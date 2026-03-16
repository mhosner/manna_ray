#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"
source "$SCRIPT_DIR/../scripts/state.sh"
source "$SCRIPT_DIR/../scripts/context.sh"

echo "=== context.sh tests ==="

# Test: context_check_exists detects missing file
echo "--- context_check_exists ---"
setup_test_dir
state_init "ctx-exist-test"
result=$(context_check_exists "product.md")
assert_equals "missing" "$result" "detects missing context file"
teardown_test_dir

# Test: context_check_exists detects empty file
echo "--- context_check_exists (empty) ---"
setup_test_dir
state_init "ctx-empty-test"
touch "$TEST_DIR/context/product.md"
result=$(context_check_exists "product.md")
assert_equals "empty" "$result" "detects empty context file"
teardown_test_dir

# Test: context_check_exists detects populated file
echo "--- context_check_exists (populated) ---"
setup_test_dir
state_init "ctx-pop-test"
echo "Product roadmap here" > "$TEST_DIR/context/product.md"
result=$(context_check_exists "product.md")
assert_equals "exists" "$result" "detects populated context file"
teardown_test_dir

# Test: context_check_staleness detects stale file
echo "--- context_check_staleness ---"
setup_test_dir
state_init "stale-test"
echo "Old content" > "$TEST_DIR/context/product.md"
local_sf="$TEST_DIR/.manna-ray/state.json"
# Use the actual file checksum so the staleness check doesn't think it was externally edited
actual_cs=$(_checksum "$TEST_DIR/context/product.md")
old_date=$(date -u -d "-60 days" +"%Y-%m-%d" 2>/dev/null || date -u -v-60d +"%Y-%m-%d")
jq --arg f "product.md" --arg d "$old_date" --arg cs "$actual_cs" \
  '.context[$f] = { checksum: $cs, lastModified: $d, status: "current" }' \
  "$local_sf" > "${local_sf}.tmp" && mv "${local_sf}.tmp" "$local_sf"
result=$(context_check_staleness "product.md")
assert_equals "stale" "$result" "detects stale context file (>30 days)"
teardown_test_dir

# Test: context_check_staleness detects current file
echo "--- context_check_staleness (current) ---"
setup_test_dir
state_init "current-test"
echo "Fresh content" > "$TEST_DIR/context/product.md"
state_update_context "product.md"
result=$(context_check_staleness "product.md")
assert_equals "current" "$result" "detects current context file"
teardown_test_dir

# Test: context_total_size
echo "--- context_total_size ---"
setup_test_dir
state_init "size-test"
printf '%0.s.' {1..100} > "$TEST_DIR/context/product.md"
printf '%0.s.' {1..200} > "$TEST_DIR/context/personas.md"
result=$(context_total_size "product.md" "personas.md")
assert_equals "300" "$result" "total size of 2 context files"
teardown_test_dir

print_results
