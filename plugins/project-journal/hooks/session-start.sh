#!/usr/bin/env bash
# project-journal :: SessionStart hook
#
# Puts the journal's hot layer into context: STATUS.md, index.md and the tail of
# log.md, in that order, each within a fixed budget. Deterministic, no model call.
#
# WHY BUDGETS. Claude Code caps a hook's stdout at 10,000 characters; anything
# longer is saved to a file and replaced by a short preview the agent is not asked
# to read. A journal that outgrows the cap is therefore not loaded at all. So this
# hook prints at most about 8,000 characters, puts the most important file first,
# and says so plainly when a file is over its budget, so the overflow gets pruned
# instead of silently ignored.
set -euo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
J="$ROOT/journal"

# No journal in this project: do nothing.
[ -d "$J" ] || exit 0

STATUS_BUDGET=4000
INDEX_BUDGET=2500
LOG_BUDGET=1200

# Print a file's leading lines up to a byte budget, never cutting a line in half.
show() {
  local file="$1" budget="$2" name="$3"
  [ -f "$file" ] || return 0
  local size
  size="$(wc -c < "$file" | tr -d ' ')"
  echo "=== journal/$name ==="
  awk -v b="$budget" '{ n += length($0) + 1; if (n > b) exit; print }' "$file"
  if [ "$size" -gt "$budget" ]; then
    echo "[journal/$name is $size bytes, over its $budget-byte budget; only the part"
    echo " above was loaded. Prune it as the project-journal skill describes under"
    echo " Budgets, then read the full file only if you need what was cut.]"
  fi
  echo
}

echo "<project-journal>"
echo "Project memory from journal/. Use it instead of re-scanning the project;"
echo "drill into the pages index.md links to only when the task needs them."
echo

# Pending captures first: compiling them is the session's first job.
n=0
for f in "$J"/pending/*.md; do [ -e "$f" ] && n=$((n + 1)); done
if [ "$n" -gt 0 ]; then
  echo "=== ACTION REQUIRED FIRST ==="
  echo "$n session capture(s) in journal/pending/ are not compiled yet. Before anything"
  echo "else, run the compile procedure from the project-journal skill, then give a"
  echo "one-line summary of what you folded in."
  echo
fi

show "$J/STATUS.md" "$STATUS_BUDGET" "STATUS.md"
show "$J/index.md" "$INDEX_BUDGET" "index.md"

if [ -f "$J/log.md" ]; then
  echo "=== journal/log.md (latest entries) ==="
  # The last LOG_BUDGET bytes, minus the first (probably partial) line.
  tail -c "$LOG_BUDGET" "$J/log.md" | sed '1d'
  echo
fi

echo "</project-journal>"
exit 0
