# Project Curator

A curator for projects you build with a coding agent. You work with Claude in a Cowork chat; a
coding agent (Claude Code, OpenCode or another) works in the project on your machine. The curator
sits between the two: it checks every claim in the agent's reports against the code and git,
argues the options with you, and writes the prompts you hand to the agent. It never writes the
project's code itself.

Each project gets its own memory, a `curator/` folder inside the project, and every chat opens from
it: the curator reads where things stood, checks git for what changed, and tells you in a few lines.

- [Why a curator](#why-a-curator)
- [Requirements](#requirements)
- [Install](#install)
- [Set up a project](#set-up-a-project)
- [Daily use](#daily-use)
- [Relays](#relays)
- [What is in curator/](#what-is-in-curator)
- [Projects with an older curator setup](#projects-with-an-older-curator-setup)
- [Working with project-journal](#working-with-project-journal)
- [What is built in, and what is per project](#what-is-built-in-and-what-is-per-project)
- [Troubleshooting](#troubleshooting)
- [Privacy](#privacy)
- [License](#license)

## Why a curator

A coding agent reports its own work, and its reports are usually right. When they are not, the
error is easy to miss: a count that was never recounted, a test that ran against the wrong build,
"nothing else changed" in a diff that touched three more files. A curator is a second Claude
outside that loop. It re-derives every figure from the sources before relying on it, keeps the
decisions you made and the predictions it filed, and turns each agreed step into one precise,
checkable prompt for the agent.

## Requirements

- **Claude Cowork** in the Claude desktop app, with the project's folder connected to a Cowork
  project. The curator reads the folder and runs read-only git commands in it.
- **git** in the project, for the curator to verify the agent's work. A project without git works,
  with less to check.
- **A coding agent** working in the same folder. Any agent works; the curator writes its prompts as
  plain text you paste.

## Install

In the Claude desktop app: **Customize > Plugins > Add marketplace**, enter `EdgeKits/skills`, then
add **Project Curator** from the list.

Then create a Cowork project for your codebase and connect its folder (the project's root folder) to
it. One Cowork project per codebase.

## Set up a project

Open a new chat in that Cowork project and write "start a new project" (any wording works, as does
`/project-curator:curator-init`).

1. The curator finds the connected folder and looks at what it can tell without asking: the git
   repositories and their remotes, deploy configs and CI, the agent's instruction file
   (`CLAUDE.md`, `AGENTS.md` and so on), a project journal, which secret files exist (by name only;
   it never opens them), and the skills and docs servers the project already uses.
2. It asks the rest in one round: your name and the language to talk to you in; what a push does
   in each repository; what counts as a blocking defect in this project; any sources of truth or
   off-limits files it could not find; and whether `curator/` should be tracked in git.
3. It writes `curator/profile.md`, `curator/status.md` and `curator/log.md`, and shows you the
   profile's key facts to correct.
4. It takes care of the agent's instruction file (`CLAUDE.md` for Claude Code, `AGENTS.md` for most
   other agents):
   - in a new project without one, it works out the content with you (stack, commands, working
     rules, local-only commits, the journal, `curator/`) and writes a draft for your approval;
   - in a project with code but no instruction file, it asks the agent to generate one from the
     code (`/init`), then reviews it against the sources and drafts what is missing;
   - in a project that has one, it proposes only what the curator setup needs.
5. It gives you two things to do yourself:
   - a short text to paste into the Cowork project's **Instructions**, so every new chat in the
     project opens as a curator session;
   - the prompts for your coding agent, one at a time: putting the approved instruction file in
     place, and starting a journal if the project has none.
6. It opens the first session and tells you where the project stands.

## Daily use

**Start a chat** in the project with anything: "let's begin", or the task itself. The curator first
reads its profile, its status and the end of its log, the project journal if there is one, and the
git state of every repository, then tells you in a few lines where things stand, whether a prompt
is out with the agent, and what waits on you.

**Discuss** what to do next. The curator reads the relevant code and docs before saying how
something works, and tells you which source each claim came from.

**Get a relay**: once you have decided, the curator writes the prompt for the agent (see
[Relays](#relays)). Paste it to the agent.

**Bring back the report**: paste the agent's report into the chat. The curator verifies it against
git and the files (hashes, diffs, counts), tells you what holds and what does not, and either
approves the round or writes the corrective prompt.

**Keep the agent's instructions current.** When a review shows the agent repeating a mistake, when
you make a decision the agent should follow every time, or when the stack or the commands change,
the curator proposes a change to the instruction file. After you agree, it writes the new version
as a draft in `curator/drafts/`, and a prompt asks the agent to put it in place unchanged, check the
hash and commit. The curator also keeps the file short, since the agent loads it in every session.

**End the session** whenever you like ("that's it for today"). The curator writes the session into
its log and rewrites its status, so the next chat starts from there. It also updates the status
after every review, so a chat that ends abruptly loses nothing.

## Relays

A relay is the prompt the curator writes for your coding agent:

- one block, starting with `# Relay:`, in English whatever language you chat in;
- one at a time: the next relay comes only after the previous report has been reviewed;
- ends with "commit locally": pushing, publishing and deploying stay with you;
- states what to do, what not to do, when to stop and report, and what evidence to put in the report;
- for a bug, asks for a test that fails before the fix and passes after it.

## What is in curator/

| File | What it holds | How it is used |
|---|---|---|
| `profile.md` | The project's facts and rules: your name and chat language, repositories and what a push does, the coding agent, the journal, what counts as blocking, sources of truth, off-limits files, rules specific to this project | Read in full at every session open. Changes only with your yes. Kept under 10,000 characters |
| `status.md` | Where things stand: repositories at last check, the prompt in flight, what waits on you, your standing decisions, lessons learned, open predictions, the parked list | Read in full at every open. Rewritten, never appended. Kept under 12,000 characters |
| `log.md` | Every session: what was read and verified, reviews, decisions, predictions and how they settled, the curator's own mistakes | Only its end is read at open. Searched when the past matters |
| `drafts/` | Drafts of files the agent will put in place unchanged, such as its instruction file | Deleted once the agent has committed them |

Everything in `curator/` is in English. You can read and edit any of it; tell the curator when you
change the profile.

## Projects with an older curator setup

If the project already has a curator in a root `CURATOR.md` and a single status file, the setup
converts it instead of starting fresh:

- each rule in the old `CURATOR.md` is either recognised as built into the plugin, or carried into
  the profile with its old section number;
- the old files move unchanged to `curator/legacy/`, so the history stays searchable;
- a new short status is built from the old file's latest state;
- you see the whole plan, including the list of rules it would drop as already covered, before
  anything is written.

## Working with project-journal

[`project-journal`](../project-journal/) gives the coding agent a project memory in `journal/`. The
two plugins fit together: the agent is the journal's only writer, and the curator reads it at every
session open (the index, the status, the page marked "read before any work", and the decisions the
work touches) instead of re-scanning the project. If the project has no journal, the setup offers a
prompt that asks the agent to start one.

## What is built in, and what is per project

Built into the plugin, the same for every project: the three roles; the relay rules; English for
relays and files; verifying every claim against the sources; what counts as work and the single
parked list; reading the sources before describing behaviour; never reading secret files; owning
mistakes as rules; how the agent's instruction file is written and kept current; read-only git
with `--no-optional-locks`; the session open and close.

Set per project in `curator/profile.md`: everything else, including any rule your project needs on
top. The plugin's rules update when you update the plugin; your profile stays yours.

## Troubleshooting

**A new chat does not open as a curator session.** Check that the chat is inside the right Cowork
project, that the project's Instructions contain the text the setup gave you, and that the folder is
connected. You can always start the session by hand: "open the curator session".

**"The folder is not reachable."** The computer is asleep or offline, or the folder was disconnected
from the project. The curator will not work from memory; reconnect and start again.

**The status grew too long.** Ask the curator to prune it: detail moves to the log, one line stays.

## Privacy

The plugin is instructions only: no code, no hooks, no servers, and it sends nothing anywhere. The
curator reads your project folder through Cowork and writes only inside `curator/` (and any other
files you name as its own in the profile). It never opens secret files such as `.env*` or
`.dev.vars*`.

## License

MIT
