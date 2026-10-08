# EdgeKits skills

Free agent skills from [EdgeKits](https://edgekits.dev), packaged as Claude plugins. They work in Claude
Code and Claude Cowork, and in Cursor, OpenCode and any other coding agent that reads `SKILL.md`.

| Plugin | What it does |
| --- | --- |
| [`repoaccess`](plugins/repoaccess/) | Sell access to a private GitHub repo with Stripe: gets you to the setup wizard of RepoAccess core, a free, self-hosted Cloudflare Worker. |
| [`telegram-bot-security-audit`](plugins/telegram-bot-security-audit/) | Security audit for Telegram bot code: webhook and Mini App authenticity, chat identity, Stars payments, token leaks. The platform-specific holes generic scanners miss. |

Each plugin installs on its own. Adding this repository as a marketplace installs nothing by itself.

## Install

**Claude Code.** Add the marketplace once, then install the plugins you want:

```
/plugin marketplace add EdgeKits/skills
/plugin install telegram-bot-security-audit@edgekits
/plugin install repoaccess@edgekits
```

Or run `/plugin`, open **Discover**, and pick from the list.

**Claude Cowork.** Customize > Plugins > Add marketplace, enter `EdgeKits/skills`, then add the plugins you
want from Discover.

**Any other agent**, with the [skills CLI](https://skills.sh):

```
npx skills add EdgeKits/skills --list
npx skills add EdgeKits/skills --skill telegram-bot-security-audit
```

## Privacy

None of these plugins collects, stores or sends data, and none contains code, hooks or MCP servers: they
are instructions for your agent. Each plugin's README has its own privacy section with the details:
[RepoAccess](plugins/repoaccess/#privacy), [Telegram Bot Security Audit](plugins/telegram-bot-security-audit/#privacy).

## License

MIT, see [LICENSE](LICENSE).
