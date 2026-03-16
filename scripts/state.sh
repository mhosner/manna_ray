#!/usr/bin/env bash
# State store for Manna Ray — manages .manna-ray/state.json
# Source this file; do not execute directly.
# Requires: jq, CLAUDE_PROJECT_DIR environment variable

set -euo pipefail

_state_file() {
  echo "${CLAUDE_PROJECT_DIR}/.manna-ray/state.json"
}

_checksum() {
  local file="$1"
  if command -v md5sum &>/dev/null; then
    md5sum "$file" | cut -d' ' -f1
  else
    md5 -q "$file"
  fi
}

_now_iso() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

_today_iso() {
  date -u +"%Y-%m-%d"
}

state_init() {
  local project_name="${1:-unnamed}"
  local sf
  sf=$(_state_file)

  # Handle corrupted state
  if [ -f "$sf" ] && ! jq empty "$sf" 2>/dev/null; then
    cp "$sf" "${sf}.bak"
    echo "WARNING: Corrupted state.json backed up to state.json.bak" >&2
  fi

  mkdir -p "$(dirname "$sf")"
  jq -n \
    --arg project "$project_name" \
    --arg init "$(_now_iso)" \
    '{
      project: $project,
      initialized: $init,
      context: {},
      workflows: {},
      history: []
    }' > "$sf"
}

state_read() {
  cat "$(_state_file)"
}

state_update_context() {
  local ctx_file="$1"
  local sf
  sf=$(_state_file)
  local full_path="${CLAUDE_PROJECT_DIR}/context/${ctx_file}"

  if [ ! -f "$full_path" ]; then
    jq --arg f "$ctx_file" \
      '.context[$f] = { checksum: null, lastModified: null, status: "missing" }' \
      "$sf" > "${sf}.tmp" && mv "${sf}.tmp" "$sf"
    return
  fi

  local checksum
  checksum=$(_checksum "$full_path")
  local today
  today=$(_today_iso)

  jq --arg f "$ctx_file" --arg cs "$checksum" --arg today "$today" \
    '.context[$f] = { checksum: $cs, lastModified: $today, status: "current" }' \
    "$sf" > "${sf}.tmp" && mv "${sf}.tmp" "$sf"
}

state_add_run() {
  local skill="$1"
  local output="$2"
  local sf
  sf=$(_state_file)

  jq --arg skill "$skill" --arg output "$output" --arg ts "$(_now_iso)" \
    '.history += [{ skill: $skill, ranAt: $ts, output: $output }]' \
    "$sf" > "${sf}.tmp" && mv "${sf}.tmp" "$sf"
}

state_workflow_init() {
  local workflow_name="$1"
  local steps_json="$2"  # JSON array of step objects
  local sf
  sf=$(_state_file)

  jq --arg name "$workflow_name" --argjson steps "$steps_json" --arg ts "$(_now_iso)" \
    '.workflows[$name] = {
      status: "in_progress",
      startedAt: $ts,
      currentStep: 0,
      steps: $steps
    }' \
    "$sf" > "${sf}.tmp" && mv "${sf}.tmp" "$sf"
}

state_workflow_advance() {
  local workflow_name="$1"
  local output_path="$2"
  local sf
  sf=$(_state_file)

  if [ -z "$workflow_name" ]; then
    echo "Error: workflow name required" >&2
    return 1
  fi

  local current_step
  current_step=$(jq -r ".workflows[\"$workflow_name\"].currentStep // empty" "$sf")
  if [ -z "$current_step" ]; then
    echo "Error: no active workflow '$workflow_name'" >&2
    return 1
  fi

  jq --arg name "$workflow_name" --arg output "$output_path" --argjson step "$current_step" \
    '.workflows[$name].steps[$step].status = "completed" |
     .workflows[$name].steps[$step].output = $output |
     .workflows[$name].currentStep = ($step + 1)' \
    "$sf" > "${sf}.tmp" && mv "${sf}.tmp" "$sf"

  # Check if workflow is complete
  local total_steps
  total_steps=$(jq ".workflows[\"$workflow_name\"].steps | length" "$sf")
  local new_step=$((current_step + 1))
  if [ "$new_step" -ge "$total_steps" ]; then
    jq --arg name "$workflow_name" \
      '.workflows[$name].status = "completed"' \
      "$sf" > "${sf}.tmp" && mv "${sf}.tmp" "$sf"
  fi
}

state_workflow_skip() {
  local workflow_name="$1"
  local sf
  sf=$(_state_file)

  if [ -z "$workflow_name" ]; then
    echo "Error: workflow name required" >&2
    return 1
  fi

  local current_step
  current_step=$(jq -r ".workflows[\"$workflow_name\"].currentStep // empty" "$sf")
  if [ -z "$current_step" ]; then
    echo "Error: no active workflow '$workflow_name'" >&2
    return 1
  fi

  jq --arg name "$workflow_name" --argjson step "$current_step" \
    '.workflows[$name].steps[$step].status = "skipped" |
     .workflows[$name].currentStep = ($step + 1)' \
    "$sf" > "${sf}.tmp" && mv "${sf}.tmp" "$sf"
}

state_workflow_cancel() {
  local workflow_name="$1"
  local sf
  sf=$(_state_file)

  if [ -z "$workflow_name" ]; then
    echo "Error: workflow name required" >&2
    return 1
  fi

  jq --arg name "$workflow_name" \
    '.workflows[$name].status = "cancelled"' \
    "$sf" > "${sf}.tmp" && mv "${sf}.tmp" "$sf"
}

state_get_active_workflow() {
  local sf
  sf=$(_state_file)
  jq -r '[.workflows | to_entries[] | select(.value.status == "in_progress")] | .[0].key // empty' "$sf" 2>/dev/null || echo ""
}
