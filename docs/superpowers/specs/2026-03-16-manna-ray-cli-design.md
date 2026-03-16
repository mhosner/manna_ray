# Manna Ray — Product Management OS: CLI Plugin Design Spec

**Date:** 2026-03-16
**Status:** Draft
**Scope:** Architecture and design for Manna Ray as a Claude Code plugin that orchestrates PM skills, context management, workflow chaining, and project state tracking.

---

## 1. Problem Statement

Manna Ray is a collection of 31 PM skills covering the full product lifecycle: discovery, strategy, planning, prioritization, feature specs, data analysis, and productivity. Four integrated workflows chain these skills into multi-step pipelines.

Today, these skills have three critical gaps:

1. **Context management** — Each skill reads from shared context files (`product.md`, `personas.md`, etc.), but there's no tooling to initialize, validate, or maintain them. The PM must manually keep them current.
2. **Workflow chaining** — Workflows describe multi-skill pipelines, but the PM must manually invoke each skill in sequence and pass outputs forward.
3. **Project state & history** — There's no way to see what has been run, what outputs exist, or where you are in a workflow.

Additionally, 7 skills are not woven into any workflow, and the workflows themselves are linear with no feedback loop from post-launch analysis back into discovery.

## 2. Solution

Manna Ray is a **Claude Code plugin** that provides orchestration on top of the existing skills. It does not replace Claude Code — it enriches the PM's Claude Code session with:

- A **Context Manager** that scaffolds, loads, validates, and tracks staleness of context files
- A **Pipeline Runner** that sequences skills into workflows with dependency validation
- A **State Store** that tracks active workflows, run history, and output locations
- A **Command set** providing `/manna` slash commands for orchestration
- **Hooks** for lifecycle automation (context loading, state tracking)

The skills themselves remain prompt-driven `.md` files. The plugin handles plumbing; Claude handles reasoning.

## 3. Architecture

### 3.1 Plugin Model

Claude Code plugins are **markdown + JSON + bash**, not compiled applications. Components are auto-discovered:

- **Commands** — `.md` files in `commands/`, each becomes a slash command
- **Skills** — `SKILL.md` files in `skills/` subdirectories, auto-activated by context
- **Agents** — `.md` files in `agents/`, subagent definitions
- **Hooks** — `hooks/hooks.json`, event-driven automation scripts
- **Manifest** — `.claude-plugin/plugin.json`, plugin metadata

**Plugin manifest (`.claude-plugin/plugin.json`):**

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

Commands are instructions FOR Claude written as markdown with optional YAML frontmatter. They can reference files with `@path`, execute bash with `!`backtick` syntax, and use `${CLAUDE_PLUGIN_ROOT}` for portable paths. Arguments are accessed via `$1`, `$2`, etc. (positional) or `$ARGUMENTS` (full string).

### 3.2 High-Level Components

```
┌─────────────────────────────────────────────────────────┐
│                    Claude Code Session                   │
│                                                         │
│  User types: /manna-init                                │
│              /manna-workflow start idea-to-sprint              │
│              /manna-status                               │
│              /manna-prd-generator                        │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                   Manna Ray Plugin                       │
│                                                         │
│  commands/           hooks/              scripts/        │
│  ├─ manna-init.md    hooks.json          ├─ state.sh    │
│  ├─ manna-status.md  ├─ SessionStart     ├─ context.sh  │
│  ├─ manna-workflow.md│   (load context)  └─ workflow.sh │
│  ├─ manna-context.md │                                  │
│  ├─ manna-history.md │                                  │
│  └─ manna-run.md     │                                  │
│                      │                                  │
│  skills/             agents/             workflows/     │
│  ├─ prd-generator/   └─ context-         ├─ idea-to-   │
│  ├─ roadmap-builder/   updater.md          sprint.yaml │
│  └─ (31 total)                           └─ (5 total)  │
│                                                         │
│  templates/                                             │
│  └─ context/          .claude-plugin/                   │
│     ├─ product.md     └─ plugin.json                    │
│     └─ (5 total)                                        │
├─────────────────────────────────────────────────────────┤
│  PM's project: context/  outputs/  research/            │
│                .manna-ray/state.json                    │
└─────────────────────────────────────────────────────────┘
```

### 3.3 Command Design

Each command is a markdown file in `commands/` that instructs Claude what to do. Claude Code auto-discovers them as `/command-name` slash commands.

**Naming:** Since plugin commands are flat (subdirectories create namespaces, not subcommands), we use `manna-` prefix for all commands:

| Command | File | Description |
|---------|------|-------------|
| `/manna-init` | `manna-init.md` | Scaffold a new PM project |
| `/manna-context` | `manna-context.md` | Context file operations (init, check, update) |
| `/manna-run` | `manna-run.md` | Run a skill with context injection |
| `/manna-workflow` | `manna-workflow.md` | Workflow operations (start, next, skip, cancel, restart, status, list) |
| `/manna-status` | `manna-status.md` | Broad dashboard: context health + workflow summary + last 5 runs |
| `/manna-history` | `manna-history.md` | Run history and output listing |

**Command structure example (`manna-run.md`):**

```markdown
---
description: Run a Manna Ray PM skill with context injection
argument-hint: [skill-name] [additional context]
allowed-tools: Read, Write, Edit, Bash(*), Glob, Grep
---

