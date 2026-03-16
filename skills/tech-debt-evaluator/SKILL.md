---
name: tech-debt-evaluator
description: 'Quantify the business cost of technical debt and calculate the ROI of engineering-led refactoring. Use when: justifying refactoring, evaluating tech debt, pitching architecture changes, or explaining velocity drops.'
---

# Tech Debt Evaluator

Evaluate and quantify the business cost of technical debt to justify engineering-led refactoring initiatives using hard ROI and opportunity cost.

## Output
Save to `strategy/outputs/tech-debt-eval-[YYYY-MM-DD].md`

## When to Use This Skill
- Pitching a major refactor or platform migration to leadership
- Explaining why feature velocity has slowed down
- Deciding between shipping a new feature or fixing an architectural bottleneck

## The Problem

Engineers pitch tech debt fixes using technical terms ("we need to move to microservices," "the codebase is spaghetti"). Executives reject these pitches because they don't solve business problems. When tech debt isn't translated into business impact (lost revenue, slower time-to-market, retention risk), it never gets prioritized.

**This skill solves it by:** Translating engineering effort into a business case. It quantifies the "Status Quo Cost" (velocity drag, maintenance hours) and calculates the exact ROI and payback period of the refactoring effort.

## What You'll Get

I'll generate a structured business case for leadership including:
- An Executive TL;DR with a clear Go/No-Go recommendation
- The Status Quo Tax (what it costs to do nothing)
- The Investment & ROI (payback period)
- The Opportunity Cost (what roadmap items must be delayed)
- Strategic alignment to current business goals

## What You'll Need

**Critical inputs (ask if not provided):**
- What specific system/architecture is causing the debt?
- What are the current symptoms? (e.g., "deployments take 4 hours," "system crashes at 500 concurrent users")
- What is the engineering estimate for the refactor (in person-weeks)?

## Process

### Step 1: Check Your Context 📁
I'll start by reading your context files to ground the technical evaluation in business realities:
- `context/goals.md` — Current quarter's goals to anchor the cost of delayed features.
- `context/product.md` — Current roadmap and known issues.
- `context/company.md` — Team capacity (headcount) and average engineering costs.

**I'll tell you what I found.** For example:
> "I found your goal to launch the document processing engine for 🦆 Morganser - AI Doc Buddy in `goals.md` and noticed your engineering capacity is 4 developers. I will quantify how the current pipeline bottlenecks are impacting your ability to deliver this milestone."

### Step 2: Gather Missing Context
If context is missing, I'll ask:
> "Before I evaluate this technical debt, I need:
> 1. What specific system is causing the debt?
> 2. What is the engineering estimate for the refactor (in person-weeks)?
> 3. What is the observable business symptom right now?"

*Note: If engineering estimates are missing, I will prompt you to get a rough t-shirt size (S/M/L) from your engineering lead before proceeding. I will not hallucinate effort.*

### Step 3: Quantify the Business Cost (Status Quo Tax)
I will calculate the ongoing cost of the bad architecture across three dimensions:
- **Velocity Drag:** Time lost building around the bad architecture.
- **Maintenance Overhead:** Hours burned on incident response and manual bug fixes.
- **Downtime/Risk Cost:** The revenue, SLA, or churn risk of system failures.

### Step 4: Calculate ROI & Opportunity Cost
I'll compare the cost of the refactoring effort against the status quo to find the **Payback Period** (how many weeks until the refactor pays for itself). I will explicitly list what roadmap items must be deferred to fund this investment.

## Output Template

I'll generate this business case for you:

```markdown
# Tech Debt Business Case: [System/Project Name]

**Date:** [YYYY-MM-DD]
**Author:** [Name]
**Recommendation:** 🟢 FUND / 🟡 DELAY / 🔴 REJECT

## Executive TL;DR
[2-3 sentences: "The legacy database is costing us 15 engineering hours per week in maintenance. We propose a 3-week refactor that will pay for itself in 8 weeks and accelerate our Q4 roadmap goals."]

---

## 1. The Status Quo (The Cost of Doing Nothing)
*If we do not fix this, we continue to pay the following "taxes":*

- **Velocity Tax:** [e.g., Features take 20% longer to ship]
- **Maintenance Tax:** [e.g., 15 hours/week spent on manual restarts]
- **Risk Profile:** [e.g., 10% chance of data loss during peak loads]

## 2. The Investment & ROI
*What it takes to fix it, and when we break even.*

- **Required Investment:** [X person-weeks / $Y cost]
- **The Fix:** [Brief, non-jargon explanation of the technical solution]
- **Expected Payback Period:** [X weeks/months until time saved equals time spent]
- **Long-term Dividend:** [What we gain after the payback period]

## 3. The Trade-offs (Opportunity Cost)
*To fund this architectural investment, we must make the following roadmap changes:*

| Feature / Goal | Original Target | Proposed Target | Justification |
| :--- | :--- | :--- | :--- |
| [Roadmap Item 1] | [Date] | [Delayed Date] | Pushed to free up 2 backend engineers |
| [Roadmap Item 2] | [Date] | [Unchanged] | Unaffected (frontend only) |

---

## 4. Strategic Alignment
*How this engineering investment serves `goals.md`:*
- Supports **[Business Goal 1]** by [Explanation]
- Mitigates risk for **[Business Goal 2]** by [Explanation]
