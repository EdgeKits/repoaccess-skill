---
description: Fill a new or thin journal from the project's existing docs and code (proposes before writing).
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

Backfill the project journal from what the project already has. Use it once, when adopting the
journal in a project with history.

1. If `journal/` does not exist, tell the user to run `/journal-init` first, then stop.
2. Read the project's docs (PRDs, specs, READMEs, design notes, config) and survey the code and
   folder structure.
3. Draft, following the `project-journal` skill and its budgets:
   - `STATUS.md` with the real current state (Now / In progress / Next / Recent decisions);
   - `index.md` linking the journal pages and the project's own key docs;
   - ADRs (`adr/NNNN-*.md`, sequential) for significant past decisions that the docs or code
     give evidence for;
   - topic pages for subjects too large for STATUS, linked from the index.
4. **Never invent decisions.** Anything that looks like a decision but has no evidence in the
   docs or code goes in a list headed "Decisions I can't verify: confirm?", not into an ADR.
5. **Propose before writing.** Show the ADR list, the STATUS and index drafts and the questions.
   Write only after the user confirms, then commit as the skill's Committing section says.

Keep it short. The journal is useful because it is small, current and true.
