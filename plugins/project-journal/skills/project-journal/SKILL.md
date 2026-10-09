---
name: project-journal
description: >-
  Maintain the project's persistent memory journal so work resumes across sessions without
  re-learning the codebase. Use when compiling pending session captures, updating STATUS or
  log.md, recording a decision as an ADR, maintaining index.md, pruning the journal to its
  budgets, running a journal lint or health check, or when the SessionStart context says pending
  captures await compilation or a journal file is over budget. Also use when the user runs
  /journal-init, /seed or /wrap, or asks to "log this", "record this decision", "update the
  journal", "what did we decide about X" or "where did we leave off".
---

# Project Journal

You keep this project's memory: a small markdown journal in `journal/`, navigated through an
index, with no database and no RAG. The user directs; you do the bookkeeping.

## Three layers

| Layer | Files | Loaded |
|---|---|---|
| Hot | `STATUS.md`, `index.md`, the tail of `log.md` | At every session start, by the hook, within fixed budgets |
| Warm | `log.md`, `adr/`, `execution-plan.md`, topic pages | When a task needs them, through `index.md` or `grep` |
| Archive | `sessions/` | Never automatically; search it when the journal pages do not have the answer |

Nothing is lost because the archive keeps every compiled session, not because the hot layer
holds everything. The hot layer is the map. Keep it small.

```
journal/
  .journal.json       # settings: {"commit": "own-repo" | "project-repo" | "none"}
  .journal-state      # compile mark (machine state, gitignored, never hand-edited)
  .gitignore          # keeps pending/, sessions/ and .journal-state out of git
  index.md            # catalog of pages, one line each
  STATUS.md           # where we are now; rewritten, never appended
  log.md              # append-only timeline: ## [YYYY-MM-DD] type | title
  execution-plan.md   # phases and checkboxes
  adr/NNNN-title.md   # one immutable file per decision
  <topic>.md          # optional deep pages, linked from index.md
  pending/            # session captures waiting to be compiled (written by the hooks)
  sessions/           # compiled captures, kept as the archive
```

Templates and formats: `references/conventions.md`. Health checks: `references/lint-checklist.md`.

## Budgets

The SessionStart hook loads at most 4,000 characters of `STATUS.md`, 2,500 of `index.md` and
1,200 of the end of `log.md`, because Claude Code drops hook output past 10,000 characters.
Anything beyond a budget is not seen at session start. When the hook reports a file over budget,
prune it before other work unless the user says otherwise.

Where things belong, which is how the budgets hold:

| Content | Goes to |
|---|---|
| Current focus, work in progress, next steps | `STATUS.md` |
| What happened in a session | `log.md` |
| A decision and its reasons | `adr/NNNN-*.md`, with one line in STATUS "Recent decisions" (the last five) |
| Standing rules, conventions, how we work | the project's `CLAUDE.md`, or a `journal/conventions.md` page |
| Deep knowledge on one subject (a spec digest, findings, a gotcha list) | a topic page, linked from `index.md` |
| The full ADR list | the `adr/` folder itself; `index.md` lists only the latest ten and says "all: adr/" |
| Raw conversation | `sessions/`, automatically |

Never keep history in STATUS ("before that...", "earlier the same day..."). Once something is
done, its story belongs in `log.md`, and STATUS keeps only what is true now.

## The compile procedure

Run it when the session starts with pending captures, when the user runs `/wrap`, or when asked
to update the journal. With `/wrap`, also include what happened in the current session so far.

1. Read every file in `journal/pending/`. Each is one session, filtered: prompts and replies in
   full, tool activity shortened.
2. Keep only what matters for continuity: what was done, decisions and their reasons, problems
   and gotchas found, what is left. Drop chit-chat and dead ends.
3. Append one `log.md` entry per session: `## [YYYY-MM-DD] session | <short title>` and a few
   bullets.