You are executing a Manna Ray PM skill.

## Step 1: Load State
State file: !`cat ${CLAUDE_PROJECT_DIR}/.manna-ray/state.json 2>/dev/null || echo '{}'`

## Step 2: Identify Skill
The user wants to run skill: $1
Available skills: !`ls ${CLAUDE_PLUGIN_ROOT}/skills/`

Load the skill definition:
@${CLAUDE_PLUGIN_ROOT}/skills/$1/SKILL.md

## Step 3: Context Injection
Check required_context from the skill's frontmatter.
For each required context file, read from ${CLAUDE_PROJECT_DIR}/context/

## Step 4: Staleness Check
Compare context file timestamps against state.json checksums.
Warn if any required context file is >30 days old.

## Step 5: Execute Skill
Run the skill with the loaded context and user's additional input: $2

## Step 6: Save Output
Save the output to the appropriate outputs/ subdirectory.
Update .manna-ray/state.json with the run record.

## Step 7: Suggest Context Updates
If the skill's frontmatter includes suggests_update, ask the PM
if they want to update those context files with new insights.
```

### 3.4 Hooks

Hooks provide lifecycle automation without manual command invocation.

**`hooks/hooks.json`:**

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

**`scripts/session-start.sh`** — On session start:
- Detects if current directory is a Manna Ray project (has `.manna-ray/` directory)
- If so, reads state.json and outputs a system message summarizing:
  - Context file health (current/stale/missing)
  - Active workflow status (if any)
  - Last 3 skill runs
- This gives the PM immediate awareness when starting a session

### 3.5 Context Manager

Implemented across commands and scripts. No compiled code needed.

**`/manna-init`** is the full project setup (superset):
- Scaffolds `context/` directory with template files from `${CLAUDE_PLUGIN_ROOT}/templates/context/`
- Creates `.manna-ray/state.json` with initial checksums
- Creates output directories (`outputs/discovery/`, `outputs/strategy/`, `outputs/specs/`, `outputs/analytics/`, `outputs/launch/`, `outputs/productivity/`)
- Creates `research/` directory
- Generates a project CLAUDE.md from template
- Claude guides the PM through populating context files interactively

**`/manna-context`** subcommands (callable independently, without `/manna-init`):
- **`/manna-context init`** — Creates only the `context/` directory and template files. Useful if the PM already has a project structure but needs context files.
- **`/manna-context check`** — Shows context file health in detail: which files exist, their staleness, last modified date, checksum status. More detailed than `/manna-status` which shows a summary dashboard.
- **`/manna-context update [file]`** — Opens a guided session to update a specific context file. Claude reads the current file, asks what's changed, and drafts updates for PM approval. Updates the checksum in state.json.

**Before each skill runs (in `/manna-run`):**

1. **Dependency check** — Skill's `required_context` frontmatter lists needed files. Script checks existence and non-emptiness.
2. **Staleness check** — `scripts/context.sh` computes the current file's checksum and compares it to the stored checksum in state.json. If they differ (file was edited outside Manna Ray), the stored checksum and `lastModified` are updated silently — the file is considered refreshed. Staleness is then determined by whether `lastModified` is >30 days ago.
3. **Context injection** — Command reads required context files and prepends them to the skill prompt.

**After skill completes:**
- Skill's `suggests_update` frontmatter triggers a prompt to update context files
- Claude drafts the update, PM approves
- `scripts/state.sh` records new checksum

### 3.6 Pipeline Runner

Implemented in `/manna-workflow` command + `scripts/workflow.sh`.

**Workflow execution model:**

1. `/manna-workflow start idea-to-sprint` — `scripts/workflow.sh` reads workflow YAML, checks prerequisite outputs exist, initializes workflow state in state.json
2. Command displays the workflow steps and starts step 1 by invoking the skill with context injection + any prior step output
3. After each skill completes, the PM can:
   - `/manna-workflow next` — advance (loads previous output as input)
   - `/manna-workflow skip` — skip current step
   - Do something else and return later
4. Workflows persist across Claude Code sessions via state.json

**`scripts/workflow.sh`** handles:
- Reading workflow YAML definitions (uses `yq` — required dependency for YAML parsing; install via `brew install yq` or `snap install yq`)
- Checking prerequisite outputs (glob matching)
- Advancing workflow state
- Resolving previous step's output path for `feeds_into` chaining

**`/manna-workflow status`** shows detailed step-by-step progress for the active workflow: each step's skill name, completion status, and output file path. This is deeper than `/manna-status` which shows a one-line workflow summary alongside context health and recent runs.

**`required_context` in workflow YAML vs skill frontmatter:** The workflow YAML `required_context` is the authoritative source during workflow execution. It may be a subset of the skill's own `required_context` if the workflow provides equivalent data through `feeds_into`. For ad-hoc `/manna-run` execution, the skill's frontmatter `required_context` is used. There is no merge — whichever is applicable for the execution mode takes precedence.

### 3.7 State Store

A JSON file at `${CLAUDE_PROJECT_DIR}/.manna-ray/state.json`. Managed by `scripts/state.sh`.

```json
{
  "project": "acme-saas",
  "initialized": "2026-03-16T10:00:00Z",
  "context": {
    "product.md":     { "checksum": "a1b2c3", "lastModified": "2026-03-14", "status": "current" },
    "personas.md":    { "checksum": "d4e5f6", "lastModified": "2026-02-01", "status": "stale" },
    "competitors.md": { "checksum": null,      "lastModified": null,         "status": "missing" },
    "company.md":     { "checksum": "g7h8i9", "lastModified": "2026-03-10", "status": "current" },
    "goals.md":       { "checksum": "j0k1l2", "lastModified": "2026-03-01", "status": "current" }
  },
  "workflows": {
    "idea-to-sprint": {
      "status": "in_progress",
      "startedAt": "2026-03-16T10:30:00Z",
      "currentStep": 2,
      "steps": [
        { "skill": "prioritization-engine", "status": "completed", "output": "outputs/strategy/prioritization-2026-03-16.md" },
        { "skill": "prd-generator",         "status": "completed", "output": "outputs/specs/prd-widget-redesign-2026-03-16.md" },
        { "skill": "ab-test-designer",      "status": "pending",   "output": null },
        { "skill": "technical-spec-writer",  "status": "pending",   "output": null },
        { "skill": "user-story-writer",      "status": "pending",   "output": null },
        { "skill": "launch-checklist-generator", "status": "pending", "output": null }
      ]
    }
  },
  "history": [
    { "skill": "prioritization-engine", "ranAt": "2026-03-16T10:30:00Z", "output": "outputs/strategy/prioritization-2026-03-16.md" },
    { "skill": "prd-generator",         "ranAt": "2026-03-16T11:15:00Z", "output": "outputs/specs/prd-widget-redesign-2026-03-16.md" }
  ]
}
```

**`scripts/state.sh`** provides functions for:
- `state_read` — read state.json
- `state_update_context` — update context file checksums
- `state_add_run` — append to run history
- `state_workflow_advance` — move to next workflow step
- `state_workflow_init` — initialize a new workflow

`currentStep` is the 0-based index of the next step to execute. Steps at indices below `currentStep` should have status `completed` or `skipped`.

### 3.8 Agents

**`agents/context-updater.md`** — A subagent that specializes in updating context files with new insights from skill outputs. Invoked by commands when the PM agrees to update context after a skill run. Reads the skill output, identifies new insights, and drafts targeted updates to the relevant context file.

### 3.9 Skill Integration

The existing 31 skills in `skills/` are auto-discovered by Claude Code as plugin skills. They activate based on their `description` field in frontmatter.

**Key change:** Skills need extended frontmatter fields for the orchestrator:

```yaml
---
name: prd-generator
description: This skill should be used when structuring messy ideas into PRDs...
mode: specs
required_context:
  - product.md
  - personas.md
  - goals.md
