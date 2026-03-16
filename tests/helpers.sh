#!/usr/bin/env bash
# Test helpers for Manna Ray scripts
set -euo pipefail

TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

setup_test_dir() {
  TEST_DIR=$(mktemp -d)
  export CLAUDE_PROJECT_DIR="$TEST_DIR"
  mkdir -p "$TEST_DIR/.manna-ray"
  mkdir -p "$TEST_DIR/context"
}

teardown_test_dir() {
  rm -rf "$TEST_DIR"
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local msg="${3:-}"
  TEST_COUNT=$((TEST_COUNT + 1))
  if [ "$expected" = "$actual" ]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    echo "  PASS: $msg"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo "  FAIL: $msg"
    echo "    expected: $expected"
    echo "    actual:   $actual"
  fi
}

assert_file_exists() {
  local path="$1"
  local msg="${2:-file exists: $path}"
  TEST_COUNT=$((TEST_COUNT + 1))
  if [ -f "$path" ]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    echo "  PASS: $msg"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo "  FAIL: $msg (file not found)"
  fi
}

assert_json_field() {
  local file="$1"
  local query="$2"
  local expected="$3"
  local msg="${4:-json field $query = $expected}"
  local actual
  actual=$(jq -r "$query" "$file" 2>/dev/null || echo "JQ_ERROR")
  assert_equals "$expected" "$actual" "$msg"
}

print_results() {
  echo ""
  echo "Results: $PASS_COUNT/$TEST_COUNT passed, $FAIL_COUNT failed"
  [ "$FAIL_COUNT" -eq 0 ]
}
