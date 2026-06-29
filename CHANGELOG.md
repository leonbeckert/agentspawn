# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- Update checker (`check-for-updates.sh` SessionStart hook) — notifies when the checkout is behind `origin/main`, with opt-in auto fast-forward via `AGENTSPAWN_AUTO_UPDATE=1`. Network fetch runs detached on a 6h timer so it never blocks session start; the "behind" count is recomputed from local refs each session; auto-apply is guarded by a clean tree + true fast-forward, and it fails open when offline or off `main`
- README **Setup** section documenting prerequisites: Claude Code (required) and Playwright MCP (recommended, with install commands) so agents have browser tools for blocked/JS-rendered sites
- README **Troubleshooting** section — most issues are fixable by asking Claude Code to read and repair its own skills/hooks/scripts in-session, with example prompts and a pointer to `claude doctor` / the official troubleshooting guide for Claude Code itself
- README **Install Claude Code** table covering all install methods — native installer (macOS/Linux/WSL/Windows), Homebrew, npm, WinGet, Linux package managers, and the Desktop app — each with the exact command and a link to the official guide, plus the plan/account requirement
- Fetch-strategy guidance in the research and design skills — agents that read live web data are now designed with a `WebFetch` → Playwright fallback
- Project session defaults in `.claude/settings.json` `env` block — `CLAUDE_CODE_SUBAGENT_MODEL=claude-opus-4-8`, `CLAUDE_CODE_AUTO_COMPACT_WINDOW=400000`, `CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING=true` — applied to every agentspawn session for all users (launcher or plain `claude`). Skip-permissions stays an opt-in per-launch choice
- macOS Dock launchers: `scripts/make-launcher.sh` builds a one-click `.app` that opens a terminal (iTerm2 → Ghostty → Terminal.app, auto-detected), `cd`s into a project, and starts a session. Standalone agents are offered a launcher in the deliver phase, each with a uniquely colored icon
- `scripts/gen-icon.js` — dependency-free app-icon generator (macOS JXA/Cocoa; no ImageMagick/Pillow)
- Multi-project subagent deployment target with `deploy.sh` symlink strategy
- Session memory system with `memory-recall` skill for cross-session context
- `pre-compact-backup.sh` hook for transcript persistence before compaction
- Self-improvement audit with findings documented in `memory/topics/`

### Changed
- Opus-only policy: all agents and subagents must use `claude-opus-4-8`
- Design-brief hook now scopes approval checks per-agent via `.building` marker
- Eval gate now verifies `test-cases.md` contains PASS/FAIL results, not just file existence
- Clarified validate skill: parent agent writes eval results, not the evaluator subagent

### Fixed
- **Prime Directive against solving problems directly** — agentspawn was treating a bare problem description as work to do (researching/answering it) instead of a request to build an agent. Added an absolute "Build Agents, Never Do the Work" rule to `CLAUDE.md`, a "What You Are NOT → not a problem-solver" entry, and a reframing step at the top of the classify skill so the user never has to say "build an agent" to prevent direct problem-solving. Backed by a soft `nudge-build-not-solve.sh` PreToolUse hook (WebFetch/WebSearch) that surfaces a one-time, self-clearing per-session reminder when web research starts
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
