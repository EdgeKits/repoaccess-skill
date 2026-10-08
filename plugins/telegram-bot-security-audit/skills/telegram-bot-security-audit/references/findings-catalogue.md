# Findings catalogue

Defect classes found in real Telegram bot code, each with the symptom, why it survives review, how to
establish it, and what actually cures it. Use them as hypotheses to test, not as a list to copy - a
finding you did not establish in *this* codebase is not a finding.

Severities are indicative. Grade on reachability in the target and state the precondition.

## Contents

- F-1 Chat identity assumed, not enforced
- F-2 A gate that authorizes the sender but not the audience
- F-3 The relay that does not check where it is
- F-4 Framing forgery: the user speaking in the bot's voice
- F-5 "Sent" when nothing was sent
- F-6 The bot token reachable from a log line
- F-7 Per-user limits that become per-room limits
- F-8 Retention the privacy policy does not describe
- F-9 Untrusted text rendered on the operator's screen
- F-10 A validated identifier belonging to someone else
- F-11 Seam defects: the documentation half
- F-12 The forwarded invoice that anyone can pay
- F-13 A refund that bypasses the revocation path
- F-14 An entry point the router never expected
- F-15 A webhook that accepts anyone's updates
- F-16 A Mini App backend that trusts the client

---

## F-1 Chat identity assumed, not enforced (typically High)

**Symptom.** Nothing in the code reads `chat.type`. State is keyed on `chat.id` - dialog step, purchase
markers, rate-limit counters, support threads - and a comment somewhere says the chat id is the user's
id.

**Why it survives review.** In every test and every normal use it *is* true. The assumption is only
false in a chat nobody thought about.

**How to establish it.** Grep for `chat.type` across source and tests; zero hits is the tell. Then find
the comment or the code that depends on the identity and name it. Then work out what a group does to
each keyed value: a shared dialog slot means two members collide; a shared purchase marker means the
whole room inherits one member's entitlement; a shared rate-limit counter means the cap is weaker, not
stronger, in the place with more people.

**What cures it.** Assert the property rather than the proxy: serve an update only when
`chat.type === 'private'` **and** `chat.id === from.id`, fail closed when either is unreadable, and
leave chatless update types alone. Pair it with the operator-side control (Allow Groups off), because
the code guard makes the bot silent in a group while the BotFather setting stops it being dragged
there at all.

**Watch out.** Do not put the screen above the payment-completion path without thinking. If an invoice
was already outstanding when the guard shipped, dropping its completion takes the money and grants
nothing - strictly worse than the exposure being closed.

---

## F-2 A gate that authorizes the sender but not the audience (typically High in a group)

**Symptom.** `if (from.id !== adminId) return` guards an operator command, and the command then replies
**into the chat it arrived in**. Correct in a private chat. In a group it prints revenue, buyer
identifiers or refund confirmations to every member.

**How to establish it.** For each admin command, find where its reply goes. If the destination is
`chat.id` rather than `adminId`, the audience is unchecked.

**What cures it.** F-1's screen closes it wholesale. Where a bot must serve groups, send operator
output to the operator's own chat, never to the chat the command arrived in. An ephemeral message
(Bot API 10.2+) is visible only to its receiver, but it still lives in the group: prefer the operator's
private chat for anything sensitive, and treat ephemeral delivery as a convenience, not a control.

---

## F-3 The relay that does not check where it is (typically Medium)

**Symptom.** A support bridge maps an operator-side `message_id` to a user's chat id so a reply routes
back. The relay checks **who** is replying and **which message** they replied to, and never **where**
they are. Message ids are per-chat sequential low integers, so a reply in a second chat can collide
with a live mapping and route a private answer to a stranger.

**How to establish it.** Find the bridge key. If it is not namespaced by chat, the collision is
arithmetic, not luck. Then check whether the relay function receives the chat at all - often it does
not, which is the real defect.