output_dir: outputs/specs
output_prefix: prd
suggests_update:
  - product.md
---
```

New fields (additive to existing):
- `mode` — module category for grouping (discovery, strategy, plan, priority, specs, data, productivity)
- `required_context` — context files needed before execution
- `output_dir` — where outputs are saved
- `output_prefix` — prefix for output filenames
- `suggests_update` — context files that may benefit from updates after this skill runs

## 4. Workflows

### 4.1 Workflow A: Zero-to-One Discovery

**Goal:** Take a vague market opportunity and turn it into a validated, testable solution.

```
user-interview-analyzer → research-synthesis-engine → jtbd-extractor → user-journey-mapper → opportunity-solution-tree
```

### 4.2 Workflow B: Quarterly Strategic Planning

**Goal:** Align the company on what to build next quarter based on market realities and business constraints.

```
north-star-finder ──────────────────────────────────┐
landscape-mapper → competitive-profile-builder      ├→ quarterly-planning-template → roadmap-builder
tech-debt-evaluator + cogs-analyzer ────────────────┘
```

### 4.3 Workflow C: Idea-to-Sprint Execution (Build First)

**Goal:** Take an approved roadmap initiative and break it down into engineering-ready tasks.

```
prioritization-engine → prd-generator → ab-test-designer → technical-spec-writer → user-story-writer → launch-checklist-generator
```

**Prerequisite:** A roadmap output must exist (`outputs/strategy/roadmap-*.md`).

### 4.4 Workflow D: Go-to-Market & Commercialization

**Goal:** Ensure a new feature or product is positioned and priced to win in the market.

```
swot-analysis-generator → positioning-statement-generator → pricing-strategy-analyzer → sales-enablement-kit → weekly-plan + daily-plan
```

### 4.5 Workflow E: Post-Launch Feedback Loop (New)

**Goal:** Analyze post-launch data and feed learnings back into the system.

```
ab-test-analyzer → funnel-analyzer → metric-framework-builder → research-synthesis-engine → backlog-prioritizer
```

**Feeds back into:**
- Workflow A (new discovery from data)
- Workflow C (next sprint's priorities)
- Context files (update with learnings)

This closes the linear pipeline into a continuous product cycle.

### 4.6 Standalone Skills (Not Workflow-Bound)

These skills are invocable ad-hoc via `/manna-run [skill-name]`:

| Skill | Use case |
|-------|----------|
| `meeting-notes-processor` | After any meeting |
| `stakeholder-simulator` | Before finalizing any PRD or proposal |
| `executive-update-generator` | Periodic reporting |
| `daily-plan` | Daily planning (also in Workflow D) |
| `weekly-plan` | Weekly planning (also in Workflow D) |

### 4.7 Complete Skills-to-Workflow Mapping

| Skill | Mode | Workflow(s) | Standalone |
|-------|------|-------------|------------|
| `user-interview-analyzer` | discovery | A | yes |
| `research-synthesis-engine` | discovery | A, E | yes |
| `jtbd-extractor` | discovery | A | yes |
| `user-journey-mapper` | discovery | A | yes |
| `opportunity-solution-tree` | discovery | A | yes |
| `north-star-finder` | plan | B | yes |
| `landscape-mapper` | strategy | B | yes |
| `competitive-profile-builder` | strategy | B | yes |
| `tech-debt-evaluator` | plan | B | yes |
| `cogs-analyzer` | plan | B | yes |
| `quarterly-planning-template` | plan | B | yes |
| `roadmap-builder` | plan | B | yes |
| `prioritization-engine` | priority | C | yes |
| `prd-generator` | specs | C | yes |
| `ab-test-designer` | data | C | yes |
| `technical-spec-writer` | specs | C | yes |
| `user-story-writer` | specs | C | yes |
| `launch-checklist-generator` | specs | C | yes |
| `swot-analysis-generator` | strategy | D | yes |
| `positioning-statement-generator` | strategy | D | yes |
| `pricing-strategy-analyzer` | strategy | D | yes |
| `sales-enablement-kit` | strategy | D | yes |
| `ab-test-analyzer` | data | E | yes |
| `funnel-analyzer` | data | E | yes |
| `metric-framework-builder` | data | E | yes |
| `backlog-prioritizer` | priority | E | yes |
| `weekly-plan` | productivity | D | yes |
| `daily-plan` | productivity | D | yes |
| `meeting-notes-processor` | productivity | — | yes |
| `stakeholder-simulator` | productivity | — | yes |
| `executive-update-generator` | productivity | — | yes |

**Valid `mode` values:** `discovery`, `strategy`, `plan`, `priority`, `specs`, `data`, `productivity`. These map to the seven modules described in the system_workflows document and are used for grouping in `/manna-status` and `/manna-run list [mode]`.

All 31 skills are runnable standalone via `/manna-run [skill-name]` regardless of workflow membership.

## 5. Workflow Definition Format

Workflows are defined as YAML files in `workflows/`:

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

## 6. Plugin Source Structure

```
manna-ray/
├─ .claude-plugin/
│  └─ plugin.json                  ← plugin manifest (name, version, metadata)
│
├─ commands/                       ← slash commands (auto-discovered as /command-name)
│  ├─ manna-init.md               ← /manna-init — scaffold a new PM project
│  ├─ manna-context.md            ← /manna-context — context file operations
│  ├─ manna-run.md                ← /manna-run [skill] — run a skill with context
│  ├─ manna-workflow.md           ← /manna-workflow — workflow operations
│  ├─ manna-status.md             ← /manna-status — project dashboard
│  └─ manna-history.md            ← /manna-history — run history & outputs
│
├─ skills/                         ← PM skills (auto-discovered, 31 existing)
│  ├─ prd-generator/
│  │  └─ SKILL.md
│  ├─ roadmap-builder/
│  │  └─ SKILL.md
│  └─ ...
│
├─ agents/                         ← subagent definitions
│  └─ context-updater.md           ← updates context files with skill insights
│
├─ hooks/                          ← event-driven automation
│  └─ hooks.json                   ← SessionStart hook for project detection
│
├─ scripts/                        ← bash helper scripts
│  ├─ session-start.sh             ← detect project, output status summary
│  ├─ state.sh                     ← state.json CRUD operations
│  ├─ context.sh                   ← context file validation & checksums
│  └─ workflow.sh                  ← workflow YAML parsing & state management
│
├─ workflows/                      ← YAML workflow definitions
│  ├─ zero-to-one.yaml
│  ├─ quarterly-planning.yaml
│  ├─ idea-to-sprint.yaml
│  ├─ go-to-market.yaml
│  └─ feedback-loop.yaml
│
├─ templates/                      ← scaffolding templates
│  ├─ context/
│  │  ├─ product.md
│  │  ├─ company.md
│  │  ├─ personas.md
│  │  ├─ competitors.md
│  │  └─ goals.md
│  └─ claude-md/
│     └─ project.md                ← CLAUDE.md template for PM projects
│
├─ CLAUDE.md                       ← development best practices for contributors
└─ README.md                       ← plugin documentation
```

**Generated project CLAUDE.md (`templates/claude-md/project.md`)** — When a PM runs `/manna-init`, this template is copied to their project root and customized. It instructs Claude to:
- Always check `context/` files for product, persona, and competitive context before answering PM questions
- Use `/manna-run [skill]` commands for structured PM workflows rather than ad-hoc responses
- Reference `outputs/` for prior analyses before generating new ones
- Suggest context file updates when new insights emerge
- Be aware of active workflows tracked in `.manna-ray/state.json`
```

