# Telegram platform facts that change security conclusions

These are the facts a general reviewer does not have, and each one has flipped a real conclusion.
Verify anything time-sensitive against core.telegram.org/bots/api before you rely on it in a report -
the Bot API moves, and a stale platform fact produces a confident wrong finding. This file was last
checked against Bot API 10.3 (August 2026); if the API changelog shows a newer version, read its
entries for chat types, update types and payments before you start.

## Contents

- Proving an update came from Telegram
- Chat identity and why `chat.type` is only a proxy
- Entry points that are not a private chat with the bot
- Privacy mode: what it does NOT prevent
- Where the sender lives on each update type
- `allowed_updates` is sticky bot state
- Message entities, and why "no parse_mode" is not the end of the question
- The bot token's position in the URL
- BotFather settings that have security consequences
- Deep links as an untrusted input
- Stars: invoices, refunds, subscriptions and idempotency

## Proving an update came from Telegram

- **Webhooks.** `setWebhook` accepts a `secret_token` (1-256 characters, `A-Za-z0-9_-`), which Telegram
  then sends in the `X-Telegram-Bot-Api-Secret-Token` header of every webhook request. It is the only
  thing that distinguishes Telegram's POST from anyone else's. Check that the handler compares it before
  parsing the body, on every request, in constant time, and that a missing header is refused rather
  than skipped. Putting the bot token or another secret in the webhook *path* instead is weaker: paths
  are written to access logs and proxies.
- **Long polling** (`getUpdates`) has no inbound endpoint, so this half does not apply - but a bot
  cannot use both at once, and a leftover webhook silently steals updates from a poller.
- **Mini Apps.** `Telegram.WebApp.initDataUnsafe` is, in Telegram's words, data that "should not be
  trusted". The server must validate `initData`: the `hash` is an HMAC-SHA-256 of the sorted
  data-check-string, keyed with HMAC-SHA-256 of the bot token under the constant `WebAppData`; a
  third party without the token can instead verify the Ed25519 `signature`. The `auth_date` field lets
  the server refuse stale data. A backend that takes a user id from the request body, a header or
  `initDataUnsafe` lets any visitor act as any user.
- **Mini App launch parameter.** A `startapp` (or `startattach`) link passes its value to the Mini App
  as `start_param` inside `initData`, and also as the `tgWebAppStartParam` GET parameter of the page.
  Anyone can craft the link, so treat the value like a deep-link payload (below). Read it from validated
  `initData` on the server; the GET parameter is not covered by the `hash`.
- **`web_app_data`.** `Telegram.WebApp.sendData()` closes the Mini App and delivers its string (up to
  4096 bytes) to the bot as a `web_app_data` service message. Telegram's own description of the field
  is "Be aware that a bad client can send arbitrary data in this field" - it is user input, however
  official it looks, and `button_text` carries the same warning.
- **Invoices opened from a Mini App.** `Telegram.WebApp.openInvoice(url)` opens a link made with
  `createInvoiceLink`; payment then completes through the bot's usual `pre_checkout_query` and
  `successful_payment` path, so the money-path checks apply unchanged. Do not let the Mini App's
  `invoiceClosed` status ("paid") stand in for `successful_payment` on the server.
- **Login Widget.** The same rule: the user object is trusted only after its `hash` is verified on the
  server, as the Login Widget documentation describes.

## Chat identity and why `chat.type` is only a proxy

Most bots are written for one-to-one chats and assume, usually in a comment rather than in code, that
**the chat id identifies the user**. In a private chat that holds: `chat.id` equals the sender's user
id. Everywhere else it does not.

- Group and supergroup ids are **negative**; a private chat id is the sender's positive user id. So a
  key written under a group id can never be read back by a private-chat lookup, and vice versa. That
  fact resolves a lot of "is this exploitable" questions in both directions.
