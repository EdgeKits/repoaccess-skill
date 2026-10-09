---
description: Compile pending session captures and the current session into the journal now.
allowed-tools: Read, Write, Edit, Bash, Glob
---

Run the **compile procedure** from the `project-journal` skill now, instead of waiting for the next
session. Include what happened in the current session so far, as well as every file in
`journal/pending/`.

If `journal/` does not exist, tell the user to run `/journal-init` first, then stop.

Follow the skill's procedure in full, including the budget check, moving captures to
`journal/sessions/`, the commit for the mode in `journal/.journal.json`, and the compile mark as the
last write. Finish with one line saying what was folded in.
