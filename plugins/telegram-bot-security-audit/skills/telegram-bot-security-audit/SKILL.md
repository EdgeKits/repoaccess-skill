---
name: telegram-bot-security-audit
description: Security-audit a Telegram bot's source code, in any language and on any hosting - webhook authenticity and the Mini App-to-server boundary, admin gating, chat identity, guest mode and other non-private entry points, payments and Stars (invoices, refunds, subscriptions), the support relay, message-entity forgery, secrets in logs, and data retention. Use this skill whenever the user asks to review, audit, harden or "check the security of" a Telegram bot, a Bot API webhook handler, or any code that handles Telegram updates, callback queries, invoices, Stars payments or refunds - and also when they ask a narrower question that touches that surface, such as "is my admin check safe", "is my webhook safe", "can a buyer fake this message", "what happens if someone adds my bot to a group", or "am I leaking my bot token". Generic OWASP or dependency scanners miss almost everything here, so reach for this skill even when a general security review has already been run.
---

# Telegram bot security audit

Generic security tooling reads a Telegram bot as "a webhook handler with no SQL", finds nothing, and
says so. That verdict is usually wrong, because the interesting failures on this platform are not
injection - they are **identity, audience and trust-boundary** failures peculiar to the Bot API.

This skill gives you the threat model that finds them and the method that makes the findings hold up.
It applies to any Telegram bot whatever it is written in, whichever framework wraps the Bot API, and
wherever it runs - a serverless function, a container, a VPS - and to webhook and long-polling bots
alike. Where a dimension does not apply (a bot that takes no payments, a bot with no Mini App), say so
in one line and move on.

For a bot with a Mini App, this audit covers the bot and every point where data from the Mini App
reaches the server or the bot: `initData` validation, the launch parameter, data sent back with
`sendData`, invoices opened from the app. It does not cover the Mini App as a web application - XSS,
CSP, CORS, sessions, browser storage. Say so in the report and recommend a web security review for
that part.

## Before anything else: three rules that decide whether the audit is worth reading

**Re-derive; never carry a conclusion forward.** If an earlier report says "the payment handler logs
nothing" or "refunds are admin-only", that was true of code that may no longer exist. Prove it again at a
current `file:line` or report that it no longer holds. Prior reports are a source of *questions*, never
of *answers*.

**Mark every finding CONFIRMED or UNVERIFIED.** CONFIRMED means you traced it end to end or executed
it. UNVERIFIED means you reasoned it but could not establish it - which is not a failure, it is a
finding in its own right: say what would settle it and how much that would cost. Blurring the two is
how a plausible-but-wrong finding survives to waste someone's week.

**Record what you checked and found CLEAN as explicitly as what you found broken.** The clean list is
what stops the next reviewer re-reading the same code, and it is the only thing that makes a later
"nothing was found" believable.

