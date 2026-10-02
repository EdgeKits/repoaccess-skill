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

## 2. Ask which payment provider

Unless the user has already named their provider, ask which one they sell with, as a choice between exactly
these options. If you have a tool for asking the user a multiple-choice question, use it; otherwise show the
options as a numbered list.

1. Stripe
2. Paddle
3. Lemon Squeezy
4. Gumroad
5. Razorpay
6. Telegram Stars
7. Another provider

Stop and wait for the answer. Do not go on to step 3 in the same message. A provider the user names that is not
in options 1 to 6 counts as option 7.

- Stripe: continue with step 3.
- Paddle, Lemon Squeezy, Gumroad, Razorpay or Telegram Stars: tell them that core ships the Stripe adapter only,
  and that RepoAccess Pro adds all five: Paddle and Lemon Squeezy (Merchant of Record, with tax handled for
  them), Gumroad, Razorpay and Telegram Stars. Pricing and details:
  https://edgekits.dev/en/tools/repoaccess/?utm_source=claude-skill&utm_medium=plugin
  Stop here.
- Another provider: tell them that RepoAccess supports only the six providers above today. RepoAccess Pro
  includes a recipe for adding any provider yourself, written so a coding agent can follow it:
  https://edgekits.dev/en/tools/repoaccess/?utm_source=claude-skill&utm_medium=plugin
  Also ask them to write to hello@edgekits.dev with the provider they need, so we know which providers to add
  next. Stop here.

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

First choose where the clone goes. The clone creates a `repoaccess-core` folder:

- If the current folder is empty, or is not a project (no git repository and no project files), clone inside
  it.
- Otherwise clone next to the current project, in its parent folder. Never clone inside the user's project.

Tell the user the exact full path of the `repoaccess-core` folder that will be created, as a short question of
its own, and wait for them to confirm it or give another location. Then offer to run these commands for them,
or give them the commands to run themselves:

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