**Key insight:** No TypeScript, no compilation, no `package.json`. The plugin is entirely markdown commands + bash scripts + JSON configuration + YAML workflow definitions. This is the native Claude Code plugin model.

## 7. PM Project Structure (After `/manna-init`)

```
my-product/
├─ CLAUDE.md                       ← generated, configures Claude for Manna Ray
├─ .manna-ray/
│  └─ state.json                   ← workflow state, run history, checksums
│
├─ context/
│  ├─ product.md
│  ├─ company.md
│  ├─ personas.md
│  ├─ competitors.md
│  └─ goals.md
│
├─ outputs/
│  ├─ discovery/
│  ├─ strategy/
│  ├─ specs/
│  ├─ analytics/
│  ├─ launch/
│  └─ productivity/
│
└─ research/                       ← raw inputs (transcripts, surveys, etc.)
```

## 8. Skill Frontmatter Extension

Existing SKILL.md files need additional frontmatter fields for the plugin to operate. These are additive — existing fields are preserved.

```yaml
---
name: prd-generator
description: This skill should be used when structuring messy ideas into PRDs...
mode: specs
required_context:
  - product.md
  - personas.md
  - goals.md
output_dir: outputs/specs
output_prefix: prd
suggests_update:
  - product.md
---
```

New fields:
- `mode` — module category for `/manna-status` grouping
- `required_context` — context files needed before execution
- `output_dir` — where output files are saved (relative to project root)
- `output_prefix` — prefix for output filenames
- `suggests_update` — context files that may benefit from updates after this skill runs

