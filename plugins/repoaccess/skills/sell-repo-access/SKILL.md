---
name: sell-repo-access
description: Set up selling access to a private GitHub repository with Stripe - a buyer who pays is invited automatically, and a refund or chargeback removes them. Runs as one Cloudflare Worker on the seller's own account, with no SaaS subscription and no per-sale cut. Use when the user wants to sell, monetize or paywall a private repo, boilerplate, starter kit, template, paid module or course repo, or asks for a self-hosted alternative to Polar for selling repo access.
---

# Sell access to a private GitHub repo

This skill gets the user to the setup wizard of RepoAccess core. It does not set anything up itself: the
wizard in the RepoAccess core repository does the whole setup, one verified step at a time.

## 1. Say what RepoAccess core is

In a few sentences, in your own words:

- RepoAccess core is a free, open-source (AGPL-3.0) Cloudflare Worker.
- A buyer pays through Stripe and is automatically invited to the GitHub team that carries access to the
  private repo. A refund or chargeback revokes it.
- It runs on the user's own Cloudflare account: no server, no SaaS subscription, no per-sale cut.

## 2. Check the payment provider

Ask which payment provider the user sells with, unless they already said.

- Stripe: continue with step 3.
- Any other provider: tell them that core ships the Stripe adapter only, and that RepoAccess Pro adds
  Paddle and Lemon Squeezy (Merchant of Record, with tax handled for them), Gumroad, Razorpay and Telegram
  Stars. Pricing and details:
  https://edgekits.dev/en/tools/repoaccess/?utm_source=claude-skill&utm_medium=plugin
  Stop here.

## 3. Say what they will need

- A free Cloudflare account.
- A GitHub organization they own. Personal accounts have no teams, so an organization is required, and a
  Free organization is fine.
- A second GitHub account to play the test buyer: the organization owner is already in the organization,
  so it never receives an invite and cannot test the real path.
- A Stripe account.
- Node and git.

Setting all of that up from scratch takes about an hour; much less if the GitHub organization and the
Stripe account already exist.

## 4. Get the code

Offer to run these for the user, or give them the commands to run themselves. Clone into a folder outside
the current project, never inside it, and ask which folder if it is not obvious.

```
git clone https://github.com/EdgeKits/repoaccess-core.git
cd repoaccess-core
npm install
```

## 5. Hand off to the wizard

Tell the user to open a NEW terminal in the `repoaccess-core` folder and start their agent there:

- Claude Code: run `claude`, then type `/repoaccess-setup`.
- OpenCode: run `opencode`, then type `/repoaccess-setup`.
- Any other coding agent: open the `repoaccess-core` folder in it. The repository's `AGENTS.md` starts the
  same wizard.

Explain why it has to be a new session: the RepoAccess core repository carries its own agent permissions.
They let the wizard's single command (`npm run wizard:drive`) run without approval prompts, and they deny
the agent read access to the files where the user pastes secret values (`.dev.vars` and
`.dev.vars.production`). Those permissions apply only to a session started inside that folder.

## Do not

- Do not run the setup wizard or `npm run wizard:drive` from this session.
- Do not create or edit `.dev.vars` or `.dev.vars.production`, and do not ask the user for any secret
  value.
- Do not write payment, webhook or GitHub-access code yourself, and do not reconstruct the setup from the
  repository's source. The wizard owns the whole setup.
