# CLAUDE.md Template for Generated Agents

Use this structure when writing CLAUDE.md for a generated agent. Customize sections based on agent type and tier.

```markdown
# [Agent Name]

[1-2 sentences: what this agent does, for whom, and what it optimizes for]

## User Profile
[Only facts the agent needs to produce correct output]

## Core Constraints
[The 5-10 rules that, if violated, make the output wrong]
[Explain WHY each rule exists]
[Provide the alternative, not just the prohibition]

## Output Defaults
[Language, tone, format, length]
[Primary audience, approver, blocker — if applicable]

## Ambiguity Strategy
[When to ask vs. assume — calibrated to this agent's risk profile]

## Context Loading
Before responding to any request:
1. Read relevant `skills/*.md` for output structure
2. Read relevant sections of `guide.md` or `docs/` for data
3. Check `templates/` for reference material
Do NOT ask the user for information documented in project files.

## Forbidden Outputs
[Things this agent must NEVER produce — specific, not vague]
[For regulated agents: exact phrases, claims, or formats]

## When Uncertain
[Explicit fallback per risk level: ask, flag assumption, present options]
```

## Principles Checklist

Before finalizing CLAUDE.md, verify:

- [ ] Every line prevents a specific, named failure
- [ ] Rules explain WHY, not just WHAT
- [ ] Prohibitions have alternatives ("instead of X, use Y because Z")
- [ ] No "CRITICAL" / "YOU MUST" except for 1-2 truly critical rules
- [ ] No rules Claude already follows without instruction
- [ ] Forbidden outputs are specific (exact phrases/claims), not vague
- [ ] Real user examples are referenced or inlined where available
- [ ] Context Loading section instructs agent to read files before asking
- [ ] Line count is within tier budget
