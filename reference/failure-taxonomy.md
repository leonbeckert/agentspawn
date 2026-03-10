# Failure Taxonomy Reference

Reference table of common agent failure modes. Use during the design phase to identify which failures apply to the agent being built.

## Full Failure Mode Table

| Failure Class | Description | Typical Severity | Common Triggers | Prevention Mechanisms |
|---|---|---|---|---|
| **Missing knowledge** | Agent doesn't know something it should | Varies | Incomplete guide.md, missed domain constraint | Research, guide.md, retrieval design |
| **Hallucinated facts** | Agent cites statistics, sources, or claims that don't exist | High | No source requirement, weak eval | Source requirements in skills, adversarial evals |
| **Wrong tone** | Output register doesn't match audience (too casual, too formal, wrong voice) | Medium | No voice examples, no anti-examples | Good+bad examples in skills, principles template |
| **Wrong format** | Produces prose when table was needed, or wrong output structure | Low | Vague output spec in skill | Exact output templates in skills |
| **Ignored constraints** | Exceeds character limit, uses forbidden terms, violates platform rules | High | Rule buried in long CLAUDE.md, no eval | CLAUDE.md rules with WHY, eval coverage |
| **Over-asking** | Asks 5 questions before doing anything | Medium | No defaults, unclear ambiguity strategy | Skill input spec, ambiguity calibration |
| **Under-asking** | Assumes wrong context, produces wrong output without checking | High | Too-aggressive defaults, no clarification triggers | Clarification triggers in skills, risk-calibrated strategy |
| **Stale information** | Uses last year's pricing, old regulations, deprecated APIs | High | No review dates, no maintenance model | `[Review: date]` markers, maintenance cadence |
| **Confidentiality leak** | Includes internal data in client-facing output | Critical | No confidentiality boundaries, raw context in skills | Context boundaries, output rules, hard gate eval |
| **Overclaiming** | Promises ROI, guarantees, or capabilities the user can't deliver | High | No forbidden claims list, no evidence requirements | Forbidden outputs in CLAUDE.md, evidence rules in skills |
| **Scope creep** | Produces output for tasks outside its domain | Medium | Vague scope definition | Explicit scope boundaries in CLAUDE.md |
| **Citation gaming** | Formats opinions as citations or attributes claims to wrong sources | Medium | Source format requirements without verification | Source strength classification, eval |
| **Template rigidity** | Follows template too literally when context requires adaptation | Low | Over-templated skills with no variation guidance | Variation sections in skills, freedom calibration |
| **Context pollution** | Loads irrelevant files into context, diluting signal | Low | Poor file organization, vague retrieval instructions | Descriptive filenames, specific context loading instructions |

## By Agent Type — Most Likely Failures

**Creative/Voice:** Tone drift, generic output, template rigidity, over-asking
**Analytical/Research:** Hallucinated facts, stale information, citation gaming, overclaiming
**Operational/Workflow:** Under-asking, missed edge cases, scope creep, wrong defaults
**Regulated/High-Risk:** Overclaiming, confidentiality leak, ignored constraints, under-asking
**Internal-Knowledge:** Confidentiality leak, stale information, context pollution, missing knowledge
