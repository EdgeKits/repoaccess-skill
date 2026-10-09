# Project Journal

Persistent project memory for Claude Code. A small markdown journal loads at the start of every
session, every session is captured when it ends, and decisions are recorded as ADRs. The agent
picks up where you left off without re-reading the codebase, and you can always find out later
what was decided and why.

Everything stays in a `journal/` folder inside your project: plain markdown you can read, edit
and diff. No database, no service, no network.

- [How it works](#how-it-works)
- [Requirements](#requirements)
- [Install](#install)
- [Set up a project](#set-up-a-project)
- [Daily use](#daily-use)
- [Commands](#commands)
- [What is in journal/](#what-is-in-journal)
- [Commit modes](#commit-modes)
- [Budgets: why the journal stays small](#budgets-why-the-journal-stays-small)
- [What is kept, and where](#what-is-kept-and-where)
- [Troubleshooting](#troubleshooting)
- [Privacy](#privacy)
- [Uninstall](#uninstall)
- [License](#license)

## How it works

The journal has three layers.

| Layer | Files | When the agent sees it |
|---|---|---|
| Hot | `STATUS.md`, `index.md`, the latest entries of `log.md` | At the start of every session, loaded by a hook |
| Warm | `log.md`, `adr/`, `execution-plan.md`, topic pages | When a task needs them; the agent finds them through `index.md` |
| Archive | `sessions/` | Never automatically; the agent searches it when the pages have no answer |

Two hooks do the routine work, with no model calls of their own:

1. **Session start.** The hook puts `STATUS.md`, `index.md` and the end of `log.md` into the
   agent's context, within a fixed size budget. If earlier sessions are waiting to be compiled,
   it tells the agent to do that first.
2. **Session end, and before every compaction.** The hook saves the session's conversation to
   `journal/pending/`, filtered so it stays readable: your prompts and the agent's replies in
   full, tool calls and tool output shortened.

At the start of the next session (or when you run `/wrap`) the agent **compiles** those
captures: it adds a log entry, writes ADRs for decisions, rewrites `STATUS.md`, keeps the hot
files within budget, commits if you chose a commit mode, and moves the captures to
`journal/sessions/`, where they stay as the archive.

The compiling is the only step that spends tokens, and it happens in the open, as a normal turn
you can read and correct.

## Requirements

- **Claude Code.** The hooks are a Claude Code feature. The commands and the skill also work in
  the Claude Code tab of the desktop app and in the IDE extensions.
- **bash** with `sed`, `awk`, `grep` and `tail`: built in on macOS and Linux. **On Windows,
  install [Git for Windows](https://git-scm.com/downloads/win)**, which provides Git Bash; the
  hooks run with `bash`.
- **git** only if you want the journal committed (see [Commit modes](#commit-modes)).

Other agents that read `SKILL.md` (Cursor, OpenCode and others) can use the skill by hand: ask
them to compile, update or check the journal. Nothing loads or captures automatically there,
because the hooks are specific to Claude Code.

## Install

In a Claude Code session:

```
/plugin marketplace add EdgeKits/skills
/plugin install project-journal@edgekits
```

The second command opens the plugin's details; choose **Install for you (user scope)**.

Or from your shell:

```bash
claude plugin marketplace add EdgeKits/skills
claude plugin install project-journal@edgekits
```

Install it once for your user account. The plugin does nothing in a project until you run
`/journal-init` there, so it is harmless in every other folder.

To update later, open `/plugin`, go to **Marketplaces**, select `edgekits` and choose **Update
marketplace**, or run `claude plugin update project-journal@edgekits` in your shell. The new
version loads in the next session, or after `/reload-plugins`. To get updates without asking,
select **Enable auto-update** on the same screen.

## Set up a project

Open Claude Code at the root of your project and run:

```
/journal-init
```

It asks one question, how the journal should be committed (see [Commit modes](#commit-modes)),
with a suggestion based on your folder: a separate repository if `journal/.git` exists, the
project's repository if the folder is under git, otherwise no commits. Then it creates the
journal, adds a short "Project journal" section to your `CLAUDE.md`, and shows the result.

If the project already has history (a spec, a README, months of code), run `/seed` next. The
agent drafts `STATUS.md`, the index and ADRs for past decisions from what it can find in your
docs and code, shows you the drafts, lists the decisions it could not verify, and writes nothing
until you confirm.

## Daily use

Nothing is required. Work as usual.

- **Starting a session**, the agent already knows the current focus, what is in progress and
  what comes next. If the previous session has not been compiled yet, the agent compiles it first
  and tells you in one line what it added.
- **During a session**, say "log this" or "record this decision" when something is worth
  keeping. The agent writes the ADR or log entry right away.
- **Ending a session** needs nothing. The hook captures it. Run `/wrap` before you leave if you
  want it compiled and committed now rather than at the next start.
- **Asking about the past** works the way you would expect: "what did we decide about caching?",
  "why did we drop the REST endpoints?". The agent checks the index, the ADRs and the log, then
  the session archive, and tells you which file the answer came from.
- **Checking health**: "check the journal" runs the lint list: broken links, orphan pages, stale
  STATUS, files over budget, decisions without ADRs, contradictions.

## Commands

| Command | What it does | When |
|---|---|---|
| `/journal-init` | Creates the journal, or adds what is missing to an existing one. Asks for the commit mode once. Never overwrites a file. | Once per project; running it again only adds what is missing |
| `/seed` | Drafts STATUS, index and ADRs from the project's existing docs and code; writes only after you confirm. | Once, when adopting the journal in a project with history |
| `/wrap` | Compiles pending captures and the current session now, commits per your mode, and marks the journal current. | Whenever you want the journal up to date before leaving |

## What is in journal/

```
journal/
  .journal.json       # settings, e.g. { "commit": "project-repo" }
  .journal-state      # compile mark: when the journal was last brought up to date (not committed)
  .gitignore          # keeps pending/, sessions/ and .journal-state out of git
  index.md            # catalog of pages, one line each (read first)
  STATUS.md           # where we are now: Now / In progress / Next / Recent decisions
  log.md              # timeline, one entry per session or event, newest at the bottom
  execution-plan.md   # phases and checkboxes
  adr/                # one file per decision: 0001-title.md, 0002-...
  <topic>.md          # optional pages for larger subjects, linked from index.md
  pending/            # captured sessions waiting to be compiled
  sessions/           # compiled sessions: the archive
```

You can edit any of these by hand. Two rules keep the journal working: `STATUS.md` is rewritten,
never appended, and an ADR is never edited after the fact (a new ADR supersedes it).

## Commit modes

Set once by `/journal-init` and stored in `journal/.journal.json`. Change it by editing that file.

| Mode | What the agent does after compiling | Use it when |
|---|---|---|
| `project-repo` | Commits the journal files it wrote to your project's repository as a separate `journal: ...` commit. Anything else you have staged is left alone. Never pushes. | The journal should travel with the project, in a repository you control |
| `own-repo` | Commits to a separate repository inside `journal/` (`journal/.git`). Never adds a remote, never pushes. | The workspace itself is not a repository, or you want journal history apart from the code |
| `none` | Does not commit. The changes wait for your own commit. | You prefer to commit everything yourself, or the project is not under git |

In every mode the agent stages only the files it wrote, by name, and never uses `git add -A`.
Captures in `pending/` and `sessions/` are never committed.

If your project repository is public, the journal will be public too in `project-repo` mode.
Choose `own-repo` or `none` there, or add `journal/` to your `.gitignore`.

## Budgets: why the journal stays small

Claude Code passes at most 10,000 characters of a hook's output into the session; anything
longer is set aside and the agent does not read it. So the session-start hook loads at most:

| File | Budget | If it is larger |
|---|---|---|
| `STATUS.md` | 4,000 characters | The start of the file loads, with a note that it is over budget |
| `index.md` | 2,500 characters | Same |
| end of `log.md` | 1,200 characters | Only the latest entries load, by design |

When a file is over budget, the agent prunes it before other work: history moves from STATUS to
`log.md`, decisions to ADRs, standing rules to `CLAUDE.md`, larger subjects to topic pages, and
the full ADR list stays in the `adr/` folder with only the latest ten in the index. `/wrap`
checks the budgets every time it compiles.

The result is a fast, cheap start (around 2,000 tokens) however long the project has been
running.

## What is kept, and where

| What | Where | How long |
|---|---|---|
| Current state | `STATUS.md` | Rewritten as it changes |
| Every session, summarized | `log.md` | Permanently |
| Every decision and its reasons | `adr/` | Permanently |
| Every session's conversation, filtered | `sessions/` | Until you delete it |
| The complete raw transcript | Claude Code's own session files | Until Claude Code cleans them up (the `cleanupPeriodDays` setting) |

The session captures keep your prompts and the agent's replies in full. Tool calls and tool
output are shortened, and thinking, images and internal entries are dropped, which makes a
capture a few percent of the raw transcript's size. File contents and command output can always
be recovered from the project itself; the conversation is what is kept.

If a capture is interrupted (a crash, a killed terminal), the next capture of the same session
or the capture before the next compaction picks it up: the hook always stages everything since
the last compile, and each session has one file that is rewritten rather than appended.

## Troubleshooting

**The journal does not load at session start.** Check that `journal/` is in the folder where you
start Claude Code, that the plugin is enabled (`/plugin`, **Installed** tab, and the **Errors** tab
for load problems), and on Windows that Git for Windows is installed. Starting Claude Code with
`claude --debug` shows each hook run and its output.

**The session starts with "over its budget".** The file is larger than its budget, so part of it
was not loaded. Say "prune the journal" or let the agent do it as it offers.

**Pending captures keep coming back after `/wrap`.** The compile mark was not written, usually
because link checking failed during the wrap. Run `/wrap` again and read its last line.

**A capture shows "the whole session (no compile mark)".** Normal for the first session, or after
`journal/.journal-state` was deleted. Nothing is lost; the next compile writes the mark.

**I want to start the archive over.** Delete files in `journal/sessions/` whenever you like.
Nothing reads them automatically.

## Privacy

The plugin runs locally and sends nothing anywhere: no network calls, no telemetry. The hooks
read Claude Code's session transcript on your machine and write files inside your project's
`journal/` folder.

Captures in `pending/` and `sessions/` contain conversation text, including shortened tool
output, which may include anything a tool printed during the session. They are excluded from git
by `journal/.gitignore`; keep those lines in place.

## Uninstall

```
claude plugin uninstall project-journal@edgekits
```

Or in a session: `/plugin`, **Installed** tab, select Project Journal, **Uninstall**.

Your `journal/` folders stay where they are, as plain markdown. Remove the "Project journal"
section from `CLAUDE.md` if you no longer want the agent to look there.

## License

MIT