**Output file naming convention:** `{output_prefix}-{user-provided-slug}-{YYYY-MM-DD}.md`. The slug is provided by the PM when running the skill (e.g., "widget redesign" becomes `widget-redesign`). If no slug is provided, Claude generates one from the skill's primary subject. Example: `prd-widget-redesign-2026-03-16.md`.

**SKILL.md casing:** Three skills (`cogs-analyzer`, `tech-debt-evaluator`, `user-journey-mapper`) currently use `SKILL.MD` (uppercase extension). These should be normalized to `SKILL.md` for consistency with Claude Code's auto-discovery, which expects `SKILL.md`.

## 9. Error Handling & Edge Cases

**State corruption:** If `.manna-ray/state.json` is invalid JSON, `scripts/state.sh` detects this and backs up the corrupted file as `state.json.bak`, then initializes a fresh state. The PM is warned that workflow progress was lost.

**Output file conflicts:** If an output file already exists at the target path, the new output appends a numeric suffix (e.g., `prd-widget-redesign-2026-03-16-2.md`). Existing files are never overwritten.

**Concurrent workflows:** Only one workflow can be active at a time (regardless of type). Starting a new workflow while one is active prompts: "An idea-to-sprint workflow is already active (step 3/6). Cancel it and start fresh, or continue with `/manna-workflow next`?"

