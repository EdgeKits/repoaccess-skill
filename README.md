# EdgeKits skills

Free agent skills from [EdgeKits](https://edgekits.dev), packaged as Claude plugins.

| Plugin | What it does | Works in |
| --- | --- | --- |
| [`repoaccess`](plugins/repoaccess/) | Sell access to a private GitHub repo with Stripe: gets you to the setup wizard of RepoAccess core, a free, self-hosted Cloudflare Worker. | Claude Code, Cowork, any agent that reads `SKILL.md` |
| [`telegram-bot-security-audit`](plugins/telegram-bot-security-audit/) | Security audit for Telegram bot code: webhook and Mini App authenticity, chat identity, Stars payments, token leaks. The platform-specific holes generic scanners miss. | Claude Code, Cowork, any agent that reads `SKILL.md` |
| [`project-journal`](plugins/project-journal/) | Persistent project memory: a small markdown journal loads at every session start, every session is captured when it ends, and decisions become ADRs. | Claude Code (its hooks are a Claude Code feature) |

Each plugin installs on its own. Adding this repository as a marketplace installs nothing by itself.

## Install

**Claude Code.** Add the marketplace once, then install the plugins you want:

```
/plugin marketplace add EdgeKits/skills
/plugin install telegram-bot-security-audit@edgekits
/plugin install repoaccess@edgekits
/plugin install project-journal@edgekits
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

None of these plugins sends data anywhere. `repoaccess` and `telegram-bot-security-audit` contain no code,
hooks or MCP servers: they are instructions for your agent. `project-journal` runs two local hooks that
read Claude Code's session transcript and write a journal inside your project; nothing leaves your
machine. Each plugin's README has the details:
[RepoAccess](plugins/repoaccess/#privacy), [Telegram Bot Security Audit](plugins/telegram-bot-security-audit/#privacy),
[Project Journal](plugins/project-journal/#privacy).

## License

MIT, see [LICENSE](LICENSE).
