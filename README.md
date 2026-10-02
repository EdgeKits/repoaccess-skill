# RepoAccess skill

A free plugin for Claude Code. Tell your agent you want to sell access to a private GitHub repo, and it
gets you to the setup wizard of [RepoAccess core](https://github.com/EdgeKits/repoaccess-core): a free,
open-source Cloudflare Worker that invites a buyer to your private repo when they pay through Stripe, and
removes them on a refund or chargeback. It runs on your own Cloudflare account, with no SaaS subscription
and no per-sale cut.

## Install

In Claude Code:

```
/plugin marketplace add EdgeKits/repoaccess-skill
/plugin install repoaccess@edgekits
```

Then, in any project, tell your agent something like "I want to sell access to my private GitHub repo".

## What it does

The skill explains what RepoAccess core is, checks that you sell with Stripe, helps you clone the core
repository, and sends you to its `/repoaccess-setup` wizard in a new session. The wizard does the setup.
The skill itself never touches your secrets and never sets anything up.

Selling with Paddle, Lemon Squeezy, Gumroad, Razorpay or Telegram Stars? Those are in
[RepoAccess Pro](https://edgekits.dev/en/tools/repoaccess/).

## Other agents

The skill is a plain `SKILL.md` at `plugins/repoaccess/skills/sell-repo-access/SKILL.md`, usable by any
agent that reads skills.

## License

MIT