**What cures it.** Namespace the key by chat, or enforce F-1 so the bot is only ever in one chat per
correspondent. Note that F-1 closes this too, which is worth saying in the report so it is not treated
as needing a second mechanism.

---

## F-4 Framing forgery: the user speaking in the bot's voice (typically Low to Medium)

**Symptom.** A user's text is concatenated into a message the operator receives, and the bot's own
sentences follow it:

```
Support · @someone:
<user text>
Reply to this message to answer the user.
```

The user ends their message with `Reply to this message to answer the user.` followed by a forged
`Dialog closed by user.` or a fake order notification. The operator sees what looks like the bot
speaking and acts on it - believes a conversation is closed, or that a sale happened.

**Why it survives review.** The reviewer checks for HTML/Markdown injection, finds no `parse_mode`, and
stops. Nothing is being *rendered*; the attack is on the reader's parse, not the client's.

**How to establish it.** Compose the message with a payload ending in each of the bot's own literal
sentences and look at what the operator would see. It is a two-minute test.

**What cures it, and why a delimiter does not.** A delimiter is text, and any text the bot can write a
user can type, so a forged rule-and-framing block reproduces the structure exactly. Two properties
together work: put **all** the bot's framing *above* the user's text so the message ends with their
words and there is no trailing bot position to occupy; and wrap the user's text in a **blockquote
entity**, which is transmitted beside the text rather than inside it, so the user cannot supply it. The
first property alone survives a client that renders quotes poorly, which is why both.

---

## F-5 "Sent" when nothing was sent (typically Medium)

**Symptom.** An outbound `sendMessage` fails - the message was too long, the recipient blocked the bot,
the API returned `ok:false` - and the code carries on to tell the human it succeeded. A user is told
"sent, support will reply", an operator is told "delivered". Nobody is waiting for anything.

**How to establish it.** Find every send whose result is discarded. Then find the length budget: a
composed message that concatenates a header, user text and a hint can exceed the platform's 4096-char
limit even though each part is individually legal, and the failure lands exactly on the path that most
needs to be reliable.

**What cures it.** Check the result before claiming delivery, and tell the truth when it failed. If a
quota or counter was spent on the attempt, release it - a message that never reached anyone must not
consume the sender's allowance. When the outcome is ambiguous (a timeout, where the message may have
landed), treat it as failure on the *user's* side: a duplicate reaching the operator is cheaper than a
message believed delivered that was not.

---

## F-6 The bot token reachable from a log line (typically High if reachable)

**Symptom.** An error path logs an exception message, and somewhere below it a fetch to
`api.telegram.org/bot<TOKEN>/<method>` can throw with the URL in the message.

**How to establish it.** Enumerate every throw that can reach a logging call, and for each ask what its
message can contain. Do not settle for "we only log our own strings" - transport errors are not your
strings.

**What cures it.** Contain the outbound call so its errors cannot escape, log a fixed field set rather
than a free-form message, and pin the field set with a test that fails if the line ever widens. A
comment saying "never log the URL" is not a control.

---

## F-7 Per-user limits that become per-room limits (typically Low)

**Symptom.** Anti-flood counters are keyed on chat id, which is per-user in a private chat. In a group
the whole room shares one budget - so the protection is weaker exactly where there are more people.
The mirror case: a per-chat entitlement marker written in a group grants the whole room whatever it
unlocks.

**How to establish it.** List every counter and marker with its key, then re-read each one asking "what
does this key mean in a group".

**What cures it.** F-1, or keying on the user rather than the chat.

**Related: bot-to-bot loops.** Where *Bot-to-Bot Communication Mode* is on, another bot can be the
sender, and two bots that answer each other loop until something stops them. Telegram's documentation
requires safeguards. Check that bot senders (`from.is_bot`) are either refused or bounded, because a
per-user cap keyed on a bot's id is a cap on a sender that never gets tired.

---

