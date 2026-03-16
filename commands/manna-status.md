---
description: Show Manna Ray project dashboard
allowed-tools: Read, Bash(*)
---

You are showing the Manna Ray project dashboard.

## Load project state

!`bash -c '
export CLAUDE_PROJECT_DIR="$(pwd)"
source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh
source ${CLAUDE_PLUGIN_ROOT}/scripts/context.sh

sf="${CLAUDE_PROJECT_DIR}/.manna-ray/state.json"
if [ ! -f "$sf" ]; then
  echo "NOT_INITIALIZED"
  exit 0
fi

echo "PROJECT:$(jq -r ".project" "$sf")"
echo ""

echo "=== Context Health ==="
for f in product.md company.md personas.md competitors.md goals.md; do
  exists=$(context_check_exists "$f")
  if [ "$exists" = "missing" ]; then
    echo "  ✗ $f — MISSING"
  elif [ "$exists" = "empty" ]; then
    echo "  ⚠ $f — EMPTY"
  else
    staleness=$(context_check_staleness "$f")
    last=$(jq -r ".context[\"$f\"].lastModified // \"unknown\"" "$sf")
    if [ "$staleness" = "stale" ]; then
      echo "  ⚠ $f — STALE (last: $last)"
    else
      echo "  ✓ $f — current (last: $last)"
    fi
  fi
done

echo ""
echo "=== Active Workflow ==="
active=$(jq -r "[.workflows | to_entries[] | select(.value.status == \"in_progress\")] | first // empty | .key" "$sf" 2>/dev/null)
if [ -n "$active" ] && [ "$active" != "null" ]; then
  step=$(jq -r ".workflows[\"$active\"].currentStep" "$sf")
  total=$(jq -r ".workflows[\"$active\"].steps | length" "$sf")
  echo "  $active — step $((step + 1))/$total"
  skill=$(jq -r ".workflows[\"$active\"].steps[$step].skill" "$sf")
  echo "  Next: $skill"
else
  echo "  (none)"
fi

echo ""
echo "=== Recent Runs (last 5) ==="
jq -r ".history | reverse | .[0:5] | .[] | \"  • \(.skill) (\(.ranAt | split(\"T\")[0])) → \(.output)\"" "$sf" 2>/dev/null || echo "  (none)"
'`

If NOT_INITIALIZED, tell the user: "This is not a Manna Ray project. Run `/manna-init` to get started."

Otherwise, present the dashboard output in a clean, readable format.