One more, because it is the most common way an audit of this kind goes wrong: **report, do not patch.**
When you see a defect, describe the failing scenario and let the owner rule on the cure. Where you do
propose something, prefer asking for a *guard* (a test that fails if the property is broken again) over
a *fix* (a change that makes today's symptom go away).

## The two artifacts this audit always produces

Prose findings age badly. These two tables are what make the next audit cheap, so build them even when
nothing is wrong.

**Table 1 - the gate enumeration.** Every entry point, its gate, and the test that proves the gate
bites:

| entry point | kind | gate | gate at | before any side effect? | test that proves it |
| --- | --- | --- | --- | --- | --- |
| `/stats` | command | `from.id === adminId` | `bot.py:213` | yes | "non-admin `/stats` is refused" |
| `ban:` | callback | `from.id === adminId` | `handlers.ts:45` | yes, target not resolved | "non-admin tap bans nobody" |
| `faq:` | callback | none, by design | - | n/a | - |

Enumerate *everything*: every `callback_data` prefix, every command, every reply-keyboard label, every
plain-message path. Ungated entries belong in the table as recorded decisions with their reason - an
omission and a decision look identical six months later unless you write the reason down.

Then answer the question the table exists for: **could a new entry point be added ungated without
anything noticing?** If the negative tests are a hand-maintained list of literals, the answer is yes.

**Table 2 - untrusted input to sink.** Every attacker-influenceable field of an Update against every
sink it reaches, and the control between them:

| field | reaches | control | verdict |
| --- | --- | --- | --- |
| `message.text` | outbound HTTP request URL | format regex + URL encoding + fixed host | SAFE |
| `callback_query.data` | storage key | fixed prefix, admin-gated first | SAFE |
| `from.first_name` | admin's DM, inside computed entity offsets | none | see F-4 |

The classic injection categories are usually absent by construction here - no SQL, no shell, no `eval`,
no HTML rendered from bot input. That is not a reason to skip the table; it is the reason the *real*
sinks (storage keys, message text sent to a human, outbound URLs, file paths, job or queue ids,
payment payloads) have never been enumerated in one place. Where the bot does build SQL, shell
commands or HTML from update fields, those are sinks too, and the usual rules apply.

## The audit dimensions

Work these in order. Each is stated as a claim to prove or break, not a box to tick. The platform facts
behind them are in `references/telegram-platform.md`; the defect catalogue with concrete symptoms is in
`references/findings-catalogue.md`. Read the platform reference before dimension 3 - the group and
privacy-mode behaviour is counter-intuitive and getting it wrong invalidates several conclusions. The
reference names the Bot API version it was checked against; if the changelog shows a newer one, read
the new entries before you trust a platform fact.

**1. Is it really Telegram?** Everything else assumes the update came from Telegram. For a webhook, find
where the `X-Telegram-Bot-Api-Secret-Token` header is compared with the `secret_token` passed to
`setWebhook`: it must happen before the body is parsed, on every request, with a constant-time compare.
Without it, anyone who learns the URL can post a forged update - including one "from" the admin. A token
or secret embedded in the webhook path is a credential that also lands in access logs. If the bot has
a Mini App or uses the Login Widget, every user identity it trusts must come from server-side
validation of `initData` (or the widget's `hash`), never from `initDataUnsafe` or from fields the
client sends separately, and stale `auth_date` values should be refused. Two more Mini App inputs are
attacker-written: the launch parameter (`start_param`, from a `startapp` or `startattach` link) and the
`web_app_data` service message produced by `sendData`. Long-polling bots skip the webhook half of this;
say so. See F-15 and F-16.

**2. Authorization.** Every privileged action resolves nothing and calls nothing before comparing the
sender to the configured admin. Build Table 1. Watch for a gate that authorizes the *sender* while
saying nothing about the *audience* - `/stats` typed in a group passes an `adminId` check and prints
revenue to the room.

**3. Chat identity - the one most audits miss entirely.** A bot written for one-to-one chats usually
assumes "the chat id is the user id". That is true only in a private chat. Establish whether the code
enforces it or merely assumes it, and read `references/telegram-platform.md` on what privacy mode does
and does not prevent. This dimension subsumes "what if someone adds the bot to a group", and the answer
is rarely "nothing". It also covers the ways in that need no group at all: guest mode, business
messages, channel direct messages, private-chat topics, bot-to-bot messages and ephemeral commands. For
each, record whether it is switched on in BotFather and what the router does with it (F-14).

**4. Cross-user isolation.** Any feature that bridges two chats - a support relay, an admin console, a
broadcast - is a place where one user's value can steer a message to another user. Ask: can anything
written by user A cause a message to reach user B, or reveal A to B? Check whether bridge keys are
namespaced by chat, and whether the relay checks *where* it is as well as *who* is speaking.

**5. What the human is told.** Two failures live here, and both are underrated. First, the bot must
never tell anyone an outbound call succeeded when it did not - check every `sendMessage` whose result
is discarded. Second, **framing forgery**: if user text is concatenated into a message that also
contains the bot's own sentences, and those sentences come *after* the user's text, the user can end
their message with something that reads as the bot speaking. See F-4.

**6. Secrets and logs.** The bot token rides in the URL path of every Bot API call, so any log line
that can contain a URL or an unfiltered error message can leak it. Enumerate every throw that can reach
a logging call and say what its message can contain. Prefer a closed-key-set assertion over a comment.
A bot that manages other bots (`getManagedBotToken`) holds their tokens too - audit those the same way.

**7. The money path** (skip, with one line, if the bot takes no payments). Idempotency on the payment
charge id; invoices that cannot be paid from another chat; a pre-checkout answer that only confirms a
fulfillable order; a refund that is the seller's capability alone. Trace a mis-typed but *valid* buyer
identifier all the way to delivery - the guard that catches nonsense rarely catches a real value
belonging to someone else. Three platform facts are routinely got wrong here: an invoice sent without
`start_parameter` stays payable from forwarded copies (F-12); a refund also arrives as a
`refunded_payment` service message, so taking back what was delivered only inside the refund command
misses refunds issued any other way (F-13); and Star subscriptions report `canceled` / `active` /
`failed` through their own update.

**8. Rate limiting and cost.** Per-user caps become per-*room* caps in a group. Ungated paths that cost
an outbound API call are reachable in a loop by any stranger - or by another bot, where bot-to-bot
messages are enabled.

**9. Data retention.** Inventory every record the bot stores - database rows, cache keys, files, log
fields: value, lifetime, and the personal data it carries. Permanent markers are legitimate and common -
the finding is usually not the retention itself but that the *published privacy policy does not describe
it*.

**10. The operator-facing seam.** README text, setup guides, deploy scripts, BotFather instructions and
any setup wizard are documentation that ships with the code, and they are held to the documentation
standard: is each claim still true? The three classes worth hunting are a claim your own change silently
falsified, a recovery procedure that exists in one surface and not the other, and a vendor setting that
matters and is mentioned nowhere.

**11. Considered and rejected.** Close the report with the generic checklist items that do not apply and
why - IP allow-listing (the webhook secret token in dimension 1 replaces it), TLS configuration,
container isolation, at-rest encryption, dependency audit if already run. A future reader should not
have to re-derive that these were considered.

## Report format

```
# Telegram bot security audit - <target>

- Date / commit / scope / method (read-only?)
- Summary table: Critical / High / Medium / Low / Info counts

## Findings, most severe first
### <ID> (<severity>, CONFIRMED|UNVERIFIED) - one-line claim
**Where:** file:line
**What happens:** the failing scenario in concrete terms - inputs, then outcome
**Why it is that severity:** name the precondition explicitly
**What would fix or guard it:** a property, not a patch

## Table 1 - gate enumeration
## Table 2 - untrusted input to sink
## Checked and found clean
## Could not settle, and what would settle it
## Considered and rejected
```

**Grade on reachability and say the precondition out loud.** "High if a stranger can trigger it on
stock configuration; Medium if it needs the operator to misconfigure something first" is a real
distinction, and writing the precondition into the grade is what lets the owner disagree with your
grade without disagreeing with your facts.

## A word on counting

Audits of this kind produce counts - hits, keys, entry points. Two habits keep them honest, and both
were learned the hard way:

Derive a baseline by **measuring** it, never by subtracting your own additions from a total. And when a
partition is supposed to account for every hit, check that the buckets are **disjoint** - a partition
that sums correctly only because two buckets share a file is a double-count that happens to look right.