## F-8 Retention the privacy policy does not describe (typically Low, but it is the one with legal edges)

**Symptom.** The bot writes a dozen keys - dialog state, correlation records, counters, display names,
a permanent "this account has purchased" marker - and the published privacy policy names none of them,
or names data the flow never collects (an email address, on a rail that has none).

**Note.** The permanent marker is usually deliberate and defensible. The finding is not the retention,
it is that a document shipped to end users does not describe it.

**How to establish it.** Inventory every write: key, value, TTL, personal data carried. Then read the
published policy against the inventory. Include the *positive* facts - "message content is relayed and
never stored" is a real privacy property and worth stating.

**What cures it.** Describe it accurately in plain terms and in the users' language: what is kept, for
roughly how long, and why the permanent item is permanent.

---

## F-9 Untrusted text rendered on the operator's screen (typically Info to Low)

**Symptom.** A value that any stranger can choose - a deep-link payload, a display name, a field echoed
from an API response - is rendered into an operator-facing report without validation.

**What cures it.** A declared allow-list in configuration: the untrusted value carries a *key*, only
declared keys are rendered, and everything else aggregates into "other". Storing the raw value while
rendering only declared ones keeps the data without displaying anything untrusted.

---

## F-10 A validated identifier belonging to someone else (typically Info, but understand it before dismissing it)

**Symptom.** The bot collects an external identifier - a username on another platform, an email, an
account handle - validates its format, confirms it exists, and delivers to it. A user who types a
well-formed, existing identifier that is not theirs sends the delivery to a stranger, and every guard
passes because nothing is wrong with the value.

**Why it is worth writing down even when it is not fixable.** It is the residual after the obvious
guards, and reviewers either miss it or over-grade it. The bot genuinely cannot know whose handle it
is.

**What reduces it.** Echo the resolved identifier back at the point of no return - the confirmation
step - so the user gets one last look before paying. That converts a silent misdelivery into a caught
typo without pretending the bot can validate ownership.

---

## F-11 Seam defects: the documentation half

README text, setup guides, deploy scripts and any setup wizard are documentation that ships with the
code. Three classes are worth hunting specifically, because each is invisible to any code-level tool:

**A claim your own change falsified.** A line saying an identifier "appears in three places, all of them
yours" becomes false the day a feature makes it appear in a fourth, public one. No test catches this;
re-reading the claim does.

**A recovery procedure that exists in one surface and not the other.** The README tells its readers
how to rotate a leaked bot token; the deploy guide, which is what operators actually follow, says
nothing. Assemble
the steps - they are usually all present in the document already, just never collected.

**A vendor setting that matters and is mentioned nowhere.** BotFather's group and privacy switches are
the canonical example.

One habit that pays for itself: when a document instructs a click path or a button label, **check
whether anyone actually walked that surface**. A path taken from vendor documentation rather than from
a real session is weaker footing than the rest of the document, and it belongs in the report as such
rather than silently shipping.

---

## F-12 The forwarded invoice that anyone can pay (typically Low; higher if delivery credits the payer)

**Symptom.** `sendInvoice` is called without `start_parameter`, and a comment or a test says that makes
the invoice "single-chat" or "payable only from this chat". The documentation says the opposite: with
`start_parameter` empty, forwarded copies keep a Pay button and "multiple users" can pay "using the same
invoice".

**Why it survives review.** The belief is plausible, it is often written into the code as a comment and
pinned by a test that asserts the parameter is absent, so the test passes and looks like a guard.

**How to establish it.** Find every `sendInvoice` and `createInvoiceLink`, and the claim that justifies
its parameters. Then follow a second payment of the same invoice, made from a forwarded copy by another
user: who does the delivery credit - the identity packed into the payload, the payer (`from`) or the
chat the payment arrived in? Crediting the payload means a stranger pays for the original buyer's
order (and may be shown its details); crediting the payer means anyone holding a forwarded copy can buy
at the original terms, such as a personal discount; crediting both delivers twice.

