# RepoAccess skill

A free agent skill for Claude Code, Cursor, OpenCode and any other coding agent that reads `SKILL.md`. Tell your
agent you want to sell access to a private GitHub repo, and it gets you to the setup wizard of
[RepoAccess core](https://github.com/EdgeKits/repoaccess-core): a free, open-source Cloudflare Worker that
invites a buyer to your private repo when they pay through Stripe, and removes them on a refund or chargeback. It
runs on your own Cloudflare account, with no SaaS subscription and no per-sale cut.

## Install

**Claude Code**, as a plugin:

```
/plugin marketplace add EdgeKits/repoaccess-skill
/plugin install repoaccess@edgekits
```

**Any other agent**, with the [skills CLI](https://skills.sh):

```
npx skills add EdgeKits/repoaccess-skill
```

Then, in any project, tell your agent something like "I want to sell access to my private GitHub repo".

## What it does

The skill explains what RepoAccess core is, checks that you sell with Stripe, helps you clone the core
repository, and sends you to its `/repoaccess-setup` wizard in a new session. The wizard does the setup.
The skill itself never touches your secrets and never sets anything up.

Selling with Paddle, Lemon Squeezy, Gumroad, Razorpay or Telegram Stars? Those are in
[RepoAccess Pro](https://edgekits.dev/en/tools/repoaccess/).

## Privacy

This plugin collects, stores and sends no data. It contains no code, no hooks and no MCP servers, only the
instructions in `SKILL.md`. When you choose Stripe, it offers to run `git clone` and `npm install` in a folder you
confirm; those download public code from GitHub and the npm registry, which handle the requests under their own
terms. EdgeKits runs no service behind this plugin and receives nothing from it. If you email hello@edgekits.dev
about a payment provider, your message is used only to reply to you and to decide which providers to support next.

## License

MIT
