#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"
source "$SCRIPT_DIR/../scripts/state.sh"
source "$SCRIPT_DIR/../scripts/context.sh"

# Set CLAUDE_PLUGIN_ROOT to project root for tests
export CLAUDE_PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/../scripts/workflow.sh"

echo "=== workflow.sh tests ==="

# Test: workflow_list returns available workflows
echo "--- workflow_list ---"
result=$(workflow_list)
TEST_COUNT=$((TEST_COUNT + 1))
if echo "$result" | grep -q "idea-to-sprint"; then
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "  PASS: workflow_list includes idea-to-sprint"
else
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "  FAIL: workflow_list missing idea-to-sprint"
fi

# Test: workflow_get_steps returns correct step count
echo "--- workflow_get_steps ---"
steps=$(workflow_get_steps "idea-to-sprint")
step_count=$(echo "$steps" | jq 'length')
assert_equals "6" "$step_count" "idea-to-sprint has 6 steps"

# Test: workflow_get_step_skill returns correct skill name
echo "--- workflow_get_step_skill ---"
skill=$(echo "$steps" | jq -r '.[0].skill')
assert_equals "prioritization-engine" "$skill" "first step is prioritization-engine"

# Test: workflow_check_prereqs fails when no roadmap exists
echo "--- workflow_check_prereqs ---"
setup_test_dir
state_init "prereq-test"
result=$(workflow_check_prereqs "idea-to-sprint" 2>&1 || true)
TEST_COUNT=$((TEST_COUNT + 1))
if echo "$result" | grep -qi "roadmap"; then
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "  PASS: prereq check warns about missing roadmap"
else
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "  FAIL: prereq check should warn about missing roadmap"
fi
teardown_test_dir

# Test: workflow_check_prereqs passes when roadmap exists
echo "--- workflow_check_prereqs (satisfied) ---"
setup_test_dir
state_init "prereq-ok-test"
mkdir -p "$TEST_DIR/outputs/strategy"
echo "Roadmap content" > "$TEST_DIR/outputs/strategy/roadmap-q2-2026.md"
workflow_check_prereqs "idea-to-sprint"
TEST_COUNT=$((TEST_COUNT + 1))
PASS_COUNT=$((PASS_COUNT + 1))
echo "  PASS: prereq check passes with roadmap present"
teardown_test_dir

# Test: workflow_start initializes state
echo "--- workflow_start ---"
setup_test_dir
state_init "start-test"
mkdir -p "$TEST_DIR/outputs/strategy"
echo "Roadmap" > "$TEST_DIR/outputs/strategy/roadmap-q2-2026.md"
workflow_start "idea-to-sprint"
assert_json_field "$TEST_DIR/.manna-ray/state.json" '.workflows["idea-to-sprint"].status' "in_progress" "workflow status is in_progress"
assert_json_field "$TEST_DIR/.manna-ray/state.json" '.workflows["idea-to-sprint"].currentStep' "0" "currentStep is 0"
assert_json_field "$TEST_DIR/.manna-ray/state.json" '.workflows["idea-to-sprint"].steps | length' "6" "6 steps initialized"
teardown_test_dir

print_results