4. Write an ADR for each notable decision, numbered after the highest existing one. If it
   replaces an earlier decision, mark the earlier ADR "superseded by ADR-NNNN" (the only edit an
   ADR ever gets).
5. Rewrite `STATUS.md` to the current state.
6. Update `execution-plan.md` checkboxes, and `index.md` if pages were added or renamed.
7. **Check the budgets**: `wc -c journal/STATUS.md journal/index.md`. If either is over (4,000
   and 2,500), move the excess where the table above says, then check again.
8. Move each compiled capture to the archive, stamped with the compile time so a session compiled
   twice never overwrites its earlier part:
   `mv journal/pending/<id>.md "journal/sessions/$(date -u +%Y-%m-%dT%H%M)-<id>.md"`.
9. Check that every link you wrote points at a file that exists.
10. **Commit**, as `journal/.journal.json` says (next section). Skip this step if step 9 failed.
11. **Leave the compile mark**, unless step 9 failed:
    `printf 'compiled=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)" > journal/.journal-state`
    Write it even when there was nothing to compile.
12. Finish with one line saying what you folded in.

Never invent progress or decisions. Record only what happened or was decided.

## Committing

Read `"commit"` from `journal/.journal.json`. If the file is missing, treat it as `none` and
suggest running `/journal-init` to choose.

- **`own-repo`**: `journal/` has its own git repository (`journal/.git`). Stage the exact files you
  wrote, by name, with `git -C journal add <paths>`; read back
  `git -C journal diff --cached --name-only`; then commit. Never add a remote and never push.
- **`project-repo`**: `journal/` is part of the project's repository. Commit only your own files:
  `git add -- <paths>`, then `git commit -m "journal: <message>" -- <paths>`. Naming the paths in
  the commit command keeps out anything else the user has staged; it stays staged for them. Then
  check that `git status --short -- journal` shows nothing you wrote left uncommitted. Never push.
- **`none`**: do not commit. Say in your summary that the journal changes are left for the
  user's own commit.

In every mode:

- Stage paths derived from what you wrote, never `git add -A` or `git add .`. If the staged set
  differs from what you believe you wrote, stop and report it: that difference is a bug.
- Nothing compiled means nothing to commit. No empty commits.
- Make the message an index of what was compiled, for example
  `journal: compile 2 sessions (2026-10-08 auth refactor, 2026-10-09 billing webhook)`.

## The compile mark

The hooks capture deterministically, so on their own they cannot tell whether a wrap already
compiled a session. `journal/.journal-state` tells them: it holds `compiled=<ISO-8601 UTC>`, and
the capture hook stages only what the transcript recorded after that instant, and nothing at all
if no typed prompt came after it.

- Write it last, after the commit, and not at all if link checking failed: a half-compiled
  journal must not claim to be current.
- It is machine state: gitignored, never edited by hand, safe to delete (the hook then captures
  whole sessions again, which only costs a redundant capture).

## Recording on the fly

When the user says "log this", "record this decision" or similar in the middle of a session,
write the ADR and/or `log.md` entry now, refresh `STATUS.md` and `index.md`, and keep to the
budgets. The session capture will still arrive later; when you compile it, do not record the same
decision twice.

## Answering from memory

For "what did we decide about X", "why did we do Y", "when did Z happen": check `index.md`, then
`grep` the ADRs and `log.md`, and only then search `journal/sessions/`. Quote what you find and
name the file. Ask the user only if the journal and the archive both come up empty.

## Lint and pruning

When asked for a health check, or when the hook reports a file over budget, apply
`references/lint-checklist.md`. Fix mechanical problems (links, index drift, budgets) directly;
raise judgment calls (contradictions, stale decisions) with the user.

## Boundaries

- `pending/` and `sessions/` contain conversation text, including shortened tool output, and stay
  out of git. Never stage them and never remove them from `journal/.gitignore`.
- Never put project content into the plugin; everything you write lives in `journal/` and the
  project's `CLAUDE.md`.
