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
