# Journal file conventions and templates

Exact formats for each journal file. Keep entries short: the journal is useful because it is
small and current.

## .journal.json

Settings, written by `/journal-init`. One key for now:

```json
{ "commit": "project-repo" }
```

`own-repo`, `project-repo` or `none`; the skill's Committing section says what each one does.

## index.md

The catalog. One line per page: link and a one-line summary, grouped. Budget: 2,500 characters.
List only the latest ten ADRs and point at the folder for the rest.

```markdown
# Journal index

Read this first, then open only the pages the task needs.

## Core
- [STATUS.md](STATUS.md) - where we are now
- [execution-plan.md](execution-plan.md) - phases and checkboxes
- [log.md](log.md) - timeline, newest at the bottom

## Topics
- [billing.md](billing.md) - how payments and refunds work here

## Decisions
- [ADR-0012](adr/0012-move-sessions-to-kv.md) - sessions move from cookies to KV
- All decisions: adr/

## Project docs
- ../CLAUDE.md - rules and conventions
- ../docs/spec.md - product spec
```

## STATUS.md

Where we are now. Rewritten on every update, never appended. Budget: 4,000 characters.

```markdown
# STATUS: <project>

_Updated: YYYY-MM-DD_

## Now
<one to three lines: the current focus>

## In progress
- <task>: <state or blocker>

## Next
- <next concrete steps, in order>

## Recent decisions
- [ADR-000N](adr/000N-title.md) <one line> (last five; the rest are in adr/)
```

## log.md

Append-only, with one greppable prefix so `grep "^## \[" journal/log.md` lists every entry.
`type` is one of: session, decision, milestone, lint, note. Only the end of the file loads at
session start, so keep each entry to a few bullets.

```markdown
# Log

## [2026-10-08] session | login form validation
- Moved validation to the server; client keeps only format hints.
- Decision: one schema shared by client and server, see ADR-0007.
- Next: error messages for locked accounts.

## [2026-10-09] decision | drop the legacy REST endpoints
- See ADR-0008.
```

## adr/NNNN-title.md

One immutable file per decision, numbered from 0001. To change a decision, write a new ADR and
mark the old one superseded.

```markdown
# ADR-000N: <title>

- **Date:** YYYY-MM-DD
- **Status:** accepted | superseded by ADR-000M | proposed
- **Context:** <the situation and the forces at play>
- **Decision:** <what we decided>
- **Consequences:** <trade-offs and follow-ups>
```

## execution-plan.md

Phases with checkboxes, usually drafted during planning and kept current.

```markdown
# Execution plan

## Phase 1: <name>
- [x] <done task>
- [ ] <open task>

## Phase 2: <name>
- [ ] <task>
```

## Topic pages

`journal/<topic>.md` for anything too large or too specific for STATUS: a digest of a spec, the
findings of an investigation, the gotchas of one integration. Free form, linked from `index.md`.

## sessions/

Compiled captures, named `YYYY-MM-DDTHHMM-<session-id>.md` after the compile time (UTC). Nothing reads them automatically. Search
them when the pages do not answer a question. You can delete old ones whenever you like.