**No active workflow:** `/manna-workflow next` with no active workflow displays: "No active workflow. Start one with `/manna-workflow start [name]`."

**Workflow cancel/restart:** `/manna-workflow cancel` marks the active workflow as cancelled in state.json and clears `currentStep`. Outputs from completed steps are preserved. `/manna-workflow restart [name]` cancels the active instance and starts fresh.

**Context size management:** If combined context files exceed 50,000 characters, the command warns the PM and suggests summarizing large context files. Context files are loaded in full — no automatic truncation — but the warning prevents silent token budget issues.

**Parallel workflow branches (Workflow B):** For the initial build, Workflow B is linearized: `north-star-finder → landscape-mapper → competitive-profile-builder → tech-debt-evaluator → cogs-analyzer → quarterly-planning-template → roadmap-builder`. Parallel branch support (convergence gates, multi-step execution) is deferred. The YAML format will be extended with a `parallel` key when needed.

**`feeds_into` semantics:** `feeds_into` is informational metadata used by the Pipeline Runner to auto-load the previous step's output file as additional context for the next step. It does NOT control execution order (that's determined by step ordering in the YAML). It does NOT block execution if the previous output is missing — it simply skips the auto-load and warns. This field exists to support future parallel branch merging where step order alone won't suffice.

**`backlog-prioritizer` vs `prioritization-engine`:** These are distinct skills. `prioritization-engine` scores and ranks 3+ roadmap features using RICE/ICE frameworks — used when deciding what to build. `backlog-prioritizer` triages large backlogs (10+ items) into P0-P3 priority buckets — used when re-prioritizing based on new data. Workflow E uses `backlog-prioritizer` because post-launch data typically surfaces many items needing triage, while Workflow C uses `prioritization-engine` for focused feature selection.

