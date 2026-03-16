#!/usr/bin/env bash
set -euo pipefail

# Detect if current directory is a Manna Ray project
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.manna-ray/state.json"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# Validate state file
if ! jq empty "$STATE_FILE" 2>/dev/null; then
  echo '{"systemMessage": "⚠ Manna Ray: state.json is corrupted. Run /manna-init to reinitialize."}'
  exit 0
fi

# Build status summary
PROJECT=$(jq -r '.project // "unknown"' "$STATE_FILE")

# Context health
CONTEXT_SUMMARY=""
for ctx in product.md company.md personas.md competitors.md goals.md; do
  STATUS=$(jq -r ".context[\"$ctx\"].status // \"missing\"" "$STATE_FILE")
  case "$STATUS" in
    current) CONTEXT_SUMMARY="${CONTEXT_SUMMARY}  ✓ ${ctx}\n" ;;
    stale)   CONTEXT_SUMMARY="${CONTEXT_SUMMARY}  ⚠ ${ctx} (stale)\n" ;;
    *)       CONTEXT_SUMMARY="${CONTEXT_SUMMARY}  ✗ ${ctx} (${STATUS})\n" ;;
  esac
done

# Active workflow
ACTIVE_WF=$(jq -r '[.workflows | to_entries[] | select(.value.status == "in_progress")] | first // empty | "\(.key) (step \(.value.currentStep + 1)/\(.value.steps | length))"' "$STATE_FILE" 2>/dev/null || echo "none")

# Recent runs (last 3)
RECENT=$(jq -r '.history | reverse | .[0:3] | .[] | "  • \(.skill) → \(.output)"' "$STATE_FILE" 2>/dev/null || echo "  (none)")

MSG="Manna Ray project: ${PROJECT}

Context files:
$(echo -e "$CONTEXT_SUMMARY")
Active workflow: ${ACTIVE_WF}

Recent runs:
${RECENT}

Use /manna-status for full dashboard."

echo "{\"systemMessage\": $(echo "$MSG" | jq -Rs .)}"
