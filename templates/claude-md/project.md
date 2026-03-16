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
