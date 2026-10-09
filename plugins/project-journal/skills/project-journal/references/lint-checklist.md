# Journal lint: health checks

Run when asked, or when the SessionStart hook reports a file over budget. Fix mechanical problems
directly (links, index, budgets); raise judgment calls with the user.

1. **Budgets.** `wc -c journal/STATUS.md journal/index.md`. Over 4,000 or 2,500 characters: move
   the excess as the skill's "Where things belong" table says, then check again.
2. **History in STATUS.** Sections like "before that" or "earlier", or finished work still listed.
   Move it to `log.md`; STATUS keeps only what is true now.
3. **Broken links.** A page links to a file that does not exist. Fix or remove the link.
4. **Orphan pages.** A page nothing links to. Link it from `index.md`, or remove it if dead.
5. **Uncompiled captures.** Files in `journal/pending/`. Run the compile procedure.
6. **Stale STATUS.** Its `Updated` date is older than the latest `log.md` entries, or it describes
   work the log shows as finished. Rewrite it.
7. **Missing ADR.** The log mentions a decision with no ADR. Add one.
8. **Contradictions.** Two pages state conflicting facts or decisions. Show both to the user; the
   later accepted ADR usually wins, and the earlier one gets marked superseded.
9. **Index drift.** `index.md` misses pages that exist or lists pages that do not.
10. **Git hygiene.** `pending/` or `sessions/` files tracked by git, or the `.gitignore` lines from
    `/journal-init` missing. Report it; untrack only with the user's yes.
11. **Settings.** `journal/.journal.json` missing or with an unknown `commit` value. Suggest
    `/journal-init`.
