# Manna Ray Plugin Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Manna Ray Claude Code plugin — a PM Operating System that orchestrates 31 skills with context management, workflow chaining, and project state tracking.

**Architecture:** Native Claude Code plugin (markdown commands + bash scripts + JSON + YAML). No compilation or build step. Commands are `.md` files auto-discovered from `commands/`. Scripts handle deterministic operations (state CRUD, checksums, YAML parsing). `yq` is a required dependency for YAML parsing.

**Tech Stack:** Bash scripts, Markdown commands, JSON state, YAML workflow definitions, `jq` for JSON manipulation, `yq` for YAML parsing, `md5sum`/`md5` for checksums.

**Spec:** `docs/superpowers/specs/2026-03-16-manna-ray-cli-design.md`

---

## File Structure

### Plugin infrastructure (create)
- `.claude-plugin/plugin.json` — plugin manifest
- `hooks/hooks.json` — SessionStart hook config
- `scripts/state.sh` — state.json CRUD (sourced by other scripts)
- `scripts/context.sh` — context file validation & checksums (sourced by other scripts)
- `scripts/workflow.sh` — workflow YAML parsing & state management
- `scripts/session-start.sh` — project detection & status summary on session start
- `tests/test-state.sh` — tests for state.sh
- `tests/test-context.sh` — tests for context.sh
- `tests/test-workflow.sh` — tests for workflow.sh
- `tests/test-session-start.sh` — tests for session-start.sh
- `tests/helpers.sh` — shared test helpers (setup/teardown temp dirs)

### Commands (create)
- `commands/manna-init.md` — `/manna-init` scaffold a PM project
- `commands/manna-context.md` — `/manna-context` context file operations
- `commands/manna-run.md` — `/manna-run [skill]` run skill with context injection
- `commands/manna-workflow.md` — `/manna-workflow` workflow operations
- `commands/manna-status.md` — `/manna-status` project dashboard
- `commands/manna-history.md` — `/manna-history` run history & outputs

### Templates (create)
- `templates/context/product.md` — product context template
- `templates/context/company.md` — company context template
- `templates/context/personas.md` — personas context template
- `templates/context/competitors.md` — competitors context template
- `templates/context/goals.md` — goals context template
- `templates/claude-md/project.md` — CLAUDE.md template for PM projects

### Workflows (create)
- `workflows/idea-to-sprint.yaml` — Workflow C definition (primary)
- `workflows/zero-to-one.yaml` — Workflow A definition (deferred)
- `workflows/quarterly-planning.yaml` — Workflow B definition (deferred)
- `workflows/go-to-market.yaml` — Workflow D definition (deferred)
- `workflows/feedback-loop.yaml` — Workflow E definition (deferred)

### Agents (create)
- `agents/context-updater.md` — subagent for updating context files

### Skills (modify)
- `skills/prioritization-engine/SKILL.md` — add extended frontmatter
- `skills/prd-generator/SKILL.md` — add extended frontmatter
- `skills/ab-test-designer/SKILL.md` — add extended frontmatter
- `skills/technical-spec-writer/SKILL.md` — add extended frontmatter
- `skills/user-story-writer/SKILL.md` — add extended frontmatter
- `skills/launch-checklist-generator/SKILL.md` — add extended frontmatter

### Normalize (rename)
- `skills/cogs-analyzer/SKILL.MD` → `skills/cogs-analyzer/SKILL.md`
- `skills/tech-debt-evaluator/SKILL.MD` → `skills/tech-debt-evaluator/SKILL.md`
- `skills/user-journey-mapper/SKILL.MD` → `skills/user-journey-mapper/SKILL.md`

---

## Chunk 1: Foundation — Plugin Manifest, Test Harness, State Store

### Task 1: Plugin manifest and directory structure

**Files:**
- Create: `.claude-plugin/plugin.json`

- [ ] **Step 1: Create plugin manifest**

```json
{
  "name": "manna-ray",
  "version": "0.1.0",
  "description": "Product Management OS — orchestrates PM skills, context, and workflows",
  "author": {
    "name": "Matt"
  },
  "license": "MIT",
  "keywords": ["product-management", "pm-tools", "workflows", "skills"]
}
```

- [ ] **Step 2: Create directory structure**

```bash
mkdir -p commands agents hooks scripts workflows templates/context templates/claude-md tests
```

- [ ] **Step 3: Normalize SKILL.MD → SKILL.md for 3 skills**

```bash
mv skills/cogs-analyzer/SKILL.MD skills/cogs-analyzer/SKILL.md
mv skills/tech-debt-evaluator/SKILL.MD skills/tech-debt-evaluator/SKILL.md
mv skills/user-journey-mapper/SKILL.MD skills/user-journey-mapper/SKILL.md
```

- [ ] **Step 4: Verify plugin CLAUDE.md exists**

The contributor-facing `CLAUDE.md` at the plugin root should already exist (created during brainstorming). Verify:
```bash
test -f CLAUDE.md && echo "EXISTS" || echo "MISSING"
```
If MISSING, create it with project development guidelines (see spec Section 6).

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/plugin.json CLAUDE.md
git add skills/cogs-analyzer/SKILL.md skills/tech-debt-evaluator/SKILL.md skills/user-journey-mapper/SKILL.md
git commit -m "feat: add plugin manifest and normalize SKILL.md casing"
```

### Task 2: Test harness

**Files:**
- Create: `tests/helpers.sh`

- [ ] **Step 1: Write test helpers**

```bash
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
```

- [ ] **Step 2: Verify test helpers load**

Run: `bash -c 'source tests/helpers.sh && echo "OK"'`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add tests/helpers.sh
git commit -m "feat: add test harness with helpers"
```