- Screening on `chat.type === 'private'` is the obvious guard, and it is a **proxy** for the property
  the code actually depends on. The property is `chat.id === from.id`. Telegram has shipped features
  where a chat reports `private` while the chat id is not the sender's. Business connections are one:
  a `business_message` belongs to the conversation between a business account and its customer, so
  the sender can be either side.
- Therefore the durable guard asserts the property: where both are readable, require
  `chat.type === 'private'` **and** `chat.id === from.id`. Fail closed when either is unreadable, and
  leave update types that carry no chat at all untouched, or you will break the ones that legitimately
  have none.

## Entry points that are not a private chat with the bot

Since 2024 Telegram has added several ways for a bot to hear from, and speak into, chats that are not
a private chat with it. Each is opt-in, but each changes who can reach the code and who reads the
reply. For every one the target supports, ask three questions: does the router handle it at all, does
it pass or bypass the private-chat screen, and who sees the bot's answer.

- **Guest mode** (Bot API 10.0; BotFather: *Guest Mode*; `getMe` returns `supports_guest_queries`).
  A user can mention the bot, or reply to one of its messages, in a chat the bot is **not a member
  of**. The bot receives a separate `guest_message` update with a `guest_query_id`, and may answer
  **once** with `answerGuestQuery`, which posts into that chat. Guest mode grants no access to the
  chat's history or member list, but the answer is read by everyone in the room. A guest handler is a
  public responder by construction: it must never print anything the operator would not post in a
  stranger's group.
- **Business connections** (BotFather: *Secretary Mode*). `business_message`,
  `edited_business_message` and `deleted_business_messages` arrive as their own update fields; what the
  bot may do is in the `rights` of the latest `BusinessConnection` (`can_reply` and others).
- **Channel direct messages** (Bot API 9.2). A channel's direct-messages chat is a supergroup with
  `is_direct_messages`, and each message carries a `direct_messages_topic`. A bot administering it with
  `can_manage_direct_messages` reads strangers' messages to the channel.
- **Topics in private chats** (Bot API 9.3-9.4; enabled in BotFather; `getMe` returns
  `has_topics_enabled` and `allows_users_to_create_topics`). `message_thread_id` now appears in private
  chats. `chat.id === from.id` still holds, so this is not a cross-user problem, but dialog state keyed
  on the chat alone is now shared by every topic the user has open.
- **Bot-to-bot messages** (Bot API 10.0; BotFather: *Bot-to-Bot Communication Mode*). Another bot can
  be the sender (`from.is_bot`), in a group or, when both bots enable the mode, in a private chat.
  Telegram's own documentation warns that bot pairs can loop forever and requires safeguards.
- **Ephemeral messages** (Bot API 10.2-10.3). In a group, a bot can send a message visible only to one
  user and the bot, and a user can send an *ephemeral command* that other members never see. Two
  consequences: an ephemeral reply is a legitimate way to answer one person inside a group, and "the
  other members would notice someone running a command" is no longer a mitigation.

## Privacy mode: what it does NOT prevent

Privacy mode is enabled by default and is widely misunderstood as "the bot sees nothing in groups". The
documented delivery set in privacy mode still includes:

- commands explicitly meant for the bot (`/command@YourBot`), **always delivered**;
- general commands (`/start`) if the bot was the last bot to send a message to the group;
- inline messages sent via the bot;
- **replies to any messages implicitly or explicitly meant for the bot**.

And regardless of privacy mode, every bot receives all service messages, all messages from private
chats and all messages from channels where it is a member.

Two consequences that matter:

1. A bot that has been added to a group is reachable under default settings. A stranger can run
   `/anything@YourBot` there, and once the bot has answered, a *reply* to that answer is delivered too -
   which is enough to drive a multi-step dialog.
2. **Callback queries are not governed by privacy mode at all.** An inline keyboard on a message the bot
   posted in a group is live for every member regardless of the privacy setting. If any inline button
   opens a stateful flow, that flow is reachable in a group by one tap.

