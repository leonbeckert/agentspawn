---
name: classify
description: Classify an agent by type and complexity tier. Use at the start of any agent build request to determine how to approach the project.
---

# Classify Agent

Determine the agent type and complexity tier before any other work begins. This classification drives every downstream decision.

## Agent Type

Identify the dominant mode. If the agent spans modes, note the primary and secondary.

| Mode | Examples | Primary Input | Research Intensity | Top Failure Risks |
|---|---|---|---|---|
| **Creative/Voice** | Content marketing, brand copywriting, social media | Style samples, voice preferences, anti-examples | Low — voice > data | Tone drift, generic output |
| **Analytical/Research** | Market analysis, competitor intel, due diligence | Public data, frameworks, benchmarks | High — data is the product | Stale facts, hallucinated citations |
| **Operational/Workflow** | Code review, incident response, migration planning | Repo conventions, SOPs, decision trees | Low — process > research | Missed edge cases, wrong defaults |
| **Regulated/High-Risk** | Healthcare, legal, tax, compliance, security audit | Regulations, internal policies, approval chains | Medium — accuracy is existential | Non-compliant output, overclaiming |
| **Internal-Knowledge** | Support triage, onboarding, internal tools | CRM data, call transcripts, internal docs | None — all context is private | Confidentiality leaks, stale internal facts |

### What the type changes

- Creative agents need anti-examples and voice calibration, not market stats
- Analytical agents need sourced data and citation discipline, not creative freedom
- Operational agents need decision trees and failure examples, not competitor analysis
- Regulated agents need forbidden-output lists and escalation paths, not engagement metrics
- Internal-knowledge agents need private artifact ingestion, not web research

## Complexity Tier

Match investment to stakes. Not every agent needs the full framework.

| | Tier 1: Minimal | Tier 2: Standard | Tier 3: High-Stakes |
|---|---|---|---|
| **When** | Personal utility, low risk, single user, narrow scope | Professional use, moderate risk, real audience | Regulated, high liability, multi-stakeholder, brand-critical |
| **Examples** | Meeting notes formatter, git commit helper, journal prompter | Content marketing agent, sales support, technical writing | Medical documentation, legal compliance, client-facing contractual proposals |
| **CLAUDE.md** | 30-60 lines, core rules only | 80-120 lines, full structure | 80-150 lines, tight surface — manage risk through external structure |
| **Skills** | 1-3, lightweight | 3-8, with examples | 3-8, with good+bad examples, validation steps |
| **guide.md** | Optional | Yes, sourced | Yes, sourced, reviewed, with `[Review: date]` markers |
| **Evals** | 5 representative, informal | 10-15 representative + 5 edge + 3 adversarial | Full suite with scoring rubric + release criteria |
| **Design phase** | Failure list only | Full | Full + source-of-truth precedence |

**Default to Tier 2.** Upgrade to Tier 3 when: output goes to clients/regulators, mistakes have legal/financial cost, or the user says "this needs to be bulletproof." Downgrade to Tier 1 when: personal, low-risk, and narrow.

## Output

State explicitly to the user:

1. **Agent type:** [Primary mode] (secondary: [mode], if applicable)
2. **Complexity tier:** [1/2/3] — because [concrete reason]
3. **Top 3 risk factors** for this type+tier combination
4. **Research intensity:** None / Light / Deep

Ask the user if this classification is correct before proceeding to the interview phase.