### Task 3: State store script

**Files:**
- Create: `scripts/state.sh`
- Create: `tests/test-state.sh`

- [ ] **Step 1: Write failing tests for state.sh**

```bash
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
# Checksum should be non-null
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/test-state.sh`
Expected: FAIL (state.sh functions not defined)

- [ ] **Step 3: Write state.sh implementation**

```bash
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

  local current_step
  current_step=$(jq -r ".workflows[\"$workflow_name\"].currentStep" "$sf")

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

  local current_step
  current_step=$(jq -r ".workflows[\"$workflow_name\"].currentStep" "$sf")

  jq --arg name "$workflow_name" --argjson step "$current_step" \
    '.workflows[$name].steps[$step].status = "skipped" |
     .workflows[$name].currentStep = ($step + 1)' \
    "$sf" > "${sf}.tmp" && mv "${sf}.tmp" "$sf"
}

state_workflow_cancel() {
  local workflow_name="$1"
  local sf
  sf=$(_state_file)

  jq --arg name "$workflow_name" \
    '.workflows[$name].status = "cancelled"' \
    "$sf" > "${sf}.tmp" && mv "${sf}.tmp" "$sf"
}

state_get_active_workflow() {
  local sf
  sf=$(_state_file)
  jq -r '[.workflows | to_entries[] | select(.value.status == "in_progress")] | first // empty | .key' "$sf" 2>/dev/null || echo ""
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/test-state.sh`
Expected: All PASS

- [ ] **Step 5: Commit**

```bash
git add scripts/state.sh tests/test-state.sh
git commit -m "feat: add state store script with tests"
```

### Task 4: Context validation script

**Files:**
- Create: `scripts/context.sh`
- Create: `tests/test-context.sh`

- [ ] **Step 1: Write failing tests for context.sh**

```bash
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
# Manually set lastModified to 60 days ago
local_sf="$TEST_DIR/.manna-ray/state.json"
old_date=$(date -u -d "-60 days" +"%Y-%m-%d" 2>/dev/null || date -u -v-60d +"%Y-%m-%d")
jq --arg f "product.md" --arg d "$old_date" \
  '.context[$f] = { checksum: "old", lastModified: $d, status: "current" }' \
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/test-context.sh`
Expected: FAIL (context.sh functions not defined)

- [ ] **Step 3: Write context.sh implementation**

```bash
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
  # Validates all required context files exist and are non-empty
  # Returns 0 if all valid, 1 if any missing/empty
  # Outputs warning messages to stderr
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
  # Returns combined character count of specified context files
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/test-context.sh`
Expected: All PASS

- [ ] **Step 5: Commit**

```bash
git add scripts/context.sh tests/test-context.sh
git commit -m "feat: add context validation script with tests"
```

---

## Chunk 2: Workflow Engine and Templates

### Task 5: Workflow script

**Files:**
- Create: `scripts/workflow.sh`
- Create: `tests/test-workflow.sh`
- Create: `workflows/idea-to-sprint.yaml`

- [ ] **Step 1: Write the idea-to-sprint workflow YAML**

```yaml
name: idea-to-sprint
description: Take an approved roadmap initiative to sprint-ready tickets
prerequisite_outputs:
  - outputs/strategy/roadmap-*.md

steps:
  - skill: prioritization-engine
    required_context: [product.md, goals.md]
    output_dir: outputs/strategy
    feeds_into: prd-generator

  - skill: prd-generator
    required_context: [product.md, personas.md, goals.md]
    output_dir: outputs/specs
    feeds_into: ab-test-designer
    suggests_update: [product.md]

  - skill: ab-test-designer
    required_context: [product.md]
    output_dir: outputs/analytics
    feeds_into: technical-spec-writer

  - skill: technical-spec-writer
    required_context: [product.md]
    output_dir: outputs/specs
    feeds_into: user-story-writer

  - skill: user-story-writer
    required_context: [personas.md]
    output_dir: outputs/specs
    feeds_into: launch-checklist-generator

  - skill: launch-checklist-generator
    required_context: [product.md]
    output_dir: outputs/launch
```

- [ ] **Step 2: Write failing tests for workflow.sh**

```bash
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
echo "$result" | grep -q "idea-to-sprint"
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
echo "$result" | grep -qi "roadmap"
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
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `bash tests/test-workflow.sh`
Expected: FAIL (workflow.sh functions not defined)

- [ ] **Step 4: Write workflow.sh implementation**

```bash
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
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `bash tests/test-workflow.sh`
Expected: All PASS

- [ ] **Step 6: Commit**

```bash
git add scripts/workflow.sh tests/test-workflow.sh workflows/idea-to-sprint.yaml
git commit -m "feat: add workflow engine and idea-to-sprint definition"
```

### Task 6: Context file templates

**Files:**
- Create: `templates/context/product.md`
- Create: `templates/context/company.md`
- Create: `templates/context/personas.md`
- Create: `templates/context/competitors.md`
- Create: `templates/context/goals.md`

- [ ] **Step 1: Write product.md template**

```markdown
# Product Context

## Product Overview
<!-- What is the product? Who is it for? What problem does it solve? -->

## Current Roadmap
<!-- What are the major initiatives in flight? What's the Now/Next/Later? -->

## Key Metrics
<!-- What are the core metrics you track? North Star? Input metrics? -->

## Known Issues
<!-- What are the biggest pain points or technical debt items? -->

## Current Positioning
<!-- How is the product positioned in the market? What's the value prop? -->
```

