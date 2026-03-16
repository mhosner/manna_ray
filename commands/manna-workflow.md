---
description: Manage Manna Ray workflows (start, next, skip, cancel, restart, status, list)
argument-hint: [start|next|skip|cancel|restart|status|list] [workflow-name]
allowed-tools: Read, Write, Edit, Bash(*), Glob, Grep
---

You are managing Manna Ray workflows. The subcommand is: $1

## Subcommand: list

If $1 is "list":
!`bash -c '
export CLAUDE_PROJECT_DIR="$(pwd)"
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
export CLAUDE_PROJECT_DIR="$(pwd)"
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
export CLAUDE_PROJECT_DIR="$(pwd)"
export CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"
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
   !`bash -c 'export CLAUDE_PROJECT_DIR="$(pwd)"; export CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"; source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh && state_workflow_advance "$1" "$2"' -- [workflow-name] [output-path]`
6. Update run history too:
   !`bash -c 'export CLAUDE_PROJECT_DIR="$(pwd)"; export CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"; source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh && state_add_run "$1" "$2"' -- [skill-name] [output-path]`

## Subcommand: skip

If $1 is "skip":
1. Find active workflow
2. Skip the current step:
   !`bash -c 'export CLAUDE_PROJECT_DIR="$(pwd)"; export CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"; source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh && state_workflow_skip "$1"' -- [workflow-name]`
3. Show what was skipped and what's next.

## Subcommand: cancel

If $1 is "cancel":
1. Find active workflow
2. Cancel it:
   !`bash -c 'export CLAUDE_PROJECT_DIR="$(pwd)"; export CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"; source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh && state_workflow_cancel "$1"' -- [workflow-name]`
3. Confirm: "Workflow [name] cancelled. Outputs from completed steps are preserved."

## Subcommand: restart

If $1 is "restart" and $2 is a workflow name:
1. Cancel any active workflow first
2. Then start the specified workflow fresh (same as "start")

## Subcommand: status

If $1 is "status":
!`bash -c '
export CLAUDE_PROJECT_DIR="$(pwd)"
export CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"
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
