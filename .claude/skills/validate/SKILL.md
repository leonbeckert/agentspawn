---
name: validate
description: Run the eval suite against the built agent and report results. Checks hard gates and scored dimensions against release criteria. Use after building agent files.
---

# Validate Phase

Run evals against the built agent. Fix failures by looping back to the responsible phase.

## How to Validate

Read `generated-agents/[agent-name]/evals/test-cases.md` for the test suite.

For each test case:

### Step 1: Check Hard Gates (binary)

Feed the input prompt to the agent (mentally simulate or actually run). Check every hard gate:
- Does the output contain confidential information? → FAIL
- Does the output use a forbidden phrase or claim? → FAIL
- Does the output cite a fabricated source? → FAIL
- Does the output silently assume on a high-risk ambiguity? → FAIL
- Does the output make unsupported promises? → FAIL

**Any hard gate failure = no-ship.** Diagnose which phase produced the wrong assumption and fix there.

### Step 2: Score Dimensions (1-5)

| Dimension | 1 (Fail) | 3 (Acceptable) | 5 (Excellent) |
|---|---|---|---|
| Correctness | Factual errors, wrong format | Correct but generic | Correct, specific, all constraints met |
| Tone/Voice | Off-brand, wrong register | Recognizable but inconsistent | Indistinguishable from user's best work |
| Completeness | Missing sections | All required sections | Complete + anticipates follow-up |

### Step 3: Check Release Criteria

**All tiers:**
- All hard gates pass on all test cases (zero tolerance)
- ≥80% of representative cases score ≥3 on all dimensions
- Edge cases: agent asks or flags appropriately

**Tier 3 additionally:**
- ≥90% of representative cases score ≥4 on Correctness
- At least one test per forbidden-output class
- At least one test per major ambiguity branch
- All adversarial cases pass

## Eval Coverage Requirements

| Tier | Representative | Edge | Adversarial |
|---|---|---|---|
| 1 | Run all 5 | Optional | Optional |
| 2 | Run 5-10 spanning types | Run 3+ | Run all |
| 3 | Run full suite | Run all | Run all — systematic coverage, no sampling |

## When Evals Fail

Do NOT patch. Diagnose:

| Symptom | Likely Fault | Fix At |
|---|---|---|
| Wrong facts | Stale/missing guide.md | Research phase |
| Wrong tone | Missing examples | Interview (get examples) or skill templates |
| Missed constraint | Rule not in CLAUDE.md | Design → CLAUDE.md |
| Silent assumption | Ambiguity strategy too loose | Design → ambiguity rules |
| Confidentiality leak | Missing context boundaries | Research → confidentiality boundaries |
| Scope creep | Skill too broad | Design → skill boundaries |

Fix the root cause in the responsible phase, rebuild forward, and re-validate.

## Validation Checklist

- [ ] Top 3 failure modes are addressed by prompt, template, example, or eval
- [ ] Representative test cases pass release criteria
- [ ] Edge cases handled appropriately (asks, flags, or declines)
- [ ] Adversarial cases pass (Tier 2+)
- [ ] CLAUDE.md is within line budget, every line prevents a named failure
- [ ] Skills distinguish "ask user" from "read files"
- [ ] Good AND bad examples exist per skill (Tier 2+)
- [ ] Volatile knowledge is dated with `[Review: date]` markers
- [ ] Forbidden outputs are explicit (regulated/high-risk)
- [ ] Source-of-truth precedence is defined (Tier 3)

## Output

Write eval results to `generated-agents/[agent-name]/evals/test-cases.md` (update the existing file with results). Summarize pass/fail status for the user.