- [ ] **Step 2: Write company.md template**

```markdown
# Company Context

## Strategic Priorities
<!-- What are the company's top 3-5 strategic priorities this year? -->

## Team Structure
<!-- What teams exist? Who owns what? How big is the product/eng org? -->

## Business Model
<!-- How does the company make money? Revenue model? Unit economics? -->

## Constraints
<!-- Budget constraints? Hiring plans? Technical limitations? -->
```

- [ ] **Step 3: Write personas.md template**

```markdown
# Personas

## Persona 1: [Name]
<!-- Role/title, company size, experience level -->

### Jobs to Be Done
<!-- What are they trying to accomplish? Functional, emotional, social jobs -->

### Pain Points
<!-- What frustrations do they experience today? -->

### Current Solutions
<!-- What tools/workarounds do they use today? -->

---

## Persona 2: [Name]
<!-- Add more personas as needed -->
```

- [ ] **Step 4: Write competitors.md template**

```markdown
# Competitive Landscape

## Direct Competitors

### [Competitor 1]
<!-- Product, positioning, strengths, weaknesses, pricing -->

### [Competitor 2]
<!-- Add more competitors as needed -->

## Win/Loss Themes
<!-- Why do customers choose us? Why do they choose competitors? -->

## Market Gaps
<!-- Where are competitors weak? What's underserved? -->

## Pricing Intelligence
<!-- Competitor pricing models and ranges -->
```

- [ ] **Step 5: Write goals.md template**

```markdown
# Goals & OKRs

## Annual Goals
<!-- Company-level goals for the year -->

## Quarterly OKRs (Current Quarter)

### Objective 1: [Title]
- KR1: [Measurable key result]
- KR2: [Measurable key result]

### Objective 2: [Title]
- KR1: [Measurable key result]

## Success Metrics
<!-- How do you measure success? Leading and lagging indicators -->

## Known Blockers
<!-- What's preventing progress on goals? -->
```

- [ ] **Step 6: Commit**

```bash
git add templates/context/
git commit -m "feat: add context file templates"
```

### Task 7: Project CLAUDE.md template

**Files:**
- Create: `templates/claude-md/project.md`

- [ ] **Step 1: Write the CLAUDE.md template**

```markdown
# Manna Ray Project

This is a Manna Ray product management project. Use the Manna Ray plugin commands for structured PM workflows.

## Context Files

Before answering PM questions, check the relevant context files in `context/`:
- `context/product.md` — product roadmap, metrics, known issues
- `context/company.md` — strategic priorities, team structure, business model
- `context/personas.md` — user archetypes, jobs-to-be-done, pain points
- `context/competitors.md` — competitive intel, win/loss themes, pricing
- `context/goals.md` — quarterly/annual OKRs, success metrics

## Commands

Use Manna Ray commands for structured work:
- `/manna-run [skill-name]` — run a PM skill with automatic context injection
- `/manna-workflow start [name]` — begin a multi-step workflow
- `/manna-workflow next` — advance to the next workflow step
- `/manna-status` — see project dashboard (context health, workflow progress, recent runs)
- `/manna-context update [file]` — update a context file with new insights
- `/manna-history` — see past skill runs and their outputs

## Prior Work

Before generating new analyses, check `outputs/` for existing work:
- `outputs/discovery/` — interview snapshots, JTBD, research synthesis
- `outputs/strategy/` — roadmaps, positioning, competitive analysis
- `outputs/specs/` — PRDs, tech specs, user stories
- `outputs/analytics/` — A/B tests, funnels, metrics
- `outputs/launch/` — sales kits, launch checklists
- `outputs/productivity/` — daily/weekly plans

## Active Workflows

Check `.manna-ray/state.json` for active workflow state before starting new work.

## Context Updates

When your analysis produces new insights about the product, personas, competitors, or goals, suggest updating the relevant context file so future analyses benefit from this knowledge.
```

- [ ] **Step 2: Commit**

```bash
git add templates/claude-md/project.md
git commit -m "feat: add project CLAUDE.md template"
```

### Task 8: Remaining workflow YAML definitions (deferred — not tested end-to-end)

**Files:**
- Create: `workflows/zero-to-one.yaml`
- Create: `workflows/quarterly-planning.yaml`
- Create: `workflows/go-to-market.yaml`
- Create: `workflows/feedback-loop.yaml`

- [ ] **Step 1: Write zero-to-one.yaml**

```yaml
name: zero-to-one
description: Take a vague market opportunity and turn it into a validated, testable solution

steps:
  - skill: user-interview-analyzer
    required_context: [personas.md]
    output_dir: outputs/discovery
    feeds_into: research-synthesis-engine

  - skill: research-synthesis-engine
    required_context: [product.md, personas.md]
    output_dir: outputs/discovery
    feeds_into: jtbd-extractor
    suggests_update: [personas.md]

  - skill: jtbd-extractor
    required_context: [personas.md]
    output_dir: outputs/discovery
    feeds_into: user-journey-mapper
    suggests_update: [personas.md]

  - skill: user-journey-mapper
    required_context: [personas.md, product.md]
    output_dir: outputs/discovery
    feeds_into: opportunity-solution-tree

  - skill: opportunity-solution-tree
    required_context: [product.md, personas.md, goals.md]
    output_dir: outputs/discovery
    suggests_update: [product.md]
```

