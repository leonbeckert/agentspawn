---
name: deliver
description: Present the completed agent to the user with usage instructions, example prompts, eval results, known limitations, and maintenance model. Creates MAINTENANCE.md and README.md.
disable-model-invocation: true
---

# Deliver Phase

Present the completed agent to the user. This skill requires manual invocation because delivery should only happen after validation passes.

**Before starting:** Verify that `generated-agents/[agent-name]/evals/test-cases.md` exists and contains passing results. If not, tell the user to run /validate first.

## Delivery Presentation

Present to the user:

### 1. Project Tree
Show the full file structure of the generated agent.

### 2. How to Use It

Adapt to the deployment target:

**Standalone:**
```
cd generated-agents/[agent-name] && claude
```

**Project subagent:**
```
cd [target-project] && claude
# Then: "Use the [agent-name] agent to [task]"
# Or Claude will auto-delegate when relevant
```

**Multi-project subagent:**
```
cd generated-agents/[agent-name] && bash deploy.sh
# Then in any target project:
cd [target-project] && claude
# "Use the [agent-name] agent to [task]"
```

**User-level:**
```
claude  # from any project
# Then: "Use the [agent-name] agent to [task]"
```

Explain the workflow: what to say, how skills are invoked, how delegation works for subagents.

### 3. Example Prompts (3-5)
One per skill, using real-world phrasing the user would actually type. Not formal — conversational.

### 4. Eval Results Summary
Which test cases were run, what passed, scores on dimensions.

### 5. Known Limitations
What the agent can't do well yet. Be specific and honest.

### 6. Maintenance Expectations
What needs periodic review and when (link to MAINTENANCE.md).

## Generate MAINTENANCE.md

Write `generated-agents/[agent-name]/MAINTENANCE.md` using `templates/maintenance.md` as a starting point. Customize the review cadence and observability signals to this specific agent.

Must include:

### When the Agent Makes a Mistake
1. Fix the immediate output
2. Ask: recurring pattern or one-off?
3. Recurring → add rule to CLAUDE.md or skill (only if decision boundary, not edge case)
4. Edge case → add to evals/test-cases.md as regression test
5. If adding a rule exceeds line budget → prune a less-important rule first

### Observability Signals

| Symptom | Check First | Then Check |
|---|---|---|
| Asks questions answered in files | CLAUDE.md context loading, file paths | Skill input spec |
| Hallucinated facts | guide.md freshness, source rules | Skill template, eval coverage |
| Wrong tone or voice | Skill examples, principles template | CLAUDE.md output defaults |
| False refusal | Forbidden outputs (too broad?), scope | Ambiguity strategy |
| Uses stale data | `[Review: date]` markers | templates/current-facts.md |
| Overclaims | Forbidden claims list, evidence rules | Skill template |
| Conflicting behavior | CLAUDE.md contradictions | Source-of-truth precedence |

### Review Cadence

| What | Frequency | Action |
|---|---|---|
| current-facts.md | Quarterly | Update pricing, offerings, team |
| current-campaign.md | Monthly | Update or delete time-limited content |
| guide.md / docs/ | Biannually | Stale stats, dead links, outdated frameworks |
| skills/*.md | When outputs drift | Update templates, add bad examples |
| evals/test-cases.md | After significant failure | Add regression test |
| CLAUDE.md | Quarterly | Prune rules Claude follows without instruction |

### Pruning Rules
- If Claude consistently follows a rule without it being in CLAUDE.md → remove it
- If a rule was added for a one-off and hasn't triggered → remove it
- If two rules contradict → resolve, keep one, document why
- If CLAUDE.md exceeds budget → move content to skill or template

## Generate README.md

Write a brief `generated-agents/[agent-name]/README.md`:

```markdown
# [Agent Name]

[1-2 sentence description]

## Quick Start
cd [agent-name] && claude

## Skills
- [skill-name]: [what it does]
- ...

## Maintenance
See MAINTENANCE.md for review cadence and troubleshooting.
```

## After Delivery

Tell the user based on deployment target:

**Standalone:**
- The agent directory is self-contained and can be moved anywhere
- `cd [path] && claude` to start using it
- Review MAINTENANCE.md for ongoing care

**Project subagent:**
- The agent is now active in the project — restart Claude or use `/agents` to verify
- Claude will auto-delegate relevant tasks, or you can request the agent explicitly
- Subagent skills are namespaced with `[agent-name]-` to avoid conflicts
- Review MAINTENANCE.md for ongoing care

**Multi-project subagent:**
- Run `deploy.sh` to create symlinks in all target projects
- The source of truth is `generated-agents/[agent-name]/` — edit there, symlinks propagate
- To add a new target project: add its path to `deploy.sh` and re-run
- To remove from a project: delete the symlinks in that project's `.claude/` directory
- Review MAINTENANCE.md for ongoing care

**User-level:**
- The agent is now available in all projects
- Restart Claude or use `/agents` to verify it appears
- Review MAINTENANCE.md for ongoing care

For all targets: the agent will improve with use — add regression tests when it makes mistakes.
