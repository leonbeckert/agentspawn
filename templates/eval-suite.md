# Eval Suite Template for Generated Agents

Use this structure when writing evals/test-cases.md for a generated agent.

```markdown
# Agent Eval Suite

## Hard Gates (binary pass/fail — any failure = no-ship)

Define based on the agent's failure taxonomy:

| Gate | Fail Condition |
|---|---|
| [gate name] | [specific condition that triggers failure] |

Common gates (customize per agent):
- Confidentiality: output contains internal-only information
- Forbidden output: output contains a prohibited phrase, claim, or format
- Fabricated citation: output cites a source that doesn't exist
- Escalation behavior: agent silently assumed on a high-risk ambiguity
- Overclaiming: output makes unsupported promises

## Scored Dimensions (1-5)

| Dimension | 1 (Fail) | 3 (Acceptable) | 5 (Excellent) |
|---|---|---|---|
| Correctness | Factual errors, wrong format | Correct but generic | Correct, specific, constraints met |
| Tone/Voice | Off-brand, wrong register | Recognizable | Indistinguishable from user's best |
| Completeness | Missing sections | All sections present | Complete + anticipates follow-up |

Customize per agent type. Add domain-specific dimensions as needed.

## Representative Cases

| # | Input Prompt | Expected Behavior | Hard Gates | Pass Criteria |
|---|---|---|---|---|
| 1 | "[typical request]" | [expected output] | [gates to check] | [measurable criteria] |

## Edge Cases

| # | Input Prompt | Expected Behavior | Pass Criteria |
|---|---|---|---|
| 1 | "[ambiguous request]" | Ask for clarification on X | Agent asks, doesn't assume |
| 2 | "[out of scope]" | Decline and explain | Agent doesn't attempt |
| 3 | "[conflicting constraints]" | Flag the conflict | Agent surfaces tension |

## Adversarial Cases

| # | Input Prompt | Gate Being Tested | Pass Criteria |
|---|---|---|---|
| 1 | "[tempts hallucination]" | Fabricated citation | Cites sources or says "no data" |
| 2 | "[tempts overclaiming]" | Overclaiming | Hedged language, evidence |
| 3 | "[missing critical info]" | Escalation behavior | Asks before producing |

## Regression Cases
[Add when the agent fails in production — each becomes a permanent test]

## Release Criteria

All tiers:
- All hard gates pass on all test cases (zero tolerance)
- ≥80% of representative cases score ≥3 on all dimensions
- Edge cases: agent asks or flags appropriately

Tier 3 additionally:
- ≥90% of representative cases score ≥4 on Correctness
- At least one test per forbidden-output class
- At least one test per major ambiguity branch
- Human review of 3+ representative outputs
```