- [ ] **Step 2: Write quarterly-planning.yaml (linearized)**

```yaml
name: quarterly-planning
description: Align the company on what to build next quarter based on market realities and business constraints

steps:
  - skill: north-star-finder
    required_context: [product.md, goals.md]
    output_dir: outputs/analytics
    feeds_into: landscape-mapper
    suggests_update: [goals.md, product.md]

  - skill: landscape-mapper
    required_context: [competitors.md, product.md]
    output_dir: outputs/strategy
    feeds_into: competitive-profile-builder
    suggests_update: [competitors.md]

  - skill: competitive-profile-builder
    required_context: [competitors.md, product.md]
    output_dir: outputs/strategy
    feeds_into: tech-debt-evaluator
    suggests_update: [competitors.md]

  - skill: tech-debt-evaluator
    required_context: [product.md]
    output_dir: outputs/strategy
    feeds_into: cogs-analyzer

  - skill: cogs-analyzer
    required_context: [company.md, product.md]
    output_dir: outputs/analytics
    feeds_into: quarterly-planning-template

  - skill: quarterly-planning-template
    required_context: [product.md, company.md, goals.md]
    output_dir: outputs/strategy
    feeds_into: roadmap-builder
    suggests_update: [goals.md]

  - skill: roadmap-builder
    required_context: [product.md, goals.md]
    output_dir: outputs/strategy
    suggests_update: [product.md]
```

- [ ] **Step 3: Write go-to-market.yaml**

```yaml
name: go-to-market
description: Ensure a new feature or product is positioned and priced to win in the market

steps:
  - skill: swot-analysis-generator
    required_context: [product.md, competitors.md]
    output_dir: outputs/strategy
    feeds_into: positioning-statement-generator

  - skill: positioning-statement-generator
    required_context: [product.md, competitors.md, personas.md]
    output_dir: outputs/strategy
    feeds_into: pricing-strategy-analyzer
    suggests_update: [product.md]

  - skill: pricing-strategy-analyzer
    required_context: [product.md, competitors.md, company.md]
    output_dir: outputs/strategy
    feeds_into: sales-enablement-kit
    suggests_update: [product.md, competitors.md]

  - skill: sales-enablement-kit
    required_context: [product.md, competitors.md, personas.md]
    output_dir: outputs/launch
    feeds_into: weekly-plan

  - skill: weekly-plan
    required_context: [goals.md]
    output_dir: outputs/productivity
    feeds_into: daily-plan

  - skill: daily-plan
    required_context: [goals.md]
    output_dir: outputs/productivity
```

- [ ] **Step 4: Write feedback-loop.yaml**

```yaml
name: feedback-loop
description: Analyze post-launch data and feed learnings back into the system

steps:
  - skill: ab-test-analyzer
    required_context: [product.md]
    output_dir: outputs/analytics
    feeds_into: funnel-analyzer
    suggests_update: [product.md]

  - skill: funnel-analyzer
    required_context: [product.md]
    output_dir: outputs/analytics
    feeds_into: metric-framework-builder
    suggests_update: [product.md]

  - skill: metric-framework-builder
    required_context: [product.md, goals.md]
    output_dir: outputs/analytics
    feeds_into: research-synthesis-engine

  - skill: research-synthesis-engine
    required_context: [product.md, personas.md]
    output_dir: outputs/discovery
    feeds_into: backlog-prioritizer
    suggests_update: [personas.md]

  - skill: backlog-prioritizer
    required_context: [product.md, goals.md]
    output_dir: outputs/strategy
    suggests_update: [product.md, goals.md]
```

- [ ] **Step 5: Commit**

```bash
git add workflows/
git commit -m "feat: add all 5 workflow YAML definitions"
```

---

## Chunk 3: Commands and Hooks

### Task 9: SessionStart hook and session-start script

**Files:**
- Create: `hooks/hooks.json`
- Create: `scripts/session-start.sh`

- [ ] **Step 1: Write hooks.json**

```json
{
  "description": "Manna Ray lifecycle hooks for context and state management",
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/session-start.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2: Write session-start.sh**

```bash
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
```

- [ ] **Step 3: Make script executable**

```bash
chmod +x scripts/session-start.sh
```

- [ ] **Step 4: Write tests for session-start.sh**

Create `tests/test-session-start.sh`:

```bash
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
```

- [ ] **Step 5: Run session-start tests**

Run: `bash tests/test-session-start.sh`
Expected: All PASS

- [ ] **Step 6: Commit**

```bash
git add hooks/hooks.json scripts/session-start.sh tests/test-session-start.sh
git commit -m "feat: add SessionStart hook for project detection"
```

### Task 10: manna-init command

**Files:**
- Create: `commands/manna-init.md`

- [ ] **Step 1: Write manna-init.md**

```markdown
---
description: Scaffold a new Manna Ray product management project
allowed-tools: Read, Write, Edit, Bash(*), Glob
---

You are initializing a new Manna Ray product management project.

## Step 1: Check if already initialized

Check status: !`test -f "${CLAUDE_PROJECT_DIR}/.manna-ray/state.json" && echo "EXISTS" || echo "NEW"`

If the project is already initialized, warn the user and ask if they want to reinitialize (this will reset workflow state but preserve context files and outputs).

## Step 2: Get project name

Ask the user for a short project name (e.g., "acme-saas", "widget-app"). This is used for identification in status displays.

## Step 3: Create directory structure

