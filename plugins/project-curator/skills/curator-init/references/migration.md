# Converting an older curator setup

For a project whose curator so far lived in a root `CURATOR.md` and a single status file (often
named `curator-status.md` or `<project>-curator-status.md`), possibly with handoff and backlog files.
Nothing is deleted. Everything is moved or copied verbatim, and the maintainer approves the plan
before anything is written.

## 1. Inventory

List the old curator files with their sizes in characters, and say which ones git tracks. Read the
old `CURATOR.md` in full. Do not read the old status file in full if it is large: read its
headings and its last sections.

## 2. Sort the old CURATOR.md

Go through it section by section and sort each rule into one of three groups:

- **Already in project-curator** (roles, relay format, verification, owning mistakes, session
  procedure, language for artifacts): not carried over.
- **Project facts** (repositories, what a push does, sources of truth, off-limits files, curator
  file tracking, other curator-owned files): go to the matching profile sections.
- **Project rules** (anything specific that has no equivalent in the skill): go verbatim, with the
  old section number, to "Project rules" in the profile.

## 3. Propose the plan

Show the maintainer, in their chat language:

- the profile you would write, with every carried-over rule marked by its old section;
- the rules you would drop as already covered, one line each, so they can object;
- where the history goes: the old status file moves unchanged to `curator/legacy/`, and the new
  `curator/log.md` opens with an entry pointing to it;
- the new `curator/status.md`: "Now" from the current git state, and the standing rulings, rules
  learned, open predictions and parked list taken from the old status file's latest state;
- what happens to the old files: the old `CURATOR.md` and status file move to `curator/legacy/`
  (moved, not copied, so nothing reads stale copies by mistake, and the content stays byte for byte
  the same); handoff and backlog files stay where they are and are listed under "Other
  curator-owned files" unless the maintainer wants them folded in.

Write nothing until the maintainer says yes.

## 4. Write, check, report

- Write the three files and move the old ones.
- Check: the new `status.md` is under 12,000 characters; `profile.md` under 10,000; every rule the
  maintainer kept is in the profile; each moved file has the same hash in `curator/legacy/` as it
  had before the move.
- If the old files are tracked in git, the moves show as renames the agent must commit: include that
  in the agent-side relays of curator-init step 6, together with updating any line in the agent's
  instruction file that names the old file paths.
- Then continue with curator-init step 5.
