---
description: Run a Manna Ray PM skill with context injection
argument-hint: [skill-name] [additional context]
allowed-tools: Read, Write, Edit, Bash(*), Glob, Grep
---

You are executing a Manna Ray PM skill with automatic context injection.

The user's first argument (skill name or "list") is: $1
The user's additional context is: $2

Based on $1, follow the appropriate flow below. Do NOT run bash blocks from unrelated sections.

## Step 0: Handle "list" subcommand

If $1 is "list", run this bash command:
```bash
for dir in ${CLAUDE_PLUGIN_ROOT}/skills/*/; do
  skill=$(basename "$dir")
  mode=$(grep "^  mode:" "$dir/SKILL.md" "$dir/SKILL.MD" 2>/dev/null | head -1 | sed "s/.*mode: *//")
  echo "  [$mode] $skill"
done | sort
```

If $2 is also provided (e.g., `/manna-run list discovery`), filter to show only skills matching that mode.

Stop here — do not proceed to skill execution.

## Step 1: Validate skill exists

The user wants to run skill: **$1**

Check if the skill exists by running:
```bash
test -d "${CLAUDE_PLUGIN_ROOT}/skills/$1" && echo "FOUND" || echo "NOT_FOUND"
```

If NOT_FOUND, run this to list available skills and suggest the closest match:
```bash
ls "${CLAUDE_PLUGIN_ROOT}/skills/" | sort
```

## Step 2: Load skill definition

Load the skill:
@${CLAUDE_PLUGIN_ROOT}/skills/$1/SKILL.md

If that file doesn't exist, try:
@${CLAUDE_PLUGIN_ROOT}/skills/$1/SKILL.MD

Extract the frontmatter fields from the `metadata:` block: `mode`, `required_context`, `output_dir`, `output_prefix`, `suggests_update`.

## Step 3: Load project state

Run this to get project state:
```bash
cat ".manna-ray/state.json" 2>/dev/null || echo '{"context":{},"workflows":{},"history":[]}'
```

## Step 4: Context dependency check

For each file listed in the skill's `metadata.required_context` frontmatter, check existence by running:
```bash
export CLAUDE_PROJECT_DIR="$(pwd)"
source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh
source ${CLAUDE_PLUGIN_ROOT}/scripts/context.sh
context_validate_required REQUIRED_FILES
```
Replace REQUIRED_FILES with the space-separated list of files from the skill's `required_context` metadata.

If any required files are missing, inform the user and ask if they want to continue anyway.

## Step 5: Staleness check

For each required context file, check staleness by running:
```bash
export CLAUDE_PROJECT_DIR="$(pwd)"
source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh
source ${CLAUDE_PLUGIN_ROOT}/scripts/context.sh
for f in REQUIRED_FILES; do
  s=$(context_check_staleness "$f")
  [ "$s" = "stale" ] && echo "WARNING: context/$f is stale (>30 days since last update)"
done
```
Replace REQUIRED_FILES with the actual required context file list from the skill's metadata.

## Step 6: Context size check

```bash
export CLAUDE_PROJECT_DIR="$(pwd)"
source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh
source ${CLAUDE_PLUGIN_ROOT}/scripts/context.sh
context_check_size_warning REQUIRED_FILES
```
Replace REQUIRED_FILES with the actual required context file list.

## Step 7: Inject context and execute skill

Read each required context file from the project's `context/` directory and present them as context.

Now execute the skill using its SKILL.md instructions with:
- The loaded context
- The user's additional input: $2

## Step 8: Save output

After the skill produces its output, save it to the appropriate directory.
The output path should follow the pattern: `{output_dir}/{output_prefix}-{slug}-{YYYY-MM-DD}.md`
Ask the user for a short slug describing this analysis, or generate one from the content.

Ensure no file conflicts — if the path already exists, append a numeric suffix.

Update state with the run record by running:
```bash
export CLAUDE_PROJECT_DIR="$(pwd)"; source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh && state_add_run "SKILL_NAME" "OUTPUT_PATH"
```
Replace SKILL_NAME with the skill that was executed and OUTPUT_PATH with the saved output file path.

## Step 9: Suggest context updates

If the skill's frontmatter includes `suggests_update`, ask the PM:
"This analysis may have produced new insights relevant to [context files]. Would you like to update any of these context files?"

If yes, use the context-updater agent to draft updates.
