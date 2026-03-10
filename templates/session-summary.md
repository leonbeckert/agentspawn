# Session Summary Template

Use this format when writing session summaries to `.claude/memory/sessions/`.

Filename: `YYYY-MM-DDTHHMMZ-[phase]-[agent-name].md`

Examples:
- `2026-03-09T1430Z-build-transport-agent.md`
- `2026-03-09T1615Z-validate-transport-agent.md`
- `2026-03-10T0900Z-interview-billing-bot.md`

## Template

```markdown
---
agent: [agent-name]
phase: [classify|interview|research|design|build|validate|deliver]
tags: [relevant-tags]
artifacts:
  - [paths to files created or modified]
---

## Objective
[One sentence: what was the goal of this session/phase.]

## Decisions
- [Decision 1 — and why]
- [Decision 2 — and why]

## Artifacts
- [file path]: [what it is]

## Open Threads
- [Unresolved issue or follow-up needed]
- [Question that came up but wasn't answered]

## Resume Prompt
[1-2 sentences: what to do next to continue this work. Written as if briefing someone picking this up cold.]
```

## Rules

- Keep each summary under 40 lines. This is a compressed record, not a transcript.
- Decisions are the most valuable section. Be specific about what was chosen and why.
- The Resume Prompt should let someone (or a future Claude session) pick up work immediately.
- Do not include raw conversation, full file contents, or verbose reasoning.
- Tags should be searchable: agent name, phase name, deployment target, domain keywords.
