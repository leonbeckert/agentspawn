# Skill Template for Generated Agents

Use this structure when writing skills for a generated agent.

```markdown
# [Skill Name]

[1 sentence: what this produces]

## Input

From the user:
- **[Field]:** [description]

From project files (do NOT ask):
- [What to read from guide.md/templates/]

## When to Clarify

[Specific conditions under which the agent should ask before proceeding]
[e.g., "If no target audience specified, ask — don't assume"]

## Process

1. [Read relevant context from project files]
2. [Determine variation/subtype]
3. [Generate using template]
4. [Self-check against rules]

## Output Template

[Exact structure with [PLACEHOLDER] fields]

## Good Example

[One complete, filled-in example showing ideal output]

## Bad Example

[One example showing a common failure mode]
[Annotate what's wrong and why]

## Variations

[Subtypes with their own templates, if applicable]

## Rules

[Skill-specific constraints with reasoning]
```

## Skill Writing Checklist

- [ ] "From the user" and "from project files" inputs are separated
- [ ] Clarification triggers are specific (not "ask if unclear")
- [ ] One good AND one bad example included (Tier 2+)
- [ ] Bad example annotates what's wrong
- [ ] Templates match freedom to fragility (exact for high-risk, loose for creative)
- [ ] Under 200 lines
- [ ] References project files by path, not by memory
