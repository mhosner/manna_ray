# Manna Ray — Development Guidelines

## Project Overview

Manna Ray is a Claude Code plugin that serves as a Product Management Operating System. It orchestrates 31 PM skills across 5 workflows, managing context files, workflow state, and skill chaining.

## Architecture

This is a **Claude Code plugin** — not a compiled application. All components are markdown, bash, JSON, or YAML:

- `commands/*.md` — Slash commands (auto-discovered by Claude Code)
- `skills/*/SKILL.md` — PM skills (auto-discovered by Claude Code)
- `agents/*.md` — Subagent definitions
- `hooks/hooks.json` — Event-driven automation
- `scripts/*.sh` — Bash helper scripts for state, context, and workflow management
- `workflows/*.yaml` — Workflow pipeline definitions
- `templates/context/*.md` — Scaffolding templates for PM projects
- `.claude-plugin/plugin.json` — Plugin manifest

## Key Conventions

### Commands
- Commands are markdown files that instruct Claude what to do
- All commands prefixed with `manna-` to avoid namespace conflicts
- Use `${CLAUDE_PLUGIN_ROOT}` for all paths to plugin files
- Use `${CLAUDE_PROJECT_DIR}` for all paths to the PM's project files
- Use `@path` syntax for file references, `!`backtick` for bash execution
- Commands must validate inputs and handle missing files gracefully

### Skills
- Skills are prompt-driven `.md` files — the PM methodology lives here
- Each skill has YAML frontmatter with: `name`, `description`, and custom fields under `metadata:` (`mode`, `required_context`, `output_dir`, `output_prefix`, `suggests_update`)
- Custom fields MUST go under `metadata:` — Claude Code only supports `name`, `description`, `argument-hint`, `compatibility`, `disable-model-invocation`, `license`, `metadata`, `user-invocable` as top-level frontmatter attributes
- Skills should NOT be modified for orchestration logic — keep them focused on PM methodology
- The orchestration layer (commands/scripts) handles context injection and state tracking

### Scripts
- All scripts in `scripts/` are bash
- Scripts handle deterministic operations: state CRUD, checksum calculation, file existence checks, YAML parsing
- Scripts output JSON or structured text that commands can consume
- Use `jq` for JSON manipulation in scripts
- Always `set -euo pipefail` at the top of scripts
- Quote all variables to prevent injection

### State Management
- State lives in `${CLAUDE_PROJECT_DIR}/.manna-ray/state.json`
- State tracks: context health (checksums), active workflows, run history
- All state mutations go through `scripts/state.sh`
- Never read/write state.json directly from commands — use the script functions

### Workflows
- Defined as YAML in `workflows/`
- Each workflow declares: name, description, prerequisite_outputs, steps
- Steps declare: skill, required_context, output_dir, feeds_into, suggests_update
- Workflows are guides, not cages — PMs can skip steps or run skills ad-hoc

### Context Files
- Five canonical files: `product.md`, `company.md`, `personas.md`, `competitors.md`, `goals.md`
- Templates in `templates/context/` provide the scaffolding structure
- Staleness threshold: 30 days since last checksum change
- Always suggest, never force context updates

## Testing

- Test scripts with sample JSON inputs piped via stdin
- Test commands by running them in Claude Code with `--debug` flag
- Validate hooks.json structure before committing
- Test workflow YAML parsing against edge cases (missing prereqs, empty steps)

## File Naming

- Commands: `manna-{action}.md` (kebab-case)
- Skills: `{skill-name}/SKILL.md` (kebab-case directory)
- Scripts: `{purpose}.sh` (kebab-case)
- Workflows: `{workflow-name}.yaml` (kebab-case)
- Outputs: `{prefix}-{topic}-{YYYY-MM-DD}.md`

## Design Principles

1. **Native plugin model** — No compilation. Markdown + bash + JSON + YAML.
2. **Skills stay as prompts** — Plugin handles plumbing; Claude handles reasoning.
3. **Declare, don't discover** — Dependencies declared in frontmatter.
4. **Suggest, don't force** — Warnings and prompts are skippable.
5. **Portable paths** — `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_PROJECT_DIR}` everywhere.
6. **Incremental population** — Context files grow organically over time.
