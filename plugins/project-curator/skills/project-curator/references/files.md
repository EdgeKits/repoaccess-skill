# The curator's files

Three files under `curator/` in the project folder. All English, whatever the chat language.

## profile.md

This project's facts and rules. Written by curator-init; changed afterwards only with the
maintainer's yes, and every change noted in the log. Read in full at every session open, so keep it
under 10,000 characters.

```markdown
# Curator profile: <project name>

> Coding agent: this folder belongs to the curator. Do not edit it; see your instruction file.

## People and language
- Maintainer: <name>
- Chat language: <language the curator uses with the maintainer>

## Project folder and repositories
- Connected folder: <folder name as connected to the Cowork project>
- Repositories:
  - `<path in the folder, "." for the root>`: <what it is>. Remote: <host/owner/repo or none>.
    A push <deploys to production / publishes to a public repo / triggers nothing>.
- Folders that are not repositories, if any: <path>: <what it holds>

## Coding agent
- Agent: <Claude Code / OpenCode / other>
- Instruction file: <CLAUDE.md / AGENTS.md / ...>
- Journal: <yes, project-journal in journal/; rules page: journal/<page>.md / no>

## What counts as blocking
<One or two sentences: who is harmed, and how badly, for a defect to become work here.>

## Sources of truth
- <subject>: <skill, docs server, document or code path that settles questions about it>

## Off limits
- Secret files, never read: <patterns found or named, beyond the defaults>
- <other files or topics the curator must not read, write or raise, with the reason and the date>

## Curator files
- Tracking: <"curator/ is tracked in git; the agent stages and commits it verbatim when it finishes
  a relay and never edits it" / "not under git">
- Other curator-owned files: <paths outside curator/ that the curator maintains, or none>

## Project rules
<!-- Rules for this project only, each with the date and, if known, the reason. -->
- <rule>
```

## status.md

Where things stand now. Rewritten at every update, never appended. **Budget: 12,000 characters.**
When it grows past that, move the detail to the log and keep one line here.

```markdown
# Curator status: <project name>

_Updated: YYYY-MM-DD_

## Now
- Repositories at last check: <repo: hash, clean or what is uncommitted>
- Relay in flight: <none / its title and what it asks>
- Waiting on the maintainer: <decisions or runs they owe, one line each>

## Standing rulings
- YYYY-MM-DD: "<the maintainer's decision, in their words>"

## Rules learned
- <a lesson from a mistake, stated as a rule>

## Open predictions
- <relay or run>: <what you expect to see, filed before it runs>

## Parked list
- <item>: <why it is parked>
```

Remove a standing ruling only when the maintainer reverses it, and log the reversal.

## log.md

Append-only history, newest at the bottom, one entry per session. Never read in full: read its end
at open (the last three entries, at most the last 6,000 characters), and search it when you need the
past. A project converted from an older setup keeps its earlier history in `curator/legacy/`; search
that too.

```markdown
## [YYYY-MM-DD] session | <short title>
- Open: read <files>; <repo> at <hash>, <clean / uncommitted>.
- Verified: <command> -> <result>.
- Review of "<relay title>": <approved / sent back>, because <evidence>.
- Ruling: "<maintainer's words>".
- Prediction settled: <prediction> -> <held / failed>.
- Mistake (mine): <what happened> -> rule: <rule added to status.md>.
- Close: <what the next session starts from>.
```

Strike a wrong statement with a reason (`~~...~~ (wrong: ...)`) instead of deleting it.

## drafts/

Full versions of files the agent will put into the repository unchanged, most often its instruction
file (`curator/drafts/CLAUDE.md`). A draft is written after discussion with the maintainer, approved
by them, copied into place by the agent with a hash check, and then deleted from `drafts/`.
