# Sources & Influences

Research and references that informed agentspawn's design.

## Anthropic Official

- [Building Effective Agents](https://www.anthropic.com/research/building-effective-agents) — Start simple, tool design > prompt engineering
- [Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — Smallest set of high-signal tokens, progressive disclosure
- [Writing Tools for Agents](https://www.anthropic.com/engineering/writing-tools-for-agents) — Ergonomics, consolidation, high-signal returns
- [Effective Harnesses](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) — File-based state, progress docs, single-feature sessions
- [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices) — Verification is highest-leverage
- [Skill Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) — Degrees of freedom, evaluation before documentation
- [Prompting Best Practices](https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/claude-prompting-best-practices) — Normal language, tell what TO do, explain why
- [Claude Code Memory](https://code.claude.com/docs/en/memory) — CLAUDE.md is context, not enforcement; target <200 lines
- [Claude Code Skills](https://code.claude.com/docs/en/skills) — Progressive disclosure, disable-model-invocation, skill directories
- [Claude Code Hooks](https://code.claude.com/docs/en/hooks-guide) — Deterministic enforcement, PreToolUse gates, Stop hooks
- [Claude Code Subagents](https://code.claude.com/docs/en/sub-agents) — Isolated context, tool restrictions, persistent memory

## Community

- [Boris Cherny](https://venturebeat.com/technology/the-creator-of-claude-code-just-revealed-his-workflow-and-developers-are) — Self-improving CLAUDE.md, plan-then-execute
- [GSD](https://github.com/gsd-build/get-shit-done) — Fresh context per executor, file-based state (25.5k stars)
- [Atlas/Mercury/Apollo](https://gist.github.com/RchGrav/438eafd62d58f3914f8d569769d0ebb3) — Quality-gated iteration, blackboard architecture
- [Anthropic Skill-Creator](https://github.com/anthropics/skills) — Dual-baseline benchmarking (86.4k stars)
- [Vercel Eval Data](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals) — Always-loaded context: 100% adherence, skills: 79%
- [HumanLayer](https://www.humanlayer.dev/blog/writing-a-good-claude-md) — "Never send an LLM to do a linter's job"
- [Trail of Bits](https://github.com/trailofbits/claude-code-config) — Opinionated hard limits
- [Self-Improving CLAUDE.md](https://github.com/aviadr1/claude-meta) — Reflection-then-write cycle
- [Claude Code Skill Factory](https://github.com/alirezarezvani/claude-code-skill-factory) — Project-directory agent factory pattern

## Eval & Observability

- [WorkOS Eval System](https://workos.com/) — Two-tier grading: functional (pass/fail) + quality (1-5 rubric)
- [promptfoo](https://promptfoo.dev/) — Declarative eval config, 28+ assertion types
- [Braintrust](https://braintrust.dev/) — Autoevals with Factuality/Similarity scoring
- [Langfuse](https://langfuse.com/) — Open-source LLM observability, prompt versioning
