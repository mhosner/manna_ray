#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"
source "$SCRIPT_DIR/../scripts/state.sh"

echo "=== state.sh tests ==="

# Test: state_init creates a valid state.json
echo "--- state_init ---"
setup_test_dir
state_init "test-project"
assert_file_exists "$TEST_DIR/.manna-ray/state.json" "state.json created"
assert_json_field "$TEST_DIR/.manna-ray/state.json" ".project" "test-project" "project name set"
assert_json_field "$TEST_DIR/.manna-ray/state.json" ".context" "{}" "context starts empty"
assert_json_field "$TEST_DIR/.manna-ray/state.json" ".workflows" "{}" "workflows starts empty"
assert_json_field "$TEST_DIR/.manna-ray/state.json" ".history" "[]" "history starts empty array"
teardown_test_dir

# Test: state_read returns state JSON
echo "--- state_read ---"
setup_test_dir
state_init "read-test"
local_result=$(state_read)
actual_project=$(echo "$local_result" | jq -r '.project')
assert_equals "read-test" "$actual_project" "state_read returns valid JSON"
teardown_test_dir

# Test: state_update_context updates a context entry
echo "--- state_update_context ---"
setup_test_dir
state_init "ctx-test"
echo "test content" > "$TEST_DIR/context/product.md"
state_update_context "product.md"
assert_json_field "$TEST_DIR/.manna-ray/state.json" '.context["product.md"].status' "current" "context status set to current"
local_checksum=$(jq -r '.context["product.md"].checksum' "$TEST_DIR/.manna-ray/state.json")
assert_equals "false" "$([ -z "$local_checksum" ] || [ "$local_checksum" = "null" ] && echo true || echo false)" "checksum is non-null"
teardown_test_dir

# Test: state_add_run appends to history
echo "--- state_add_run ---"
setup_test_dir
state_init "run-test"
state_add_run "prd-generator" "outputs/specs/prd-test-2026-03-16.md"
assert_json_field "$TEST_DIR/.manna-ray/state.json" '.history | length' "1" "history has 1 entry"
assert_json_field "$TEST_DIR/.manna-ray/state.json" '.history[0].skill' "prd-generator" "history skill name"
assert_json_field "$TEST_DIR/.manna-ray/state.json" '.history[0].output' "outputs/specs/prd-test-2026-03-16.md" "history output path"
teardown_test_dir

# Test: state_recover handles corrupted JSON
echo "--- state corruption recovery ---"
setup_test_dir
mkdir -p "$TEST_DIR/.manna-ray"
echo "NOT VALID JSON{{{" > "$TEST_DIR/.manna-ray/state.json"
state_init "recovery-test"
assert_file_exists "$TEST_DIR/.manna-ray/state.json.bak" "corrupted file backed up"
assert_json_field "$TEST_DIR/.manna-ray/state.json" ".project" "recovery-test" "fresh state after recovery"
teardown_test_dir

print_results
