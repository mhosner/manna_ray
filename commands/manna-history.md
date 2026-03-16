---
description: Show Manna Ray run history and output files
argument-hint: [skill-name]
allowed-tools: Read, Bash(*)
---

You are showing Manna Ray run history.

## Load history

!`bash -c '
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR}"
export CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"

sf="${CLAUDE_PROJECT_DIR}/.manna-ray/state.json"
if [ ! -f "$sf" ]; then
  echo "NOT_INITIALIZED"
  exit 0
fi

if [ -n "$1" ] && [ "$1" != "" ]; then
  echo "=== History for: $1 ==="
  jq -r ".history | map(select(.skill == \"$1\")) | reverse | .[] | \"  \(.ranAt | split(\"T\")[0]) → \(.output)\"" "$sf"
else
  echo "=== Full Run History ==="
  jq -r ".history | reverse | .[] | \"  [\(.ranAt | split(\"T\")[0])] \(.skill) → \(.output)\"" "$sf"
fi

echo ""
echo "=== Available Outputs ==="
for dir in discovery strategy specs analytics launch productivity; do
  files=$(find "${CLAUDE_PROJECT_DIR}/outputs/$dir" -name "*.md" 2>/dev/null | sort -r)
  if [ -n "$files" ]; then
    echo "  outputs/$dir/:"
    echo "$files" | while read -r f; do
      echo "    $(basename "$f")"
    done
  fi
done
' -- $1`

If NOT_INITIALIZED, tell the user: "This is not a Manna Ray project. Run `/manna-init` to get started."

Otherwise, present the history in a clean, readable format.
- If the user provided a skill name ($1), filter to show only runs of that skill.
- Also show the output file listing so the user can see what artifacts exist.
