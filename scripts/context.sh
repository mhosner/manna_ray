#!/usr/bin/env bash
# Context file validation for Manna Ray
# Source this file; do not execute directly.
# Requires: state.sh sourced first, jq, CLAUDE_PROJECT_DIR

set -euo pipefail

context_check_exists() {
  local ctx_file="$1"
  local full_path="${CLAUDE_PROJECT_DIR}/context/${ctx_file}"

  if [ ! -f "$full_path" ]; then
    echo "missing"
  elif [ ! -s "$full_path" ]; then
    echo "empty"
  else
    echo "exists"
  fi
}

context_check_staleness() {
  local ctx_file="$1"
  local sf="${CLAUDE_PROJECT_DIR}/.manna-ray/state.json"
  local full_path="${CLAUDE_PROJECT_DIR}/context/${ctx_file}"

  # If file doesn't exist in state, it's unknown
  local last_modified
  last_modified=$(jq -r ".context[\"$ctx_file\"].lastModified // empty" "$sf" 2>/dev/null)

  if [ -z "$last_modified" ] || [ "$last_modified" = "null" ]; then
    echo "unknown"
    return
  fi

  # Check if file changed since last recorded
  if [ -f "$full_path" ]; then
    local current_checksum stored_checksum
    current_checksum=$(_checksum "$full_path")
    stored_checksum=$(jq -r ".context[\"$ctx_file\"].checksum // empty" "$sf")

    if [ "$current_checksum" != "$stored_checksum" ]; then
      # File changed outside Manna Ray — refresh silently
      state_update_context "$ctx_file"
      echo "current"
      return
    fi
  fi

  # Check age
  local last_epoch now_epoch days_ago
  if date -d "$last_modified" +%s &>/dev/null; then
    last_epoch=$(date -d "$last_modified" +%s)
    now_epoch=$(date +%s)
  else
    last_epoch=$(date -j -f "%Y-%m-%d" "$last_modified" +%s 2>/dev/null || echo 0)
    now_epoch=$(date +%s)
  fi

  days_ago=$(( (now_epoch - last_epoch) / 86400 ))

  if [ "$days_ago" -gt 30 ]; then
    echo "stale"
  else
    echo "current"
  fi
}

context_validate_required() {
  local missing=0
  for ctx_file in "$@"; do
    local status
    status=$(context_check_exists "$ctx_file")
    case "$status" in
      missing)
        echo "ERROR: Required context file missing: context/$ctx_file" >&2
        echo "  Run /manna-context init or create it manually." >&2
        missing=1
        ;;
      empty)
        echo "WARNING: Context file exists but is empty: context/$ctx_file" >&2
        echo "  Run /manna-context update $ctx_file to populate it." >&2
        ;;
    esac
  done
  return $missing
}

context_total_size() {
  local total=0
  for ctx_file in "$@"; do
    local full_path="${CLAUDE_PROJECT_DIR}/context/${ctx_file}"
    if [ -f "$full_path" ]; then
      local size
      size=$(wc -c < "$full_path")
      total=$((total + size))
    fi
  done
  echo "$total"
}

context_check_size_warning() {
  local total
  total=$(context_total_size "$@")
  if [ "$total" -gt 50000 ]; then
    echo "WARNING: Combined context files exceed 50,000 characters ($total chars)." >&2
    echo "  Consider summarizing large context files to stay within token budget." >&2
  fi
}