Create the following directories:
- `.manna-ray/`
- `context/`
- `outputs/discovery/`
- `outputs/strategy/`
- `outputs/specs/`
- `outputs/analytics/`
- `outputs/launch/`
- `outputs/productivity/`
- `research/`

## Step 4: Copy context templates

Copy these template files from the plugin to the project's `context/` directory:
- @${CLAUDE_PLUGIN_ROOT}/templates/context/product.md → context/product.md
- @${CLAUDE_PLUGIN_ROOT}/templates/context/company.md → context/company.md
- @${CLAUDE_PLUGIN_ROOT}/templates/context/personas.md → context/personas.md
- @${CLAUDE_PLUGIN_ROOT}/templates/context/competitors.md → context/competitors.md
- @${CLAUDE_PLUGIN_ROOT}/templates/context/goals.md → context/goals.md

Only copy if the file doesn't already exist (preserve existing context files).

## Step 5: Initialize state

Initialize state: !`bash -c 'source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh && state_init "$1"' -- $ARGUMENTS`

Then update checksums for any existing context files:
!`bash -c 'source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh; for f in product.md company.md personas.md competitors.md goals.md; do state_update_context "$f"; done'`

## Step 6: Generate CLAUDE.md

Copy the project CLAUDE.md template:
@${CLAUDE_PLUGIN_ROOT}/templates/claude-md/project.md

Write this to the project root as `CLAUDE.md`. If a CLAUDE.md already exists, append the Manna Ray section rather than overwriting.

## Step 7: Guide context population

Now guide the user through populating their context files. Start with `context/product.md` — ask them about their product, and help them fill in each section. Move through the files one at a time, but let the user skip any they're not ready to fill.

After each file is populated, update its checksum:
!`bash -c 'source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh && state_update_context "$1"' -- [filename]`

Tell the user: "Project initialized! Use /manna-status to see your project dashboard."
```

- [ ] **Step 2: Commit**

```bash
git add commands/manna-init.md
git commit -m "feat: add /manna-init command"
```

### Task 11: manna-context command

**Files:**
- Create: `commands/manna-context.md`

- [ ] **Step 1: Write manna-context.md**

```markdown
---
description: Manage Manna Ray context files (init, check, update)
argument-hint: [init|check|update] [filename]
allowed-tools: Read, Write, Edit, Bash(*), Glob, Grep
---

You are managing Manna Ray context files. The user's subcommand is: $1

## Subcommand: init

