---
description: Set up the project journal in this workspace, or bring an existing one up to date (safe to run again).
allowed-tools: Read, Write, Edit, Bash, Glob
---

Set up the **project journal** at the workspace root (`$CLAUDE_PROJECT_DIR`, or the folder the
session was opened in), following the `project-journal` skill and its `references/conventions.md`.

Never overwrite or rewrite an existing journal file. If `journal/` exists, report what is there and
add only what is missing. Running this again on an older journal is how it gets upgraded.

1. **Choose the commit mode** and write it to `journal/.journal.json` as
   `{ "commit": "<mode>" }`. If the file already exists, keep its value and skip the question.
   Otherwise detect the likely mode and ask the user to confirm or pick another:
   - `journal/.git` exists: propose `own-repo` (the journal has its own repository; commits go
     there, never pushed).
   - The workspace is inside a git repository (`git rev-parse --is-inside-work-tree`): propose
     `project-repo` (journal commits go into the project's repository as separate
     `journal: ...` commits, never pushed).
   - Neither: propose `none` (the journal is never committed by the agent).
2. Create what is missing: `journal/`, `journal/adr/`, `journal/pending/`, `journal/sessions/`.
3. Create these files only if absent, from the templates in `references/conventions.md`:
   `index.md`, `STATUS.md`, `log.md` (with a first `## [<today>] note | journal initialized`
   entry), `execution-plan.md`, `adr/0000-template.md`, `pending/.gitkeep`, `sessions/.gitkeep`.
4. Make sure `journal/.gitignore` contains each of these lines, adding any that are missing and
   leaving other lines alone:
   ```
   .journal-state
   pending/*
   !pending/.gitkeep
   sessions/*
   !sessions/.gitkeep
   ```
   Captures hold conversation text, so they never go into git. If git already tracks files under
   `journal/pending/` or `journal/sessions/` (check with `git ls-files`), tell the user and offer
   the one-time `git rm --cached` that stops tracking them; do not run it without a yes.
5. Root `CLAUDE.md`: if there is no "## Project journal" section, add one (create the file if
   needed) that says: persistent memory lives in `journal/`; read `journal/index.md` first; keep
   `STATUS.md` current and within budget; append to `log.md`; record decisions as ADRs; follow
   the project-journal skill. Do not touch the rest of the file.
6. If `STATUS.md` or `index.md` already exist and are over budget (4,000 and 2,500 characters),
   say so and offer to prune them as the skill describes. Propose the moves and wait for a yes
   before rewriting.
7. If the project has obvious history (PRD, specs, an existing CLAUDE.md, code) and the journal is
   new, suggest `/seed`.
8. Report the result as a short tree, with the commit mode.

`<today>` is `date +%F`.
