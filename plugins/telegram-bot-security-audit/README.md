# Telegram Bot Security Audit

A free agent skill that security-audits the source code of a Telegram bot. It works in Claude Code,
Claude Cowork, Cursor, OpenCode and any other coding agent that reads `SKILL.md`, on bots written in any
language and hosted anywhere.

Generic security tools read a Telegram bot as "a webhook handler with no SQL", find nothing, and say so.
The holes that matter on this platform are about identity, audience and trust: who really sent an
update, which chat a reply lands in, who can pay an invoice, what a log line contains. This skill gives
your agent that threat model and a method that makes its findings hold up.

## Install

**Claude Code**, as a plugin:

```
/plugin marketplace add EdgeKits/skills
/plugin install telegram-bot-security-audit@edgekits
```

**Any other agent**, with the [skills CLI](https://skills.sh):

```
npx skills add EdgeKits/skills --skill telegram-bot-security-audit
```

Then open your bot's project and ask something like "audit my Telegram bot for security issues", or a
narrower question such as "is my admin check safe?" or "what happens if someone adds my bot to a group?".

## What it checks

1. **Is it really Telegram?** Webhook secret token, Mini App `initData` validation, Login Widget hash.
2. **Authorization.** Every privileged command and button, and who sees its answer.
3. **Chat identity.** Groups, guest mode, business messages, channel direct messages, topics,
   bot-to-bot messages and ephemeral commands.
4. **Cross-user isolation.** Support relays and anything else that bridges two chats.
5. **What the human is told.** "Sent" when nothing was sent, and users forging the bot's voice.
6. **Secrets and logs.** The bot token sits in every Bot API URL.
7. **The money path.** Stars invoices, forwarded invoices, refunds, subscriptions, idempotency.
8. **Rate limiting and cost.**
9. **Data retention** against the bot's published privacy policy.
10. **The operator-facing seam.** README, setup guides and BotFather instructions that are no longer
    true.
11. **Considered and rejected.** Generic checklist items that do not apply, and why.

The platform facts behind these checks, with the Bot API version they were last checked against, are
in [`telegram-platform.md`](skills/telegram-bot-security-audit/references/telegram-platform.md). The
catalogue of real defect classes, with how to establish and cure each one, is in
[`findings-catalogue.md`](skills/telegram-bot-security-audit/references/findings-catalogue.md).

## What you get

A report with every finding marked CONFIRMED or UNVERIFIED and graded by who can reach it, plus two
tables that make the next audit cheap: every entry point with its gate, and every untrusted input with
the sinks it reaches. The skill reports and does not patch: fixing is your call.

## Scope

The skill covers the bot and every point where Mini App data reaches your server or your bot. It does
not audit the Mini App as a web application (XSS, CSP, CORS, sessions); use a web security review for
that part.

This is an independent project. It is not affiliated with, endorsed by or sponsored by Telegram.

## Privacy

This plugin collects, stores and sends no data. It contains no code, no hooks and no MCP servers, only
the instructions in `SKILL.md` and two reference files. Your agent reads the source code you point it at
inside your own session and writes the report there. EdgeKits runs no service behind this plugin and
receives nothing from it.

## License

MIT, see [LICENSE](../../LICENSE).