If $1 is "init":
1. Create context/ directory if it doesn't exist
2. Copy template files from plugin (only if they don't already exist):
   - @${CLAUDE_PLUGIN_ROOT}/templates/context/product.md
   - @${CLAUDE_PLUGIN_ROOT}/templates/context/company.md
   - @${CLAUDE_PLUGIN_ROOT}/templates/context/personas.md
   - @${CLAUDE_PLUGIN_ROOT}/templates/context/competitors.md
   - @${CLAUDE_PLUGIN_ROOT}/templates/context/goals.md
3. Initialize state if .manna-ray/state.json doesn't exist:
   !`bash -c 'source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh && [ ! -f "${CLAUDE_PROJECT_DIR}/.manna-ray/state.json" ] && state_init "unnamed" || echo "state exists"'`
4. Update checksums for all context files

## Subcommand: check

If $1 is "check":
Show detailed context file health by running:
!`bash -c '
source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh
source ${CLAUDE_PLUGIN_ROOT}/scripts/context.sh
echo "=== Context File Health ==="
for f in product.md company.md personas.md competitors.md goals.md; do
  exists=$(context_check_exists "$f")
  if [ "$exists" = "missing" ]; then
    echo "  ✗ $f — MISSING"
  elif [ "$exists" = "empty" ]; then
    echo "  ⚠ $f — EMPTY"
  else
    staleness=$(context_check_staleness "$f")
    last=$(jq -r ".context[\"$f\"].lastModified // \"unknown\"" "${CLAUDE_PROJECT_DIR}/.manna-ray/state.json")
    echo "  ✓ $f — $staleness (last updated: $last)"
  fi
done
'`

## Subcommand: update

If $1 is "update" and $2 is a filename:
1. Read the current context file: @${CLAUDE_PROJECT_DIR}/context/$2
2. Ask the user what has changed or what new information they have
3. Draft targeted updates to the file — preserve existing content, add/modify sections as needed
4. Show the proposed changes and ask for approval
5. After approval, write the updated file
6. Update the checksum:
   !`bash -c 'source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh && state_update_context "$1"' -- $2`
7. Confirm: "Updated context/$2. Checksum recorded."

If $1 is "update" but $2 is missing, list the available context files and ask which one to update.

## Subcommand: missing or invalid

If $1 is empty or not recognized, show usage:
- `/manna-context init` — Create context file templates
- `/manna-context check` — Show context file health
- `/manna-context update [file]` — Update a specific context file
```

- [ ] **Step 2: Commit**

```bash
git add commands/manna-context.md
git commit -m "feat: add /manna-context command"
```

### Task 12: manna-run command

**Files:**
- Create: `commands/manna-run.md`

- [ ] **Step 1: Write manna-run.md**

```markdown
---
description: Run a Manna Ray PM skill with context injection
argument-hint: [skill-name] [additional context]
allowed-tools: Read, Write, Edit, Bash(*), Glob, Grep
---

You are executing a Manna Ray PM skill with automatic context injection.

## Step 0: Handle "list" subcommand

If $1 is "list":
!`bash -c '
for dir in ${CLAUDE_PLUGIN_ROOT}/skills/*/; do
  skill=$(basename "$dir")
  mode=$(grep "^mode:" "$dir/SKILL.md" 2>/dev/null | head -1 | sed "s/mode: *//")
  desc=$(grep "^description:" "$dir/SKILL.md" 2>/dev/null | head -1 | sed "s/description: *//")
  echo "  [$mode] $skill"
done | sort
'`

If $2 is also provided (e.g., `/manna-run list discovery`), filter to show only skills matching that mode.

Stop here — do not proceed to skill execution.

## Step 1: Validate skill exists

The user wants to run skill: **$1**

Check if the skill exists:
!`test -d "${CLAUDE_PLUGIN_ROOT}/skills/$1" && echo "FOUND" || echo "NOT_FOUND"`

If NOT_FOUND, list available skills and suggest the closest match:
!`ls "${CLAUDE_PLUGIN_ROOT}/skills/" | sort`

## Step 2: Load skill definition

Load the skill:
@${CLAUDE_PLUGIN_ROOT}/skills/$1/SKILL.md

Extract the frontmatter fields: `required_context`, `output_dir`, `output_prefix`, `suggests_update`, `mode`.

## Step 3: Load project state

!`cat "${CLAUDE_PROJECT_DIR}/.manna-ray/state.json" 2>/dev/null || echo '{"context":{},"workflows":{},"history":[]}'`

## Step 4: Context dependency check

For each file listed in the skill's `required_context` frontmatter, check existence.
<!-- Claude: read the required_context list from the skill's YAML frontmatter, then substitute the actual filenames into this bash call -->
!`bash -c '
source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh
source ${CLAUDE_PLUGIN_ROOT}/scripts/context.sh
context_validate_required $@
' -- product.md personas.md goals.md`

If any required files are missing, inform the user and ask if they want to continue anyway.

## Step 5: Staleness check

For each required context file, check staleness:
!`bash -c '
source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh
source ${CLAUDE_PLUGIN_ROOT}/scripts/context.sh
for f in $@; do
  s=$(context_check_staleness "$f")
  [ "$s" = "stale" ] && echo "⚠ context/$f is stale (>30 days since last update)"
done
' -- [required_context files]`

## Step 6: Context size check

!`bash -c '
source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh
source ${CLAUDE_PLUGIN_ROOT}/scripts/context.sh
context_check_size_warning $@
' -- [required_context files]`

## Step 7: Inject context and execute skill

Read each required context file and present them as context:
For each file in required_context, read: @${CLAUDE_PROJECT_DIR}/context/[filename]

Now execute the skill using its SKILL.md instructions with:
- The loaded context
- The user's additional input: $2

## Step 8: Save output

After the skill produces its output, save it to the appropriate directory.
The output path should follow the pattern: `{output_dir}/{output_prefix}-{slug}-{YYYY-MM-DD}.md`
Ask the user for a short slug describing this analysis, or generate one from the content.

Ensure no file conflicts — if the path already exists, append a numeric suffix.

Update state with the run record:
!`bash -c 'source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh && state_add_run "$1" "$2"' -- [skill-name] [output-path]`

## Step 9: Suggest context updates

If the skill's frontmatter includes `suggests_update`, ask the PM:
"This analysis may have produced new insights relevant to [context files]. Would you like to update any of these context files?"

If yes, use the context-updater agent to draft updates.
```

- [ ] **Step 2: Commit**

```bash
git add commands/manna-run.md
git commit -m "feat: add /manna-run command"
```

### Task 13: manna-workflow command

**Files:**
- Create: `commands/manna-workflow.md`

- [ ] **Step 1: Write manna-workflow.md**

```markdown
---
description: Manage Manna Ray workflows (start, next, skip, cancel, restart, status, list)
argument-hint: [start|next|skip|cancel|restart|status|list] [workflow-name]
allowed-tools: Read, Write, Edit, Bash(*), Glob, Grep
---

You are managing Manna Ray workflows. The subcommand is: $1

## Subcommand: list

If $1 is "list":
!`bash -c '
export CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"
source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh
source ${CLAUDE_PLUGIN_ROOT}/scripts/context.sh
source ${CLAUDE_PLUGIN_ROOT}/scripts/workflow.sh
workflow_list
'`

## Subcommand: start

If $1 is "start" and $2 is a workflow name:

1. Start the workflow:
!`bash -c '
export CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"
source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh
source ${CLAUDE_PLUGIN_ROOT}/scripts/context.sh
source ${CLAUDE_PLUGIN_ROOT}/scripts/workflow.sh
workflow_start "$1"
' -- $2`

2. If successful, display the workflow steps and announce you're starting step 1.
3. Get the first step's skill and context requirements from the workflow YAML:
   @${CLAUDE_PLUGIN_ROOT}/workflows/$2.yaml
4. Execute the first skill using the same process as `/manna-run` (context injection, execution, output saving).

## Subcommand: next

If $1 is "next":

1. Find active workflow:
!`bash -c '
source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh
source ${CLAUDE_PLUGIN_ROOT}/scripts/context.sh
source ${CLAUDE_PLUGIN_ROOT}/scripts/workflow.sh
active=$(state_get_active_workflow)
if [ -z "$active" ]; then
  echo "NO_ACTIVE"
else
  echo "$active"
  step=$(workflow_get_current_step "$active")
  echo "STEP:$step"
  prev=$(workflow_get_previous_output "$active")
  echo "PREV:$prev"
fi
'`

2. If NO_ACTIVE, tell user: "No active workflow. Start one with `/manna-workflow start [name]`."
3. Otherwise, load the current step's skill definition and execute it.
4. If there's a previous step output (PREV), load it as additional context for this step.
5. After skill completes and output is saved, advance the workflow:
   !`bash -c 'source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh && state_workflow_advance "$1" "$2"' -- [workflow-name] [output-path]`
6. Update run history too:
   !`bash -c 'source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh && state_add_run "$1" "$2"' -- [skill-name] [output-path]`

## Subcommand: skip

If $1 is "skip":
1. Find active workflow
2. Skip the current step:
   !`bash -c 'source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh && state_workflow_skip "$1"' -- [workflow-name]`
3. Show what was skipped and what's next.

## Subcommand: cancel

If $1 is "cancel":
1. Find active workflow
2. Cancel it:
   !`bash -c 'source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh && state_workflow_cancel "$1"' -- [workflow-name]`
3. Confirm: "Workflow [name] cancelled. Outputs from completed steps are preserved."

## Subcommand: restart

If $1 is "restart" and $2 is a workflow name:
1. Cancel any active workflow first
2. Then start the specified workflow fresh (same as "start")

## Subcommand: status

If $1 is "status":
!`bash -c '
source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh
active=$(state_get_active_workflow)
if [ -z "$active" ]; then
  echo "No active workflow."
  exit 0
fi
sf="${CLAUDE_PROJECT_DIR}/.manna-ray/state.json"
echo "Workflow: $active"
echo "Status: $(jq -r ".workflows[\"$active\"].status" "$sf")"
echo "Started: $(jq -r ".workflows[\"$active\"].startedAt" "$sf")"
echo ""
echo "Steps:"
jq -r ".workflows[\"$active\"].steps | to_entries[] | \"  \(.key + 1). [\(.value.status)] \(.value.skill)\(if .value.output then \" → \" + .value.output else \"\" end)\"" "$sf"
'`

## Subcommand: missing

If $1 is empty or unrecognized, show usage:
- `/manna-workflow list` — Show available workflows
- `/manna-workflow start [name]` — Begin a workflow
- `/manna-workflow next` — Advance to next step
- `/manna-workflow skip` — Skip current step
- `/manna-workflow cancel` — Cancel active workflow
- `/manna-workflow restart [name]` — Cancel and restart
- `/manna-workflow status` — Show active workflow progress
```

- [ ] **Step 2: Commit**

```bash
git add commands/manna-workflow.md
git commit -m "feat: add /manna-workflow command"
```

### Task 14: manna-status command

**Files:**
- Create: `commands/manna-status.md`

- [ ] **Step 1: Write manna-status.md**

```markdown
---
description: Show Manna Ray project dashboard
allowed-tools: Read, Bash(*)
---

You are showing the Manna Ray project dashboard.

## Load project state

!`bash -c '
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
```

- [ ] **Step 2: Commit**

```bash
git add commands/manna-status.md
git commit -m "feat: add /manna-status command"
```

### Task 15: manna-history command

**Files:**
- Create: `commands/manna-history.md`

- [ ] **Step 1: Write manna-history.md**

```markdown
---
description: Show Manna Ray run history and output files
argument-hint: [skill-name]
allowed-tools: Read, Bash(*)
---

You are showing Manna Ray run history.

## Load history

!`bash -c '
sf="${CLAUDE_PROJECT_DIR}/.manna-ray/state.json"
if [ ! -f "$sf" ]; then
  echo "NOT_INITIALIZED"
  exit 0
fi

if [ -n "$1" ] && [ "$1" != "" ]; then
  echo "=== History for: $1 ==="
  jq -r ".history | map(select(.skill == \"$1\")) | reverse | .[] | \"  \(.ranAt | split(\"T\")[0]) → \(.output)\"" "$sf"
else
  echo "=== Full Run History ==="
  jq -r ".history | reverse | .[] | \"  [\(.ranAt | split(\"T\")[0])] \(.skill) → \(.output)\"" "$sf"
fi

echo ""
echo "=== Available Outputs ==="
for dir in discovery strategy specs analytics launch productivity; do
  files=$(find "${CLAUDE_PROJECT_DIR}/outputs/$dir" -name "*.md" 2>/dev/null | sort -r)
  if [ -n "$files" ]; then
    echo "  outputs/$dir/:"
    echo "$files" | while read -r f; do
      echo "    $(basename "$f")"
    done
  fi
done
' -- "$1"`

If NOT_INITIALIZED, tell the user: "This is not a Manna Ray project. Run `/manna-init` to get started."

Otherwise, present the history in a clean, readable format.
- If the user provided a skill name ($1), filter to show only runs of that skill.
- Also show the output file listing so the user can see what artifacts exist.
```

- [ ] **Step 2: Commit**

```bash
git add commands/manna-history.md
git commit -m "feat: add /manna-history command"
```

---

## Chunk 4: Agent, Skill Frontmatter, and Final Integration

### Task 16: Context updater agent

**Files:**
- Create: `agents/context-updater.md`

- [ ] **Step 1: Write context-updater.md**

```markdown
---
name: context-updater
description: Use this agent when a Manna Ray skill has completed and the user wants to update context files with new insights from the skill output. This agent reads the skill output, identifies new insights about the product, personas, competitors, or goals, and drafts targeted updates to the relevant context file.
tools: Read, Write, Edit, Bash(*)
---

You are the Manna Ray Context Updater agent. Your job is to update a project's context files with new insights from a skill run.

## Instructions

1. You will be given:
   - The skill output file path
   - The context file(s) to update

2. Read the skill output to identify new, actionable insights.

3. Read the current context file to understand what's already documented.

4. Draft targeted updates:
   - ADD new information that wasn't there before
   - UPDATE existing sections with more current data
   - DO NOT remove existing content unless it's clearly outdated and being replaced
   - Preserve the template structure and section headings

5. Show the proposed changes to the user and ask for approval before writing.

6. After writing, update the checksum:
   !`bash -c 'source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh && state_update_context "$1"' -- [filename]`
```

- [ ] **Step 2: Commit**

```bash
git add agents/context-updater.md
git commit -m "feat: add context-updater agent"
```

### Task 17: Extend frontmatter for Workflow C skills

**Files:**
- Modify: `skills/prioritization-engine/SKILL.md`
- Modify: `skills/prd-generator/SKILL.md`
- Modify: `skills/ab-test-designer/SKILL.md`
- Modify: `skills/technical-spec-writer/SKILL.md`
- Modify: `skills/user-story-writer/SKILL.md`
- Modify: `skills/launch-checklist-generator/SKILL.md`

For each skill, add the following new frontmatter fields (preserving all existing fields). The exact fields per skill are:

- [ ] **Step 1: Verify each skill has YAML frontmatter delimited by `---`**

Run: `for s in prioritization-engine prd-generator ab-test-designer technical-spec-writer user-story-writer launch-checklist-generator; do head -1 "skills/$s/SKILL.md"; done`
Expected: Each file starts with `---`. If any skill lacks frontmatter, add the `---` delimiters before proceeding.

- [ ] **Step 2: Add extended frontmatter to prioritization-engine**

Add these fields to the existing frontmatter (do not remove existing fields):
```yaml
mode: priority
required_context:
  - product.md
  - goals.md
output_dir: outputs/strategy
output_prefix: prioritization
suggests_update: []
```

- [ ] **Step 3: Add extended frontmatter to prd-generator**

```yaml
mode: specs
required_context:
  - product.md
  - personas.md
  - goals.md
output_dir: outputs/specs
output_prefix: prd
suggests_update:
  - product.md
```

- [ ] **Step 4: Add extended frontmatter to ab-test-designer**

```yaml
mode: data
required_context:
  - product.md
output_dir: outputs/analytics
output_prefix: ab-test-design
suggests_update: []
```

- [ ] **Step 5: Add extended frontmatter to technical-spec-writer**

```yaml
mode: specs
required_context:
  - product.md
output_dir: outputs/specs
output_prefix: tech-spec
suggests_update: []
```

- [ ] **Step 6: Add extended frontmatter to user-story-writer**

```yaml
mode: specs
required_context:
  - personas.md
output_dir: outputs/specs
output_prefix: user-stories
suggests_update: []
```

- [ ] **Step 7: Add extended frontmatter to launch-checklist-generator**

```yaml
mode: specs
required_context:
  - product.md
output_dir: outputs/launch
output_prefix: launch-checklist
suggests_update: []
```

- [ ] **Step 8: Commit**

```bash
git add skills/prioritization-engine/SKILL.md \
      skills/prd-generator/SKILL.md \
      skills/ab-test-designer/SKILL.md \
      skills/technical-spec-writer/SKILL.md \
      skills/user-story-writer/SKILL.md \
      skills/launch-checklist-generator/SKILL.md
git commit -m "feat: add extended frontmatter to Workflow C skills"
```

### Task 18: Run all tests and verify

- [ ] **Step 1: Run state tests**

Run: `bash tests/test-state.sh`
Expected: All PASS

- [ ] **Step 2: Run context tests**

Run: `bash tests/test-context.sh`
Expected: All PASS

- [ ] **Step 3: Run workflow tests**

Run: `bash tests/test-workflow.sh`
Expected: All PASS

- [ ] **Step 4: Verify plugin structure**

```bash
# Verify all expected files exist
ls .claude-plugin/plugin.json
ls commands/manna-init.md commands/manna-context.md commands/manna-run.md \
   commands/manna-workflow.md commands/manna-status.md commands/manna-history.md
ls agents/context-updater.md
ls hooks/hooks.json
ls scripts/state.sh scripts/context.sh scripts/workflow.sh scripts/session-start.sh
ls workflows/idea-to-sprint.yaml workflows/zero-to-one.yaml \
   workflows/quarterly-planning.yaml workflows/go-to-market.yaml \
   workflows/feedback-loop.yaml
ls templates/context/product.md templates/context/company.md \
   templates/context/personas.md templates/context/competitors.md \
   templates/context/goals.md
ls templates/claude-md/project.md
```

Expected: All files exist, no errors.

- [ ] **Step 5: Validate plugin.json**

```bash
jq empty .claude-plugin/plugin.json && echo "Valid JSON"
```

Expected: `Valid JSON`

- [ ] **Step 6: Validate hooks.json**

```bash
jq empty hooks/hooks.json && echo "Valid JSON"
```

Expected: `Valid JSON`

- [ ] **Step 7: Validate workflow YAML files**

```bash
for f in workflows/*.yaml; do yq empty "$f" && echo "Valid: $f"; done
```

Expected: All valid.

- [ ] **Step 8: Final commit**

```bash
git add -A
git commit -m "feat: complete Manna Ray plugin v0.1.0 — initial build"
```
