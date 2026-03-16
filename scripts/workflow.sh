#!/usr/bin/env bash
# Workflow engine for Manna Ray
# Source this file; do not execute directly.
# Requires: state.sh sourced, yq, jq, CLAUDE_PLUGIN_ROOT, CLAUDE_PROJECT_DIR

set -euo pipefail

_workflows_dir() {
  echo "${CLAUDE_PLUGIN_ROOT}/workflows"
}

workflow_list() {
  local dir
  dir=$(_workflows_dir)
  for f in "$dir"/*.yaml; do
    [ -f "$f" ] || continue
    local name desc
    name=$(yq -r '.name' "$f")
    desc=$(yq -r '.description' "$f")
    echo "$name: $desc"
  done
}

workflow_get_steps() {
  local workflow_name="$1"
  local file="${CLAUDE_PLUGIN_ROOT}/workflows/${workflow_name}.yaml"

  if [ ! -f "$file" ]; then
    echo "ERROR: Workflow '$workflow_name' not found" >&2
    return 1
  fi

  yq -o=json '.steps' "$file"
}

workflow_check_prereqs() {
  local workflow_name="$1"
  local file="${CLAUDE_PLUGIN_ROOT}/workflows/${workflow_name}.yaml"

  local prereqs
  prereqs=$(yq -o=json '.prerequisite_outputs // []' "$file")
  local count
  count=$(echo "$prereqs" | jq 'length')

  if [ "$count" -eq 0 ]; then
    return 0
  fi

  local missing=0
  for i in $(seq 0 $((count - 1))); do
    local pattern
    pattern=$(echo "$prereqs" | jq -r ".[$i]")
    local full_pattern="${CLAUDE_PROJECT_DIR}/${pattern}"

    # Use bash globbing
    local found=0
    for match in $full_pattern; do
      if [ -f "$match" ]; then
        found=1
        break
      fi
    done

    if [ "$found" -eq 0 ]; then
      echo "ERROR: Prerequisite not met: $pattern" >&2
      echo "  No files matching this pattern found in your project." >&2
      missing=1
    fi
  done

  return $missing
}

workflow_start() {
  local workflow_name="$1"

  # Check for active workflow
  local active
  active=$(state_get_active_workflow)
  if [ -n "$active" ]; then
    echo "ERROR: Workflow '$active' is already active." >&2
    echo "  Cancel it with /manna-workflow cancel, or continue with /manna-workflow next." >&2
    return 1
  fi

  # Check prerequisites
  workflow_check_prereqs "$workflow_name" || return 1

  # Build steps array for state
  local steps_json
  steps_json=$(workflow_get_steps "$workflow_name" | jq '[.[] | { skill: .skill, status: "pending", output: null }]')

  state_workflow_init "$workflow_name" "$steps_json"
}

workflow_get_current_step() {
  local workflow_name="$1"
  local sf="${CLAUDE_PROJECT_DIR}/.manna-ray/state.json"

  local current_step
  current_step=$(jq -r ".workflows[\"$workflow_name\"].currentStep" "$sf")
  local step_info
  step_info=$(jq ".workflows[\"$workflow_name\"].steps[$current_step]" "$sf")

  echo "$step_info"
}

workflow_get_step_context() {
  # Returns required_context for a specific step from the workflow YAML
  local workflow_name="$1"
  local step_index="$2"
  local file="${CLAUDE_PLUGIN_ROOT}/workflows/${workflow_name}.yaml"

  yq -o=json ".steps[$step_index].required_context // []" "$file"
}

workflow_get_previous_output() {
  # Returns the output path from the previous step (for feeds_into)
  local workflow_name="$1"
  local sf="${CLAUDE_PROJECT_DIR}/.manna-ray/state.json"

  local current_step
  current_step=$(jq -r ".workflows[\"$workflow_name\"].currentStep" "$sf")

  if [ "$current_step" -eq 0 ]; then
    echo ""
    return
  fi

  local prev=$((current_step - 1))
  jq -r ".workflows[\"$workflow_name\"].steps[$prev].output // empty" "$sf"
}
