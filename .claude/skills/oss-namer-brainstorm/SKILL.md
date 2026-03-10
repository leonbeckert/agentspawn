# Brainstorm

Interactive naming exploration. Understand the project, propose naming angles across multiple strategies, and iterate on the user's reactions.

## Trigger

The user describes a project they want to name, or explicitly asks to brainstorm names.

## Inputs

**From the user:**
- Project description (what it does, who it's for)
- Target ecosystems (npm, PyPI, crates.io — or "all")
- Optional: names they've considered, names they like/dislike for reference

**From project files:**
- `docs/oss-namer-guide.md` — naming taxonomy, generation techniques, anti-patterns

## Workflow

### Step 1: Understand the Project

Extract from the user's description:
- **Core function** — what does it actually do? (one sentence)
- **Key differentiator** — what makes it different from alternatives?
- **Target audience** — who uses it? (developers, data scientists, ops, general)
- **Emotional register** — is this serious infrastructure or a fun utility?
- **Scale ambition** — small focused tool or ecosystem-level project?

If the description is too vague to extract these, ask ONE focused question. Don't interrogate.

If the user frames their project as "like X but better," note the competitor but find your own naming identity. Don't echo the competitor's naming style.

If the project operates in a space with well-known existing tools, note those tools by name to avoid naming collisions and to differentiate.

### Step 2: Generate Naming Angles

Propose 3-5 naming angles, each from a different strategy in the taxonomy. For each angle:

1. Name the strategy (Metaphorical, Descriptive+Personality, Mythological, etc.)
2. Explain the conceptual direction (e.g., "names based on speed/acceleration metaphors")
3. Give 3-4 concrete candidate names
4. For each candidate, one line explaining why it fits

Consider phonetic fit — match sound to project personality. Sharp consonants (k, t, v) for speed/precision tools; soft sounds (l, m, o) for friendly/approachable tools. See guide Section 2 for details.

Note: these are brainstorm candidates — availability has NOT been checked yet. Tell the user you'll verify availability in the shortlist phase.

**Example output format:**

```
## Angle 1: Speed Metaphors
Your library makes API calls faster — names that evoke acceleration.

- **Tailwind** — invisible force propelling you forward
- **Slipstream** — reduced resistance, effortless speed
- **Catalyst** — something that accelerates a reaction without being consumed

## Angle 2: Descriptive with Attitude
Names that say what it does but with personality.

- **Impatient** — because waiting for API responses is unacceptable
- **Snappy** — what your API calls become
```

### Step 3: Iterate

Based on the user's reaction:

- **"I like angle X"** → Go deeper in that direction. Generate 5-8 more candidates in that vein. Start thinking about which ones are likely available.
- **"None of these work"** → Pivot to strategies you haven't tried. If you used metaphor and mythology, try portmanteau and foreign language. Briefly acknowledge that naming is hard ("Let me try a completely different angle") without being defensive or apologetic.
- **"I like [specific name]"** → Do a quick availability pre-check (GitHub + primary registry). If available, suggest moving to `/shortlist` to score and fully check it alongside alternatives.
- **"I like the vibe of X but not the exact word"** → Explore the semantic neighborhood. Thesaurus, related concepts, adjacent metaphors.

### Anti-Pattern Checklist

Before proposing any name, mentally check:
- Is it a common English word with no creative hook? (fast, simple, core) → reject
- Is it a generic compound? (DataFlow, CodeHub, FastUtil) → reject
- Is it > 3 syllables with no obvious abbreviation? → flag or reconsider
- Could it be confused with a well-known project? → flag
- Is it phonetically or visually similar to an established project in the same domain? → flag
- Is it hard to spell when heard aloud? → flag
- Does it have an unfortunate meaning in another language or context? → search before proposing

## Good Example

**User:** "I have a Python library that adds human-in-the-loop approval to AI agent workflows. Before an agent takes a critical action, it pauses and asks a human to approve."

**Good response:**

> Your library is about the moment of pause — where an AI defers to human judgment. Let me explore some angles.
>
> **Angle 1: The Pause Metaphor**
> Names that evoke the deliberate stop before action.
> - **Checkpoint** — a mandatory verification point before proceeding
> - **Threshold** — the boundary you must consciously cross
> - **Turnstile** — controls passage, one at a time, with permission
>
> **Angle 2: Authority / Control**
> Names that evoke human oversight and governance.
> - **Veto** — the power to block an action (strong, 2 syllables)
> - **Gavel** — the judge's tool for rendering a decision
> - **Mandate** — authority granted explicitly, not assumed
>
> **Angle 3: Safety / Trust**
> Names that evoke the protective function.
> - **Guardrail** — prevents going off the edge
> - **Lifeline** — the safety mechanism you hope you don't need
> - **Canary** — early warning system (canary in the coal mine)
>
> Which direction resonates? Or should I try something completely different — maybe foreign language or mythology?

## Bad Example

**User:** Same as above.

**Bad response:**

> Here are some name ideas:
> - HumanLoop
> - ApprovalFlow
> - AIGateway
> - AgentGuard
> - SafeAgent

This fails because: all generic compounds, no creative hooks, no taxonomy diversity, no rationale, no direction for iteration.

## When to Suggest Moving to /shortlist

When the user has narrowed to 2-3 favorite directions and you have 10+ promising candidates across those directions, suggest running `/shortlist` to score them and check full availability.
