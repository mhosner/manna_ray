#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

echo "=== session-start.sh tests ==="

# Test: exits cleanly when not a Manna Ray project
echo "--- non-project directory ---"
setup_test_dir
rm -rf "$TEST_DIR/.manna-ray"
export CLAUDE_PROJECT_DIR="$TEST_DIR"
output=$(bash "$SCRIPT_DIR/../scripts/session-start.sh" 2>/dev/null || true)
assert_equals "" "$output" "empty output for non-project dir"
teardown_test_dir

# Test: warns on corrupted state
echo "--- corrupted state ---"
setup_test_dir
echo "NOT JSON{{{" > "$TEST_DIR/.manna-ray/state.json"
export CLAUDE_PROJECT_DIR="$TEST_DIR"
output=$(bash "$SCRIPT_DIR/../scripts/session-start.sh" 2>/dev/null)
TEST_COUNT=$((TEST_COUNT + 1))
if echo "$output" | grep -q "corrupted"; then
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "  PASS: warns about corruption"
else
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "  FAIL: should warn about corruption"
fi
teardown_test_dir

# Test: outputs valid JSON with systemMessage for valid project
echo "--- valid project ---"
setup_test_dir
source "$SCRIPT_DIR/../scripts/state.sh"
export CLAUDE_PROJECT_DIR="$TEST_DIR"
state_init "test-proj"
output=$(bash "$SCRIPT_DIR/../scripts/session-start.sh" 2>/dev/null)
TEST_COUNT=$((TEST_COUNT + 1))
if echo "$output" | jq -e '.systemMessage' >/dev/null 2>&1; then
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "  PASS: outputs valid JSON with systemMessage"
else
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "  FAIL: output should be valid JSON with systemMessage"
fi
teardown_test_dir

print_results
