# Contributing

Contributions are welcome. agentspawn is a Claude Code meta-agent — the "source code" is markdown and shell scripts that define agent behavior.

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). Be respectful.

## Reporting Bugs

[Open a bug report](../../issues/new?template=1-bug-report.yml). Include:
- What you asked agentspawn to build
- What phase failed
- The error or unexpected behavior

## Suggesting Features

[Open a feature request](../../issues/new?template=2-feature-request.yml).

## Development Setup

```bash
git clone https://github.com/leonbeckert/agentspawn.git
cd agentspawn
claude
```

No dependencies to install. The project runs entirely inside Claude Code.

## Project Structure

| Directory | What | When to modify |
|---|---|---|
| `CLAUDE.md` | agentspawn operating rules | Changing phase order, process rules, memory management |
| `.claude/skills/` | Phase logic (one skill per phase) | Changing how a phase works |
| `.claude/agents/` | Subagent definitions (researcher, evaluator) | Changing subagent behavior or adding new ones |
| `.claude/hooks/` | Gate enforcement scripts | Changing what gets blocked and when |
| `templates/` | Scaffolding for generated agents | Changing output structure |
| `reference/` | Failure taxonomy, knowledge architecture | Adding failure classes or knowledge patterns |

## Making Changes

1. Fork and create a branch
2. Make your changes
3. Test by running agentspawn on a sample agent request
4. Open a pull request with a description of what changed and why

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add new agent type classification
fix: correct hook path resolution for user-level agents
docs: clarify deployment target selection
chore: update failure taxonomy reference
```

## What Makes a Good Contribution

- **New failure classes** in `reference/failure-taxonomy.md` — with examples and prevention mechanisms
- **Skill improvements** — better examples, clearer templates, edge case handling
- **Hook enhancements** — new gate enforcement or validation logic
- **Bug fixes** — especially in hooks and skill workflows

## What to Avoid

- Adding features agentspawn doesn't need yet
- Changing the phase order without strong justification
- Removing gate enforcement
