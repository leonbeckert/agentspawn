# Maintenance Template for Generated Agents

Use this as a starting point for MAINTENANCE.md. Customize signals and cadence per agent.

```markdown
# Maintenance

## When the Agent Makes a Mistake

1. Fix the immediate output
2. Ask: is this a recurring pattern or a one-off?
3. If recurring: add a rule to CLAUDE.md or the relevant skill
   - Only if it reflects a decision boundary, not a single edge case
   - For edge cases: add to evals/test-cases.md as a regression test
4. If adding a rule exceeds line budget: prune a less-important rule first

## Observability — What to Track

| Symptom | Check First | Then Check |
|---|---|---|
| Asks questions answered in files | CLAUDE.md context loading, file paths | Skill input spec ("from project files" section) |
| Hallucinated facts | guide.md freshness, missing source rule | Skill template (requires evidence?), eval coverage |
| Wrong tone or voice | Skill examples, principles template | CLAUDE.md output defaults, anti-examples |
| False refusal | Forbidden outputs (too broad?) | Ambiguity strategy (too conservative?) |
| Wrong format | Skill output template | CLAUDE.md output defaults |
| Uses stale data | [Review: date] markers, guide.md timestamps | templates/current-facts.md |
| Overclaims | Forbidden claims list, evidence rules | Skill template (hedging?), eval gap |
| Conflicting behavior | CLAUDE.md (contradictory rules?) | Source-of-truth precedence |
| Leaks confidential info | Confidentiality boundaries | Skill template (raw context in output?) |

## Review Cadence

| What | Frequency | Action |
|---|---|---|
| templates/current-facts.md | Quarterly | Update pricing, offerings, team size |
| templates/current-campaign.md | Monthly | Update or delete time-limited content |
| guide.md (or docs/) | Biannually | Check for stale stats, dead links |
| skills/*.md | When outputs drift | Update templates, add bad examples |
| evals/test-cases.md | After significant failure | Add regression test |
| CLAUDE.md | Quarterly | Prune rules Claude follows without instruction |

## Pruning Rules

- If Claude follows a rule without it being in CLAUDE.md → remove it
- If a rule was added for a one-off and hasn't triggered → remove it
- If two rules contradict → resolve, keep one, document why
- If CLAUDE.md exceeds budget → move to skill or template

## Versioning

When making significant changes:
- Note what changed and why in a Changelog section
- If it affects output format/behavior → add regression test
- For Tier 3: re-run full eval suite after CLAUDE.md changes
```
