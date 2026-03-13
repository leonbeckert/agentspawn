# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- Multi-project subagent deployment target with `deploy.sh` symlink strategy
- Session memory system with `memory-recall` skill for cross-session context
- `pre-compact-backup.sh` hook for transcript persistence before compaction
- Self-improvement audit with findings documented in `memory/topics/`

### Changed
- Opus-only policy: all agents and subagents must use `claude-opus-4-6`
- Design-brief hook now scopes approval checks per-agent via `.building` marker
- Eval gate now verifies `test-cases.md` contains PASS/FAIL results, not just file existence
- Clarified validate skill: parent agent writes eval results, not the evaluator subagent

### Fixed
- Broken symlink in `docs/oss-namer-guide.md` pointing to old `agent-factory` repo name
- README and CHANGELOG incorrectly listed researcher subagent as "Sonnet" (was always Opus)

## [0.1.0] - 2026-03-09

### Added
- 7-phase agent engineering pipeline: classify, interview, research, design, build, validate, deliver
- Hook-enforced gates: design-before-build, evals-before-delivery
- Context budget guard for user-level agents (warn at 5, block at 10)
- Persistent memory system with session summaries and cross-session recall
- Researcher subagent (Opus, background, read-only)
- Evaluator subagent (read-only, strict scoring)
- Three deployment targets: standalone workspace, project subagent, user-level agent
- Templates for CLAUDE.md, skills, eval suites, session summaries, maintenance models
- Reference material: failure taxonomy, knowledge architecture, source index
- Pre-compact transcript backup hook