So "privacy mode is on" is not a mitigation. The mitigation is not being in the group, or screening the
chat. And guest mode, above, reaches the bot in groups it was never added to.

## Where the sender lives on each update type

This inverts guards if you get it wrong, so it is worth stating plainly:

- `message.from` - the sender.
- **`callback_query.from` - the sender. NOT `callback_query.message.from`**, which is the *bot*,
  because the bot sent the message the keyboard is attached to. A guard that reads the wrong one
  compares the bot's id against the chat id: it refuses every legitimate tap and admits exactly the
  case it was written to close. A test on the operator's own button taps is what catches an inversion.
- `callback_query.message` is a `MaybeInaccessibleMessage`. When the message was deleted or is too old
  to return, it arrives as an `InaccessibleMessage` with `date` 0: it still has `chat` and
  `message_id`, but no `from` and no text. Dropping those breaks admin buttons on older records; reading
  their text crashes.
- A button on a message sent **via the bot in inline mode** produces a `callback_query` with
  `inline_message_id` and **no** `message`, so it carries no chat at all.
- `guest_message.from` - the user who summoned the bot; the chat is the room it was summoned in, which
  the bot is not a member of.
- `pre_checkout_query` carries no chat at all - it is answered by id.

## `allowed_updates` is sticky bot state

The update-type list set via `setWebhook` **outlives the webhook**. A `setWebhook` call that omits the
parameter *inherits* whatever list was set before, including a narrower one set months ago by someone
else. A missing type fails silently: the bot simply never sees that kind of update.

Note the shape of this as a control: it is a **configuration protecting an invariant**. If the code's
safety depends on a type never arriving, one hand-run `setWebhook` with a wider list removes that
protection with no code change and no signal. Prefer guards that do not depend on the list.

The opposite direction matters too: an **empty** list means "all update types except `chat_member`,
`message_reaction` and `message_reaction_count`", and that includes every type Telegram adds later. A
router with a catch-all branch can end up processing update types its authors never saw.

## Message entities, and why "no parse_mode" is not the end of the question

Not setting `parse_mode` genuinely removes HTML and Markdown injection - Telegram renders the text
literally. Reviewers then stop, and two live risks remain:

- **`entities` are sent alongside the text**, with `offset` and `length`. Telegram counts both in
  **UTF-16 code units**, and a JavaScript string's `.length` is also UTF-16 code units - so no
  conversion is needed in JS, and an astral character (emoji, flag, ZWJ sequence) counts the same on
  both sides. In other languages this is exactly where off-by-N bugs live. Pin it with a test carrying
  an emoji, a regional-indicator flag and a ZWJ sequence, because it is invisible until it is wrong.
- **Framing forgery** - see the findings catalogue, F-4. This is the one that survives "no parse_mode".

An entity is also the *cure* for framing forgery, and the reason is worth understanding: a delimiter is
text, and any text the bot can write a user can type, so a forged delimiter reproduces the structure
exactly. An entity is not in the text at all - it is transmitted beside it, by the bot. The user
supplies characters and cannot supply markup. That asymmetry is the whole defence.

Text messages are capped at 4096 characters after entities parsing, which matters for F-5.

## The bot token's position in the URL

Every Bot API call goes to `api.telegram.org/bot<TOKEN>/<method>`. The token is in the **URL path**, not
a header. So any log line, error message or exception trace that can contain a request URL can leak the
full bot token, which is total control of the bot: read its updates, message its users, refund its
payments.

When auditing logging, do not check only the lines the code writes deliberately. Enumerate every throw
that can reach a logging call and ask what its message can contain - a transport error from a fetch
implementation frequently embeds the URL it was given.

A bot with *Bot Management Mode* (Bot API 9.6) can create bots for its users and fetch their tokens
with `getManagedBotToken` (`replaceManagedBotToken` rotates one). Such a bot holds **other people's
tokens**: audit where they are stored, who can trigger the fetch, and whether they can reach a log line
the same way the bot's own token can.

