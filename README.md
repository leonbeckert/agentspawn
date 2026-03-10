# agentspawn

System that engineers production-grade AI agents. A 7-phase pipeline — classify, interview, research, design, build, validate, deliver — with hook-enforced quality gates and automated evaluation suites.

You describe what you need. agentspawn runs the full pipeline: classifies the agent type and complexity tier, interviews for requirements, researches the domain via a background subagent, produces a design brief for your approval, builds the agent files, validates against an eval suite, and delivers with usage instructions and a maintenance model.

Two phases are gate-enforced by shell hooks — the system cannot write agent files without an approved design brief, and cannot deliver without passing evals.

## Usage

```bash
cd agentspawn
claude
```

```
> I need an agent that [your use case]
```

## Pipeline

| Phase | What | Your role |
|---|---|---|
| **Classify** | Agent type (Creative, Analytical, Operational, Regulated, Internal-Knowledge) + complexity tier (1-3) | Confirm |
| **Interview** | Structured discovery — 2-3 rounds shaped by agent type | Answer |
| **Research** | Domain knowledge via researcher subagent (background, read-only) | Review |
| **Design** | Design brief: failure taxonomy, skill plan, knowledge architecture | **Approve** |
| **Build** | Agent files — you invoke `/build` | Invoke |
| **Validate** | Eval suite via evaluator subagent — hard gates + scored dimensions | Review |
| **Deliver** | Usage instructions + maintenance model — you invoke `/deliver` | Invoke |

## Quality Gates

Shell hooks intercept tool calls and enforce phase ordering at runtime:

| Hook | What it enforces |
|---|---|
| `require-design-brief.sh` | Blocks writes to agent directories unless `design-brief.md` exists |
| `require-evals-before-delivery.sh` | Blocks delivery artifacts unless eval results exist |
| `check-user-level-budget.sh` | Warns at 5, blocks at 10 user-level agents (context budget guard) |

`/build` and `/deliver` require manual invocation — the system cannot auto-invoke them.

## Output

The pipeline produces Claude Code native files:

| File | Purpose |
|---|---|
| Agent definition (`.md`) | System prompt — identity, constraints, forbidden outputs, ambiguity strategy |
| Skills (`SKILL.md`) | Workflows with input specs, output templates, good + bad examples |
| Knowledge base (`docs/`) | Sourced domain data, checklists, volatile facts with review dates |
| Eval suite (`test-cases.md`) | Hard gates (binary, zero tolerance) + scored dimensions (1-5) |

Deployment targets:

| Target | Location | Use case |
|---|---|---|
| Standalone workspace | `generated-agents/[name]/` | The agent is the project |
| Project subagent | `.claude/agents/` + `.claude/skills/` | Agent augments existing work |
| User-level | `~/.claude/agents/` + `~/.claude/skills/` | Available in every session |

## Design Approach

Every agent gets a failure taxonomy before any files are written. The design brief ranks the top 3-5 failure modes by cost and maps each to a prevention mechanism — a rule in the system prompt, a template in a skill, an eval hard gate, or a hook.

The evaluation model separates **hard gates** (binary — any failure blocks release) from **scored dimensions** (1-5 on correctness, tone, completeness). Release criteria: all hard gates pass, ≥80% of representative cases score ≥3 on all dimensions.

Agent type determines everything downstream:

| Type | Research Intensity | Top Risk |
|---|---|---|
| Creative/Voice | Low | Tone drift, generic output |
| Analytical/Research | High | Stale facts, hallucinated citations |
| Operational/Workflow | Low | Missed edge cases |
| Regulated/High-Risk | Medium | Non-compliant output |
| Internal-Knowledge | None | Confidentiality leaks |

## Architecture

```
agentspawn/
├── CLAUDE.md                                 # System prompt and operating rules
├── .claude/
│   ├── settings.json                         # Hook wiring
│   ├── skills/                               # One skill per pipeline phase
│   │   ├── classify/    interview/    research/    design/
│   │   └── build/       validate/     deliver/     memory-recall/
│   ├── agents/
│   │   ├── researcher.md                     # Background research (Sonnet, read-only)
│   │   └── evaluator.md                      # Eval execution (autonomous, isolated)
│   └── hooks/
│       ├── require-design-brief.sh           # Gate: design before build
│       ├── require-evals-before-delivery.sh  # Gate: evals before delivery
│       ├── check-user-level-budget.sh        # Context budget guard
│       ├── session-start-memory.sh           # Cross-session memory injection
│       └── pre-compact-backup.sh             # Memory persistence before compaction
├── templates/                                # Scaffolding for generated agent files
├── reference/                                # Failure taxonomy, knowledge architecture
└── generated-agents/                         # Pipeline output
```

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI

## License

MIT
