---
name: user-journey-mapper
description: 'Map the end-to-end user journey across Discovery, Evaluation, Activation, and Retention to diagnose funnel drop-offs. Use when: mapping user journey, analyzing onboarding friction, or diagnosing churn.'
---

# User Journey Mapper

Map the end-to-end user journey across Discovery, Evaluation, Activation, and Retention to diagnose funnel drop-offs by connecting quantitative leaks to qualitative friction.

## Output
Save to `discovery/outputs/journey-map-[persona]-[YYYY-MM-DD].md`

## When to Use This Skill
- Diagnosing a leaky onboarding funnel
- Creating a baseline customer journey map for a new persona
- Planning growth experiments to improve stage-to-stage conversion

## The Problem

Product teams often look at funnel drop-offs as just numbers (e.g., "we are losing 45% of users at activation") without understanding the *why*. Conversely, qualitative journey maps are often idealized and disconnected from actual analytics. 

**This skill solves it by:** Forcing a cross-reference between your hard quantitative funnel metrics and the user's emotional state, ensuring that your proposed opportunities directly target the friction causing the most expensive drop-offs.

## What You'll Get

I'll generate a comprehensive, scannable Markdown table mapping the 4 key stages including:
- User goals and exact touchpoints
- Quantitative funnel metrics (conversion rate & absolute drop-off)
- Emotional state and cognitive/functional friction
- Moments of delight to amplify
- Hypothesis-driven opportunities to plug the leaks

## What You'll Need

**Critical inputs (ask if not provided):**
- Which specific persona are we mapping?
- What are the core touchpoints they interact with?
- Do you have a recent funnel analysis to pull metrics from?

## Process

### Step 1: Check Your Context 📁
I'll start by reading your existing context files:
- `context/personas.md` — Who is the user? What are their Jobs-to-be-Done?
- `context/product.md` — What is the core value proposition and "aha moment"?
- `analytics/outputs/` — Funnel analysis outputs for exact conversion rates.

**I'll tell you what I found.** For example:
> "I found your Loan Officer persona in `personas.md` for 🦆 Morganser - AI Doc Buddy, and noticed your recent `funnel-analysis` shows a 55% drop-off (450 users) between Evaluation and Activation. I'll map the journey to understand the friction causing that specific leak."

### Step 2: Gather Missing Context
If context is missing, I'll ask:
> "Before I map this journey, I need:
> 1. Which specific persona are we mapping?
> 2. What are the specific touchpoints they interact with?
> 3. What are the stage-by-stage drop-off numbers?"

*Note: If metrics are missing, I will mark them as `[NEEDS DATA]` rather than guessing.*

### Step 3: Map the Stages & Touchpoints
I will map the user's actions and channels across four core stages:
- **Discovery:** Realizing they have a problem and finding your solution.
- **Evaluation:** Assessing if the product is the right fit.
- **Activation:** The initial onboarding and reaching the "aha moment".
- **Retention:** Building a habit and realizing ongoing value.

### Step 4: Cross-Reference & Analyze Friction
For each stage, I will pull the quantitative drop-off metrics, then map the qualitative experience causing that drop-off (cognitive overload, missing features, confusing UI).

### Step 5: Identify Opportunities
Translate the friction into actionable hypotheses to improve the funnel.

## Output Template

I'll generate this journey map for you:

```markdown
# User Journey Map: [Persona Name]

**Date:** [YYYY-MM-DD]
**Target Product/Feature:** [Product Name]
**Primary Bottleneck:** [e.g., Evaluation -> Activation]

## Context
- **Core Job-to-be-Done:** [From personas.md]
- **The "Aha" Moment:** [From product.md]

---

## The Journey

| Stage | Discovery | Evaluation | Activation | Retention |
| :--- | :--- | :--- | :--- | :--- |
| **User Goal** | [What they want to solve] | [How they assess fit] | [Reaching the 'aha' moment] | [Achieving ongoing success] |
| **Funnel Metrics** | [X entering -> Y% conv] | [Y entering -> Z% conv] <br> *Drop: [Abs #]* | [Z entering -> A% conv] <br> *Drop: [Abs #]* | [A active -> B% retained] <br> *Churn: [Abs #]* |
| **Touchpoints** | [Channels/Interactions] | [Channels/Interactions] | [Channels/Interactions] | [Channels/Interactions] |
| **Emotional State** | [Emotion] | [Emotion] | [Emotion] | [Emotion] |
| **Friction** | [Specific obstacle] | [Specific obstacle] | [Specific obstacle] | [Specific obstacle] |
| **Delight** | [What is working well] | [What builds trust] | [The magic moment] | [The habit builder] |
| **Opportunities**| *Hypothesis:* [If we do X, then Y will happen] | *Hypothesis:* [If we do X, then Y will happen] | *Hypothesis:* [If we do X, then Y will happen] | *Hypothesis:* [If we do X, then Y will happen] |

---

## Top 3 Recommended Actions
1. **[High Impact/Low Effort]**: [Description of experiment/fix]
2. **[Strategic Bet]**: [Description of experiment/fix]
3. **[Data Need]**: [What we need to track better]
