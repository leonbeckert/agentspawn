---
name: research
description: Gather domain knowledge for the agent being built. Intensity depends on agent type — from no research (internal-knowledge) to deep parallel research (analytical). Use after the interview phase.
---

# Research Phase

Gather the knowledge the agent needs. Research intensity was determined during classification.

## When to Research Deeply (Analytical/Research, some Creative)

Use the **researcher subagent** for parallel investigation. Launch separate research tasks for:
- Market data, trends, adoption rates, key statistics
- Competitor analysis, pricing, positioning
- Best practices, proven frameworks, methodologies
- Legal/regulatory context
- The user's existing public presence

## When to Research Lightly (Operational, Internal-Knowledge)

- Search for established patterns and conventions in the domain
- Check for regulatory requirements
- Look for prior art (templates, checklists, decision trees)
- Most context comes from the user's own files, not the web

## When NOT to Research Externally

- The agent is powered entirely by private context (SOPs, codebase, CRM)
- The domain is so specialized that public sources are noise
- The user has already provided comprehensive input

## Private Context Ingestion

For agents that rely on private documents:

### Step 1: Artifact Intake

Ask the user to share source materials. For each, classify:

| Artifact | Type | Confidentiality | Volatility | Use In Agent |
|---|---|---|---|---|
| [name] | SOP / Policy / Template / Log / Transcript | Internal-only / Redactable / Public | Stable / Quarterly / Monthly | CLAUDE.md / guide.md / skill / template |

### Step 2: Extract, Don't Dump

Don't copy-paste raw documents. Extract:
- Decision rules and branching logic
- Domain vocabulary and definitions
- Conventions and formatting requirements
- Edge cases and exceptions
- Explicit constraints and prohibitions

### Step 3: Mark Confidentiality Boundaries

```
What the agent may include in outputs:
- [list]

What the agent may use as context but NOT include in outputs:
- [list]

What the agent must NEVER reference:
- [list]
```

### Step 4: Source-of-Truth Precedence

For agents with multiple knowledge sources, define which wins when they conflict:

```
Source-of-truth precedence (highest to lowest):
1. [e.g., Current regulation text > internal policy > guide.md > general knowledge]
2. [e.g., Client brief > brand guidelines > skill defaults]

When sources conflict: flag the conflict, state which source you're following and why.
```

Essential for regulated and internal-knowledge agents. Usually unnecessary for creative agents.

## Source Strength (Analytical/Research agents)

Classify each piece of information by reliability:

| Strength | Definition | Use In Output |
|---|---|---|
| **Evidence** | Primary data, official statistics, regulation text | Can support output claims directly |
| **Orientation** | Industry reports, expert opinion, case studies | Context and framing, not hard claims |
| **Heuristic** | Community practice, rules of thumb, anecdotes | Background only — always hedge |

Mark source strength in guide.md so the agent distinguishes what supports a claim from what merely informed the framing.

## Research Rules

- Every factual claim in guide.md needs a source URL (for web-researched content)
- Private/internal content should note its origin and date
- Prefer primary sources over blog aggregators
- If you can't find data, note the gap — don't fabricate

## Research Checkpoints

After research, BEFORE moving to design:
- **Does research invalidate any interview assumptions?** If yes, re-interview.
- **Are there domain constraints you didn't ask about?** If yes, ask now.
- **Is the agent type still correct?** Reclassify if needed.
