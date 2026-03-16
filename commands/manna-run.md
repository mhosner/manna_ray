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
