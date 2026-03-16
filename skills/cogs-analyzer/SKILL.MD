---
name: cogs-analyzer
description: 'Evaluate unit economics, infrastructure costs, and third-party vendor expenses to calculate Cost of Goods Sold (COGS) and profit margins. Use when: analyzing COGS, evaluating unit economics, pricing a new feature, or reviewing profit margins.'
---

# COGS & Unit Economics Analyzer

Evaluate unit economics, infrastructure costs, and third-party vendor expenses to calculate Cost of Goods Sold (COGS) and ensure sustainable profit margins.

## Output
Save to `strategy/outputs/cogs-analysis-[YYYY-MM-DD].md`

## When to Use This Skill
- Pricing a new compute-heavy or AI-driven feature
- Evaluating if current subscription tiers support infrastructure costs
- Forecasting profitability at 10x or 100x user scale
- Auditing vendor expenses to find margin optimization opportunities

## The Problem

Product teams often price features based on competitor benchmarks or perceived user value, entirely missing the variable cost to deliver that feature. In software—especially AI—power users can quickly generate negative margins if third-party API costs or compute resources scale faster than revenue.

**This skill solves it by:** Forcing a strict breakdown of fixed infrastructure versus variable costs. It calculates your exact Cost Per User (CPU), models your gross margin, and pressure-tests your pricing model against high-volume usage.

## What You'll Get

I'll generate a structured Unit Economics report including:
- A breakdown of Fixed vs. Variable costs
- Current per-unit profitability (ARPU, CPU, and Gross Margin %)
- A 10x scale projection to test infrastructure elasticity
- Identification of your primary margin risks (e.g., power users)
- Actionable pricing or technical recommendations to protect margins

## What You'll Need

**Critical inputs (ask if not provided):**
- Cloud infrastructure estimates (e.g., AWS/GCP base server costs per month).
- Third-party vendor fees (e.g., AI API costs per 1k tokens, Stripe fees).
- Average usage per user per month (e.g., "the average user processes 50 documents a month").
- Target Gross Margin % (if known).

## Process

### Step 1: Check Your Context 📁
I'll start by reading your existing context files to ground the financial analysis:
- `context/product.md` — Current pricing tiers, user volumes, and core features.
- `context/company.md` — Overall business model and target gross margins.
- `context/competitors.md` — For benchmarking acceptable pricing models in your space.

**I'll tell you what I found.** For example:
> "I found your Pro tier pricing is $49/month for 🦆 Morganser - AI Doc Buddy in `product.md`, and your company target gross margin is 80% according to `company.md`. I will evaluate if your current LLM token costs and document parsing infrastructure support this margin."

### Step 2: Gather Missing Financial Context
If the cost context is missing, I'll ask:
> "Before I analyze your unit economics, I need:
> 1. What are your fixed monthly cloud costs?
> 2. What is the variable cost per action (e.g., API cost per document processed)?
> 3. What is the expected usage volume for an average user vs. a power user?"

### Step 3: Categorize Fixed vs. Variable Costs
I will separate the provided expenses into:
- **Fixed Infrastructure:** Base server costs, database hosting, minimum vendor commitments.
- **Variable COGS (Per User/Action):** API token costs, payment processing fees, compute/storage tied directly to usage.

### Step 4: Calculate Unit Economics
I will calculate the per-unit profitability using standard financial formulas:
- **ARPU:** Average Revenue Per User.
- **CPU:** Cost Per User (variable cost to serve one user for a month).
- **Gross Margin %:** `((ARPU - CPU) / ARPU) * 100`

### Step 5: Analyze Scalability and Risks
I will model what happens at 10x scale to identify if variable costs scale linearly, sub-linearly, or exponentially. I will specifically hunt for margin risks, such as unlimited usage tiers without fair-use caps.

## Output Template

I'll generate this financial analysis for you:

```markdown
# Unit Economics Analysis: [Product/Feature Name]

**Date:** [YYYY-MM-DD]
**Author:** [Name]
**Target Gross Margin:** [XX%]

## Executive Summary
[2-3 sentences: "Currently, our $29/mo tier yields a 65% gross margin. However, power users processing >500 items per month cost us $35 to serve, resulting in negative unit economics for the top 10% of our user base."]

---

## 1. Cost Breakdown

**Fixed Infrastructure (Monthly)**
- [Line Item 1, e.g., Base AWS RDS]: [$X]
- [Line Item 2, e.g., Vercel Pro]: [$X]

**Variable COGS (Per User/Action)**
- [Line Item 1, e.g., LLM Token Cost per action]: [$X]
- [Line Item 2, e.g., Stripe processing (2.9% + 30¢)]: [$X]

---

## 2. Unit Economics (Per User/Month)

| Metric | Average User | Power User (Top 10%) |
| :--- | :--- | :--- |
| **Usage Volume** | [X actions] | [Y actions] |
| **ARPU** | [$ Amount] | [$ Amount] |
| **Cost Per User (CPU)** | [$ Amount] | [$ Amount] |
| **Gross Margin %** | **[%]** | **[%]** |

---

## 3. Scale Projection (10x User Base)

| Metric | Current State | 10x Scale |
| :--- | :--- | :--- |
| **Total MRR** | [$ Amount] | [$ Amount] |
| **Total COGS** | [$ Amount] | [$ Amount] |
| **Key Cost Driver** | [e.g., OpenAI API fees] | [e.g., Database scaling limits] |

---

## 4. Margin Risks & Recommendations

**Identified Risks:**
- 🔴 [e.g., Unlimited pricing tier is vulnerable to API abuse]
- 🟡 [e.g., Storage costs scale linearly, reducing economies of scale]

**Recommended Actions:**
1. **[Pricing Fix]**: [e.g., Introduce a usage cap of 1,000 actions per month on the Pro tier]
2. **[Technical Fix]**: [e.g., Cache frequent API queries to reduce redundant third-party calls]
