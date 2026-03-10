---
name: design
description: Create a design brief for the agent being built. Synthesizes classification, interview, and research into a concrete plan including failure taxonomy, skill boundaries, knowledge architecture, and tool strategy. The design brief must be approved before building.
---

# Design Phase

Design the agent system before writing files. This phase produces `design-brief.md` — the mandatory artifact that unlocks the build phase.

Read `reference/failure-taxonomy.md` and `reference/knowledge-architecture.md` for detailed reference tables.

## 1. Failure Taxonomy

Identify the most likely and most costly failures for THIS agent. Rank the top 3-5 by cost.

Common failure classes:

| Failure | Example | Fix Via |
|---|---|---|
| Missing knowledge | Doesn't know a regulation exists | guide.md, retrieval |
| Hallucinated facts | Cites a stat that doesn't exist | Source requirements, eval |
| Wrong tone | Too casual for C-suite | Voice examples, anti-examples |
| Wrong format | Prose when table was needed | Skill templates |
| Ignored constraints | Exceeds char limit, forbidden terms | CLAUDE.md rules, eval |
| Over-asking | 5 questions before doing anything | Skill input spec, ambiguity rules |
| Under-asking | Assumes wrong context | Clarification triggers |
| Stale information | Last year's pricing | Maintenance model, dating |
| Confidentiality leak | Internal data in client output | Context boundaries |
| Overclaiming | Promises undeliverable ROI | Forbidden claims, evidence rules |

**Design the system to prevent the top failures first.** Cosmetic failures can be fixed later.

## 2. Skill Boundary Design

Split skills when:
- Different required inputs (proposal vs. LinkedIn post)
- Different source dependencies (market data vs. style samples)
- Different validation logic (legal check vs. tone check)
- Different failure costs (client contract vs. internal note)
- Different tone (executive brief vs. team update)

Merge skills when:
- Same inputs, same tone, same validation → one skill with format variants
- One is always a sub-step of the other → one skill with phases
- Splitting would force sequential invocation for what feels like one task

## 3. Knowledge Architecture

Separate knowledge by volatility and access pattern:

| Layer | What | File | Loads |
|---|---|---|---|
| Always-loaded | Identity, core rules, top constraints | CLAUDE.md | Every session |
| On-demand | Frameworks, decision trees, detailed rules | skills/*.md | On trigger |
| Deep reference | Market data, case studies, regulations | guide.md or docs/ | On search |
| Stable | Brand voice, positioning, values | templates/principles.md | On demand |
| Current facts | Pricing, team, offerings | templates/current-facts.md | On demand (quarterly) |
| Volatile | Seasonal offers, campaigns | templates/current-campaign.md | On demand (monthly) |
| Client-specific | Per-client notes | clients/[name].md | Per client |

Every filename should answer a retrieval question. Every file starts with a one-line purpose statement.

## 4. Tool Strategy

| Signal | Use a Tool | Use a Prompt Instruction |
|---|---|---|
| Deterministic computation | Yes — LLMs shouldn't do arithmetic | — |
| External data lookup | Yes — can't bake into context | — |
| Format validation | Yes — "never send an LLM to do a linter's job" | — |
| Stylistic judgment | — | Yes — LLMs excel at this |
| Creative generation | — | Yes — core capability |
| Clear rule-based decision | Yes — encode as script/tree | — |
| Judgment under ambiguity | — | Yes — with calibrated strategy |

## 5. Ambiguity Resolution

Define how the agent handles incomplete information, calibrated to its risk profile:
- Regulated/High-Risk: ask more, assume less
- Creative/Voice: assume more, the user wants flow
- Operational: follow decision tree, escalate at branch points

## 6. Subagent Configuration (project/user-level targets only)

When the deployment target is project subagent or user-level agent, make these decisions:

| Decision | Options | Default | Guidance |
|---|---|---|---|
| Model | `inherit`, `sonnet`, `opus`, `haiku` | `inherit` | Use `haiku` for fast read-only tasks, `sonnet` for balanced work, `opus` for complex reasoning |
| Tool restrictions | `tools` (allowlist) or `disallowedTools` (denylist) | Inherit all | Use `disallowedTools` to block Write/Edit for read-only agents. Use `tools` allowlist for tightly scoped agents |
| Permission mode | `default`, `acceptEdits`, `dontAsk`, `plan` | `default` | `dontAsk` for autonomous agents (auto-denies prompts). `acceptEdits` for edit-heavy workflows. `plan` for read-only |
| Memory | `project`, `user`, `local` | None | `project` for codebase knowledge (can be version-controlled). `user` for cross-project learning. `local` for private project knowledge |
| Max turns | Number | Unlimited | Set to prevent runaway execution. Estimate based on typical task complexity |
| Background | `true`/`false` | `false` | `true` if the agent is typically launched in parallel with other work |
| Hooks | PreToolUse, PostToolUse, Stop | None | Add when you need runtime validation (e.g., blocking write operations, validating output format) |
| Isolation | `worktree` | None | Use when the agent modifies files that shouldn't affect the main working tree |
| Skill preloading | List of skill names | None | List skills in `skills` field to inject full content at startup. Subagents don't inherit parent skills |
| MCP servers | Server names or inline defs | None | Only if the agent needs external tool access (databases, APIs, etc.) |

**Key constraint:** Subagents cannot spawn other subagents. Design skills and workflows accordingly — complex multi-step work should be handled through skill chaining within the subagent, not delegation.

## 7. Multi-Stakeholder (if applicable)

```
Primary audience: [who the output is written FOR]
Approver: [who reviews — their constraints override]
Blocker: [who can reject — their red lines are absolute]
```

## Output: design-brief.md

Write the design brief to `generated-agents/[agent-name]/design-brief.md` with this structure:

```markdown
# Design Brief: [Agent Name]

## Classification
- Type: [primary] (secondary: [if any])
- Tier: [1/2/3]

## Deployment Target
- **Standalone workspace** / **Project subagent** / **Multi-project subagent** / **User-level agent**
- Target path(s): [where files will be written; for multi-project, list all target projects]
- Reason: [why this target fits]

## Scope
- What it does: [1-2 sentences]
- What it does NOT do: [explicit boundaries]

## Top Failure Modes (ranked by cost)
1. [failure] — prevented by [mechanism]
2. [failure] — prevented by [mechanism]
3. [failure] — prevented by [mechanism]

## Skill Plan
| Skill | Purpose | Inputs | Key Risk |
|---|---|---|---|
| [name] | [what it produces] | [from user / from files] | [what goes wrong] |

## Knowledge Architecture
[Which files, what goes where, what's stable vs. volatile]

## Tool Requirements
[What tools are needed, what's prompt-only]

## Subagent Configuration (project/user-level only)
- Model: [inherit/sonnet/opus/haiku] — [reason]
- Tool restrictions: [allowlist or denylist] — [what's blocked and why]
- Permission mode: [default/acceptEdits/dontAsk/plan] — [reason]
- Memory: [project/user/local/none] — [what it should remember across sessions]
- Max turns: [number or unlimited] — [reason]
- Background: [true/false] — [reason]
- Hooks: [PreToolUse/PostToolUse/Stop or none] — [what they validate]
- Isolation: [worktree or none] — [reason]
- MCP servers: [list or none]

## Ambiguity Strategy
[When to ask vs. assume for this agent]

## Source-of-Truth Precedence (Tier 3 only)
[Ordered list of which source wins]

## Forbidden Outputs (if applicable)
[Exact things the agent must never produce]

## Open Questions
[Anything still uncertain — or "None" with justification]
```

**After writing the design brief, present it to the user and wait for explicit approval before proceeding to /build.**