## BotFather settings that have security consequences

These live under the bot's **Bot Settings** in BotFather's Mini App. The classic slash commands may
still answer, but teach whatever surface the operator will actually be looking at.

- **Allow Groups** - whether the bot can be added to a group at all. Enabled by default. For a bot that
  serves only private chats this is the root control; turning it off makes the whole group question
  moot. Readable programmatically: `getMe` returns `can_join_groups`, and it is returned **only** in
  `getMe`, so if the code already calls `getMe` the check is free.
- **Group Privacy** - privacy mode, described above. `getMe` returns `can_read_all_group_messages`.
- **Group / Channel Admin Rights** - these are default-permission *pickers* (which rights the bot
  requests when promoted), not access switches. Requesting zero rights does not stop a bot being added.
- **Guest Mode**, **Secretary Mode** (business), **Bot-to-Bot Communication Mode**, **Bot Management
  Mode** and private-chat **topics** each open one of the entry points described above. Allow Groups
  governs being *added* to a group; guest mode works in chats the bot was never added to, so treat it
  as a separate switch and check it separately. For each mode that is on, the code needs a reason, and
  for each one that is off, the report can say so.

## Deep links as an untrusted input

`t.me/<bot>?start=<payload>` delivers the payload as `/start <payload>`. The payload is capped at 64
characters over `A-Za-z0-9_-`, so almost no punctuation survives and separators must be chosen from
that set.

Anyone can craft a link with any payload and send it to themselves, so **the payload is
attacker-influenceable text**. If it ends up on an operator's screen - a source label in a stats
report, for example - prefer a **declared allow-list in configuration** over free text: the link carries
a key, unknown keys aggregate into "other" and are never rendered. Storing the raw value while
rendering only declared ones is a good compromise: nothing is lost, nothing untrusted is displayed.

Note also that a published deep link is a **public contract**. It lives in old posts and other people's
bookmarks, so the payload grammar is cheap to fix before launch and expensive afterwards.

## Stars: invoices, refunds, subscriptions and idempotency

- **`start_parameter` on `sendInvoice` decides what a forwarded invoice does, and the common belief is
  backwards.** Per the documentation: if it is **left empty**, forwarded copies of the invoice keep a
  **Pay button**, "allowing multiple users to pay directly from the forwarded message, using the same
  invoice". If it is **set**, forwarded copies get a URL button with a deep link to the bot instead.
  So omitting it does *not* make an invoice single-chat. Find out who the delivery credits - the
  identity in the payload, the payer or the chat - and work out what a second payer from a forwarded
  copy receives and pays for. See F-12.
- `successful_payment.telegram_payment_charge_id` is the stable correlation key: the idempotency key for
  whatever the payment delivers, and the argument to `refundStarPayment`. Deriving the delivery's
  identifier from it deterministically is what makes a re-delivered update harmless.
- **A refund is visible as a service message.** Since Bot API 7.7 a message can carry
  `refunded_payment` (`RefundedPayment`: currency, total amount, `invoice_payload`,
  `telegram_payment_charge_id`). If taking back what was delivered (access, credits, a subscription
  flag) lives only inside the bot's own refund command, any refund issued another way - a script, a
  second service using the same token - takes back nothing. Check whether the code handles the service
  message, and if both paths take back, that they are idempotent on the charge id.
- **Subscriptions.** Star subscriptions report state changes through the `subscription` update
  (`BotSubscriptionUpdated`: `user`, `invoice_payload`, `state` of `canceled`, `active` or `failed`).
  Something delivered on the first payment and never revisited outlives the subscription; the policy for each
  state is the owner's call, but the report should say whether one exists.
- `pre_checkout_query` must be answered `ok: true` only for an order the bot can actually fulfil; it is
  the last point at which a purchase can be refused for free.
