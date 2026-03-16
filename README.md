# Manna Ray

A Claude Code plugin that turns Claude into a Product Management Operating System. Manna Ray orchestrates 31 PM skills across 5 structured workflows, managing context files, workflow state, and skill chaining — so PMs can focus on decisions, not process.

## What It Does

Manna Ray wraps your product knowledge in five **context files** (product, company, personas, competitors, goals) and automatically injects the right context when you run PM skills. It tracks what you've done, chains skills into multi-step workflows, and nudges you when context files go stale.

You stay in Claude Code. Manna Ray handles the plumbing.

## Quick Start

### Install

```bash
# Clone into your Claude Code plugins directory
git clone <repo-url> ~/.claude/plugins/manna-ray
```

### Initialize a Project

Open Claude Code in your project directory and run:

```
/manna-init
```

This scaffolds:
- `context/` — Five context files (product, company, personas, competitors, goals)
- `outputs/` — Organized output directories (discovery, strategy, specs, analytics, launch, productivity)
- `.manna-ray/state.json` — Project state tracking
- `CLAUDE.md` — Configures Claude to work with Manna Ray

You'll be guided through populating your context files.

### Run a Skill

```
/manna-run prd-generator
```

Manna Ray validates that required context files exist, warns if any are stale, loads them automatically, runs the skill, saves the output, and records the run in your project history.

### Start a Workflow

```
/manna-workflow start idea-to-sprint
```

Workflows chain skills together. Each step's output feeds into the next. Use `/manna-workflow next` to advance, `/manna-workflow skip` to skip a step, or `/manna-workflow cancel` to abandon.

### Check Status

```
/manna-status
```

Shows context file health, active workflow progress, and recent skill runs.

## Commands

| Command | Description |
|---|---|
| `/manna-init` | Scaffold a new PM project with context files and state |
| `/manna-run [skill]` | Run a skill with automatic context injection |
| `/manna-run list [mode]` | List available skills, optionally filtered by mode |
| `/manna-workflow start [name]` | Begin a multi-step workflow |
| `/manna-workflow next` | Advance to the next workflow step |
| `/manna-workflow skip` | Skip the current step |
| `/manna-workflow cancel` | Cancel the active workflow |
| `/manna-workflow restart [name]` | Cancel and restart a workflow |
| `/manna-workflow status` | Show detailed workflow step progress |
| `/manna-workflow list` | List all available workflows |
| `/manna-context init` | Create context file templates |
| `/manna-context check` | Show context file health (missing, empty, stale) |
| `/manna-context update [file]` | Update a context file with new insights |
| `/manna-status` | Project dashboard — context, workflows, recent runs |
| `/manna-history [skill]` | Run history and output files, optionally filtered |

## Workflows

### Zero-to-One Discovery
*Take a vague market opportunity and turn it into a validated, testable solution.*

```
user-interview-analyzer → research-synthesis-engine → jtbd-extractor
→ user-journey-mapper → opportunity-solution-tree
```

### Quarterly Strategic Planning
*Align the company on what to build next quarter.*

```
north-star-finder → landscape-mapper → competitive-profile-builder
→ tech-debt-evaluator → cogs-analyzer → quarterly-planning-template → roadmap-builder
```

### Idea-to-Sprint Execution
*Take an approved roadmap initiative to sprint-ready tickets.*

```
prioritization-engine → prd-generator → ab-test-designer
→ technical-spec-writer → user-story-writer → launch-checklist-generator
```

Prerequisite: a roadmap output (`outputs/strategy/roadmap-*.md`) must exist.

### Go-to-Market
*Position and price a feature to win in the market.*

```
swot-analysis-generator → positioning-statement-generator → pricing-strategy-analyzer
→ sales-enablement-kit → weekly-plan → daily-plan
```

### Feedback Loop
*Analyze post-launch data and feed learnings back into the system.*

```
ab-test-analyzer → funnel-analyzer → metric-framework-builder
→ research-synthesis-engine → backlog-prioritizer
```

## Skills (31)

### Discovery
| Skill | What It Does |
|---|---|
| `user-interview-analyzer` | Transform interview transcripts into structured snapshots |
| `research-synthesis-engine` | Combine insights from multiple research sources |
| `jtbd-extractor` | Turn raw research into Jobs-to-be-Done statements |
| `user-journey-mapper` | Map end-to-end user journeys across lifecycle stages |
| `opportunity-solution-tree` | Map outcomes to opportunities to testable solutions |