## 10. Scope for Initial Build

**In scope (Workflow C: Idea-to-Sprint):**
- Plugin manifest (`.claude-plugin/plugin.json`)
- 6 commands: `manna-init`, `manna-context`, `manna-run`, `manna-workflow`, `manna-status`, `manna-history`
- SessionStart hook + `scripts/session-start.sh`
- State management scripts (`scripts/state.sh`, `scripts/context.sh`, `scripts/workflow.sh`)
- Context file templates (5 files in `templates/context/`)
- Workflow C YAML definition (`workflows/idea-to-sprint.yaml`)
- 6 skills with extended frontmatter: `prioritization-engine`, `prd-generator`, `ab-test-designer`, `technical-spec-writer`, `user-story-writer`, `launch-checklist-generator`
- Context updater agent (`agents/context-updater.md`)
- Project CLAUDE.md template
- Plugin CLAUDE.md for contributors

**Deferred:**
- Workflows A, B, D, E (YAML definitions written, not tested end-to-end)
- Remaining 25 skills (frontmatter extended, runnable ad-hoc via `/manna-run`, not workflow-tested)
- Schema enforcement on skill outputs (future evolution)

## 11. Design Principles

1. **Native plugin model** — No compilation, no TypeScript, no build step. Markdown commands, bash scripts, JSON config, YAML definitions. This is how Claude Code plugins work.
2. **Skills stay as prompts** — The plugin handles plumbing; Claude handles reasoning. Skill `.md` files are the source of truth for PM methodology.
3. **Declare, don't discover** — Skills declare their dependencies in frontmatter. Missing dependencies fail fast with clear messages.
4. **Suggest, don't force** — Staleness warnings, update prompts, and workflow sequencing are suggestions. The PM retains full control.
5. **Outputs feed context** — Every insight should have a path back into the shared knowledge base via context file update suggestions.
6. **Workflows are guides, not cages** — Any skill can run standalone via `/manna-run`. Workflows provide sequencing and validation, but the PM can skip, jump, or go ad-hoc.
7. **Incremental population** — Context files don't need to be complete on day one. Skills work with what exists and flag what's missing.
8. **Portable paths** — All intra-plugin references use `${CLAUDE_PLUGIN_ROOT}`. All project references use `${CLAUDE_PROJECT_DIR}`.
