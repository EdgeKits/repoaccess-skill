#!/usr/bin/env bash
# project-journal :: SessionEnd + PreCompact hook
#
# Stages this session's conversation into journal/pending/<session-id>.md so the
# next session (or /wrap) can compile it into the journal. Deterministic: no model
# call, no network, nothing leaves the machine.
#
# WHAT IT KEEPS. Everything the transcript recorded after the last compile mark
# (journal/.journal-state), filtered for reading: your prompts and Claude's replies
# in full, tool calls and tool output shortened, thinking blocks, images and
# housekeeping entries dropped. One file per session, rewritten on every capture,
# so a PreCompact capture followed by a SessionEnd capture never duplicates.
#
# FAIL-SAFE DIRECTION. No mark, an unreadable mark, or a transcript format this
# script does not recognise all fall back to staging the whole session. A missing
# mark costs a redundant capture, never a lost one.
#
# Needs only bash, sed, awk, grep and tail (Git Bash on Windows has them all).
set -euo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
J="$ROOT/journal"

# No journal in this project: do nothing.
[ -d "$J" ] || exit 0

# Hook payload arrives as JSON on stdin; read the fields without requiring jq.
input="$(cat || true)"
field() {
  printf '%s' "$input" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n1
}
tp="$(field transcript_path)"
sid="$(field session_id)"
event="$(field hook_event_name)"
[ -n "$event" ] || event="capture"
[ -n "$sid" ] || sid="unknown-$(date +%Y%m%d-%H%M%S)"

# Windows paths arrive with backslashes, escaped once more inside JSON.
tp="$(printf '%s' "$tp" | sed 's/\\\\/\\/g')"
[ -n "$tp" ] && [ -f "$tp" ] || exit 0

mark="$J/.journal-state"
compiled=""
[ -f "$mark" ] && compiled="$(sed -n 's/^compiled=//p' "$mark" | head -n1)"

start=1
range="the whole session (no compile mark)"

if [ -n "$compiled" ] && grep -qE '"timestamp":"[0-9]' "$tp"; then
  # First line timestamped after the mark. ISO-8601 UTC strings of one shape
  # order correctly as strings. A line NUMBER, so untimestamped entries keep
  # travelling with their neighbours.
  start="$(
    awk -v m="$compiled" '
      match($0, /"timestamp":"[^"]*"/) {
        t = substr($0, RSTART + 13, RLENGTH - 14)
        if (t > m) { print NR; exit }
      }
    ' "$tp" || true
  )"

  # Nothing recorded after the mark: the journal is current for this session.
  [ -n "$start" ] || exit 0
  range="everything after the compile mark ($compiled)"

  # Was there a prompt the user typed after the mark? If the transcript format
  # marks typed prompts at all, and none came after the mark, the only thing
  # since the wrap is the wrap's own tail, which is not work.
  #
  # COUNTED, not grep -q: grep -q exits early, tail dies of SIGPIPE, and under
  # pipefail that reads as "no prompt" and would skip a capture that is owed.
  TYPED='"promptSource"[[:space:]]*:[[:space:]]*"typed"'
  known="$(grep -cE "$TYPED" "$tp" || true)"
  if [ "${known:-0}" -gt 0 ]; then
    typed="$(tail -n "+$start" "$tp" | grep -cE "$TYPED" || true)"
    [ "${typed:-0}" -gt 0 ] || exit 0
  fi
fi

mkdir -p "$J/pending"
out="$J/pending/$sid.md"
tmp="$out.tmp"

{
  echo "# Pending session capture"
  echo "# session: $sid"
  echo "# event: $event"
  echo "# captured: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# range: $range"
  echo "# Filtered transcript: prompts and replies in full; tool calls and output"
  echo "# shortened; thinking, images and housekeeping dropped. Compile with /wrap"
  echo "# or at the next session start, then it moves to journal/sessions/."
  echo
  tail -n "+$start" "$tp" | awk '
    function has(s) { return index($0, s) > 0 }
    function keep(n) {
      if (length($0) > n) print substr($0, 1, n) " [...cut " length($0) - n " chars]"
      else print
    }
    has("\"type\":\"summary\"")                              { keep(20000); next }
    has("\"type\":\"system\"")                               { keep(300);   next }
    has("\"type\":\"user\"") && has("\"type\":\"tool_result\"") { keep(300);   next }
    has("\"type\":\"user\"") && has("\"type\":\"image\"")     { keep(2000);  next }
    has("\"type\":\"user\"")                                 { keep(20000); next }
    has("\"type\":\"assistant\"") && has("\"type\":\"thinking\"") { next }
    has("\"type\":\"assistant\"") && has("\"type\":\"tool_use\"") { keep(400); next }
    has("\"type\":\"assistant\"")                            { keep(20000); next }
  '
} > "$tmp"

mv -f "$tmp" "$out"
exit 0
