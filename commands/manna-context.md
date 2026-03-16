---
description: Manage Manna Ray context files (init, check, update)
argument-hint: [init|check|update] [filename]
allowed-tools: Read, Write, Edit, Bash(*), Glob, Grep
---

You are managing Manna Ray context files. The user's subcommand is: $1
The user's second argument (if any) is: $2

Based on $1, follow ONLY the matching subcommand section below.

## Subcommand: init

If $1 is "init":
1. Create context/ directory if it doesn't exist
2. Copy template files from plugin (only if they don't already exist):
   - @${CLAUDE_PLUGIN_ROOT}/templates/context/product.md
   - @${CLAUDE_PLUGIN_ROOT}/templates/context/company.md
   - @${CLAUDE_PLUGIN_ROOT}/templates/context/personas.md
   - @${CLAUDE_PLUGIN_ROOT}/templates/context/competitors.md
   - @${CLAUDE_PLUGIN_ROOT}/templates/context/goals.md
3. Initialize state if .manna-ray/state.json doesn't exist by running:
   ```bash
   export CLAUDE_PROJECT_DIR="$(pwd)"; source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh && [ ! -f ".manna-ray/state.json" ] && state_init "unnamed" || echo "state exists"
   ```
4. Update checksums for all context files

## Subcommand: check

If $1 is "check", run this bash command:
```bash
export CLAUDE_PROJECT_DIR="$(pwd)"
source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh
source ${CLAUDE_PLUGIN_ROOT}/scripts/context.sh
echo "=== Context File Health ==="
for f in product.md company.md personas.md competitors.md goals.md; do
  exists=$(context_check_exists "$f")
  if [ "$exists" = "missing" ]; then
    echo "  X $f — MISSING"
  elif [ "$exists" = "empty" ]; then
    echo "  ! $f — EMPTY"
  else
    staleness=$(context_check_staleness "$f")
    last=$(jq -r ".context[\"$f\"].lastModified // \"unknown\"" ".manna-ray/state.json")
    echo "  OK $f — $staleness (last updated: $last)"
  fi
done
```

## Subcommand: update

If $1 is "update" and $2 is a filename:
1. Read the current context file at `context/$2` in the project directory
2. Ask the user what has changed or what new information they have
3. Draft targeted updates to the file — preserve existing content, add/modify sections as needed
4. Show the proposed changes and ask for approval
5. After approval, write the updated file
6. Update the checksum by running:
   ```bash
   export CLAUDE_PROJECT_DIR="$(pwd)"; source ${CLAUDE_PLUGIN_ROOT}/scripts/state.sh && state_update_context "FILENAME"
   ```
   Replace FILENAME with the actual context filename (e.g., "product.md").
7. Confirm: "Updated context/$2. Checksum recorded."

If $1 is "update" but $2 is missing, list the available context files and ask which one to update.

## Subcommand: missing or invalid

If $1 is empty or not recognized, show usage:
- `/manna-context init` — Create context file templates
- `/manna-context check` — Show context file health
- `/manna-context update [file]` — Update a specific context file
