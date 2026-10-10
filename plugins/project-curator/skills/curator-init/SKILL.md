---
name: curator-init
description: >-
  Set up the curator for a project, or convert an existing CURATOR.md and curator status file to the
  project-curator layout. Use when the maintainer starts a new project with a curator ("start a new
  project", "set up the curator", "начинаем новый проект"), runs /curator-init, or when the
  project-curator skill finds no curator/ folder in the connected project.
---

# Set up the curator

Creates `curator/profile.md`, `curator/status.md` and `curator/log.md` in the project folder, asking
the maintainer only what the folder cannot tell you. File formats are in the project-curator skill's
`references/files.md`; read it first. Never overwrite an existing `curator/` file.

## 1. Find the project folder

List the folders connected to this session.

- None: ask the maintainer to connect the project folder to this Cowork project, and stop.
- One: that is the project. Confirm its name in your first question round.
- Several: ask which one is the project.

If `curator/profile.md` already exists, the project is set up: show the profile's key facts and ask
whether anything should change. Stop there.

If the folder has an older curator setup (a `CURATOR.md`, a `*curator-status*.md`, a curator handoff
or backlog file), follow `references/migration.md` instead of the steps below.

## 2. Learn what the folder can tell you

Look, do not ask, for these. Read file names and small config files only; never open secret files.

- **Repositories**: is the folder a git repository; are there repositories inside it (folders with
  their own `.git`); each one's remotes (`git --no-optional-locks remote -v`) and current branch.
- **Deployment hints**: CI workflows (`.github/workflows/`), deploy scripts in `package.json`,
  platform configs (`wrangler.toml`/`wrangler.jsonc`, `vercel.json`, `netlify.toml`, `fly.toml`,
  Dockerfiles). They suggest what a push does; they do not prove it.
- **Coding agent**: which instruction file exists (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`,
  `GEMINI.md`). In a new project there may be none yet; step 5 deals with that.
- **Code**: whether the project already has source code, or is empty or nearly so.
- **Journal**: `journal/` with `.journal.json` (project-journal), and which page `journal/index.md`
  marks "read before any work".
- **Secret files present**: names matching `.env*`, `.dev.vars*`, `*.pem`, `*.key`, `.npmrc` and
  similar. Names only.
- **Sources of truth already declared**: skills under `.claude/skills/`, MCP servers in `.mcp.json`,
  docs the agent's instruction file points to.

## 3. Ask the rest, in one round

Use the multiple-choice question tool if the session has one, with your best guess first;
otherwise a short numbered list. Ask only what step 2 did not settle:

1. The maintainer's name, and the language to use with them in chat.
2. The project's name as they want it written.
3. For each repository: what a push does (deploys to production, publishes a public repository,
   triggers nothing), with your guess from step 2.
4. The coding agent, if more than one instruction file exists or none does. This sets the
   instruction file's name: `CLAUDE.md` for Claude Code, `AGENTS.md` for most others.
5. What counts as blocking here: who is harmed, and how badly, for a defect to become work. Offer a
   default that fits the project ("would materially harm a real user, buyer or search engine").
6. Sources of truth beyond what you found, and anything off limits (files, topics), with the reason.
7. Whether `curator/` should be tracked in git, if the root is a repository. Recommend tracking it
   when the remote is private, so the curator's memory is backed up with the project.

## 4. Write the files

- `curator/profile.md` from the answers and findings, in the format in `references/files.md`.
- `curator/status.md` with "Now" filled from the current git state, and the other sections empty.
- `curator/log.md` with a first entry: `## [<today>] session | curator set up`, listing what was
  found and decided.

All in English. Show the maintainer the profile's key facts in their chat language and ask for
corrections before you continue.

## 5. The agent's instruction file

Follow section 10 of the project-curator skill's `references/rules.md` for how the file is written.

- **No instruction file, no code yet**: discuss its content with the maintainer: the stack, the
  build, test and lint commands, the working rules, that commits stay local, how the agent uses the
  journal, that `curator/` belongs to the curator. Write the draft to `curator/drafts/<file name>`,
  show the maintainer a summary, and revise until they approve.
- **No instruction file, but code exists**: if the agent can generate the file from the code
  (Claude Code and OpenCode: `/init`), the first relay asks it to run that and commit the result
  locally. Then review the generated file against the sources, and add what is missing through a
  draft, as above.
- **The file exists**: read it. Propose only what the curator setup needs (the section about
  `curator/`, and the journal if one is being added), as a draft or a short relay.

## 6. Hand over what only others can do

- **Project instructions.** Give the maintainer this text, in their chat language, to paste into the
  Cowork project's Instructions field, filled in:
  "Chats in this project are curator sessions for <project name>; its folder is connected as
  <folder>. At the start of every chat, before any work, follow the project-curator skill's session
  opening. If the folder is not reachable, say so and do not work from memory."
- **The agent's side**, one relay at a time, in this order, each only if needed:
  1. generating the instruction file with `/init` (step 5);
  2. putting the approved instruction-file draft in place, with a hash check against the draft;
  3. if `curator/` is tracked: adding `curator/` to the formatter's ignore file, if the project has
     one (the instruction file's own section about `curator/` comes with the draft);
  4. if the project has no journal and the agent is Claude Code: installing project-journal and
     running `/journal-init`.
  Follow the relay rules: discussion first, one `# Relay:` block, ending at "commit locally".

## 7. Open the first session

Run the project-curator skill's session opening, so the maintainer sees the project's state in the
same chat.