### Strategy
| Skill | What It Does |
|---|---|
| `north-star-finder` | Identify the one metric that captures core product value |
| `landscape-mapper` | Map competitors into positioning matrices |
| `competitive-profile-builder` | Build strategic competitor profiles |
| `swot-analysis-generator` | Structured SWOT with strategic implications |
| `positioning-statement-generator` | Positioning via April Dunford's framework |
| `pricing-strategy-analyzer` | Competitive pricing, packaging, revenue modeling |
| `roadmap-builder` | Structured roadmap linked to business objectives |
| `quarterly-planning-template` | Quarterly plan with themes, bets, resource allocation |
| `backlog-prioritizer` | Prioritize backlogs into P0/P1/P2 using RICE |
| `prioritization-engine` | Defend roadmap with RICE/ICE scoring frameworks |
| `tech-debt-evaluator` | Quantify business cost of tech debt |
| `cogs-analyzer` | Evaluate unit economics and infrastructure costs |

### Specs
| Skill | What It Does |
|---|---|
| `prd-generator` | Transform ideas into structured PRDs |
| `technical-spec-writer` | Architecture, data models, API designs |
| `user-story-writer` | Sprint-ready INVEST stories with acceptance criteria |
| `launch-checklist-generator` | Launch checklists customized to feature tier |

### Analytics
| Skill | What It Does |
|---|---|
| `ab-test-designer` | Design experiments with hypotheses and sample sizes |
| `ab-test-analyzer` | Interpret results with ship/no-ship recommendations |
| `funnel-analyzer` | Identify drop-off points and optimization opportunities |
| `metric-framework-builder` | Design metrics frameworks showing what to measure |

### Productivity & Communication
| Skill | What It Does |
|---|---|
| `daily-plan` | Time-blocked daily plan aligned to goals |
| `weekly-plan` | Weekly priorities with milestones and risk tracking |
| `meeting-notes-processor` | Extract action items and decisions from meetings |
| `executive-update-generator` | Concise executive updates using SCARF framework |
| `sales-enablement-kit` | Battlecards and how-to-sell materials |
| `stakeholder-simulator` | Feedback from simulated CTO, UX, Sales perspectives |

## Context Files

Manna Ray uses five canonical context files that accumulate product knowledge over time:

| File | Contains |
|---|---|
| `context/product.md` | Product overview, roadmap, key metrics, known issues, positioning |
| `context/company.md` | Strategic priorities, team structure, business model, constraints |
| `context/personas.md` | User archetypes, jobs-to-be-done, pain points, current solutions |
| `context/competitors.md` | Competitor profiles, win/loss themes, market gaps, pricing intel |
| `context/goals.md` | Annual goals, quarterly OKRs, success metrics, blockers |

Context files are checked for staleness (30-day threshold). When a skill produces insights relevant to a context file, Manna Ray suggests updating it.

## Project Structure

After initialization, your project looks like this:

```
your-project/
├── .manna-ray/
│   └── state.json          # Workflow state, context checksums, run history
├── context/
│   ├── product.md           # Product context
│   ├── company.md           # Company context
│   ├── personas.md          # User personas
│   ├── competitors.md       # Competitive intel
│   └── goals.md             # Goals & OKRs
├── outputs/
│   ├── discovery/           # Interview snapshots, JTBD, research synthesis
│   ├── strategy/            # Roadmaps, positioning, competitive analysis
│   ├── specs/               # PRDs, tech specs, user stories
│   ├── analytics/           # A/B tests, funnels, metrics
│   ├── launch/              # Sales kits, launch checklists
│   └── productivity/        # Daily/weekly plans
├── research/                # Raw research materials
└── CLAUDE.md                # Configures Claude for Manna Ray
```

## Architecture

Manna Ray is a native Claude Code plugin — no compilation, no build step. Everything is markdown, bash, JSON, or YAML.

```
manna-ray/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── commands/                # Slash commands (auto-discovered)
├── skills/                  # PM skills (prompt-driven .md files)
├── agents/                  # Subagent definitions
├── hooks/
│   └── hooks.json           # SessionStart hook
├── scripts/                 # Bash helpers for state, context, workflows
├── workflows/               # YAML pipeline definitions
├── templates/               # Scaffolding templates
└── tests/                   # Bash test suite
```

### Dependencies

- `jq` — JSON manipulation in scripts
- `yq` — YAML parsing for workflow definitions

## Testing

```bash
bash tests/test-state.sh
bash tests/test-context.sh
bash tests/test-workflow.sh
bash tests/test-session-start.sh
```

30 tests covering state CRUD, context validation, workflow engine, and session detection.

## Design Principles

1. **Native plugin model** — No compilation. Markdown + bash + JSON + YAML.
2. **Skills stay as prompts** — The plugin handles plumbing; Claude handles reasoning.
3. **Declare, don't discover** — Dependencies declared in frontmatter and workflow YAML.
4. **Suggest, don't force** — Warnings and prompts are always skippable.
5. **Portable paths** — `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_PROJECT_DIR}` everywhere.
6. **Incremental population** — Context files grow organically over time.

## License

MIT