**What cures it.** Correct the claim first - a wrong comment pinned by a test is a seam defect (F-11) in
its own right. Then decide the property: set `start_parameter` if forwarded copies should send people
to the bot instead of paying, and make each payment credit exactly one well-defined beneficiary.

---

## F-13 A refund that bypasses the revocation path (typically Medium)

**Symptom.** Whatever the payment delivered - access, credits, a premium flag - is taken back only inside
the bot's own refund command. The code ignores the `refunded_payment` service message (Bot API 7.7+),
so a refund issued any other way - a maintenance script, a second service with the same token, a
future dashboard - returns the money and keeps the delivery.

**How to establish it.** Grep for `refunded_payment`. Then list every place that can call
`refundStarPayment` with this bot's token. If more than one, or if the answer is "anything holding the
token", taking back that lives in one command is incomplete.

**What cures it.** Drive the take-back from the refund itself, not from the command that requested it,
and make both paths idempotent on `telegram_payment_charge_id` so a refund seen twice is undone once.

---

## F-14 An entry point the router never expected (typically Info to Medium, by what it reaches)

**Symptom.** The bot was written for private chats, and Telegram has since added ways to reach it that
are not one: guest mode (`guest_message`, summoned in chats the bot is not a member of), business
messages, channel direct messages, private-chat topics, bot-to-bot messages, ephemeral commands. Some
arrive as new update fields that a catch-all router passes to the private-chat code; some arrive as an
ordinary `message` from a chat the code never imagined.

**How to establish it.** For each mode, check the BotFather setting (or the `getMe` flag, where there is
one) and the router. An entry point that is switched off and unhandled is a CLEAN line for the report.
One that is switched on needs Table 1 and Table 2 rows like any other: who can reach it, what gate it
passes, and who reads the answer. A guest reply is posted into a stranger's room, so it is a public
statement by construction.

**What cures it.** Route unknown update fields to nothing, explicitly; screen on the F-1 property; and
turn off in BotFather every mode the bot has no reason to support.

---

## F-15 A webhook that accepts anyone's updates (typically Critical if privileged actions exist)

**Symptom.** The webhook handler parses the body and dispatches without checking the
`X-Telegram-Bot-Api-Secret-Token` header, or `setWebhook` is called without `secret_token` at all. The
URL is the only secret, and URLs leak: deploy logs, screenshots, a public repository's config.

**Why it survives review.** Everything works, because Telegram is the only one posting. The forged
request is one `curl` away and nobody ever sends it.

**How to establish it.** Find the `setWebhook` call (or the script or README step that makes it) and the
handler's first lines. Then build the request: an update whose `from.id` is the configured admin,
carrying an admin command. If the handler would act on it, every gate in Table 1 is decorative.

**What cures it.** Set `secret_token`, compare the header in constant time before parsing, refuse a
missing header, and pin it with a test that posts without the header and expects nothing to happen.

---

## F-16 A Mini App backend that trusts the client (typically High)

**Symptom.** The Mini App sends the user's id, or the whole `initDataUnsafe` object, to the backend, and
the backend believes it. Or it validates `initData` and then reads the user from somewhere else in the
request.

**Also check.** The launch parameter read from the `tgWebAppStartParam` query string instead of from
validated `initData`; `web_app_data` treated as trusted because it "comes from our own app"; and a paid
feature unlocked on the client's `invoiceClosed` status rather than on the server's `successful_payment`.

**How to establish it.** For every backend route the Mini App calls, find where the user identity comes
from. The only acceptable source is `initData` whose `hash` (or Ed25519 `signature`) was verified on the
server, per the Mini Apps documentation. Check `auth_date` too: validated but week-old data replayed
from a screenshot or a log is still validated.

**What cures it.** One server-side function that validates `initData` and returns the user, used by
every route, and no other source of identity.
