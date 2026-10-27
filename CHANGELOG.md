# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Fixed
- `scripts/webrender.py` failed in every agent with `ModuleNotFoundError: playwright` (observed 2026-10-27): the skills invoke it with the `python3` on PATH, which has no Python Playwright — the system-wide Playwright **MCP** server only provides `mcp__playwright__*` tools, not the library, and researcher subagents are barred from the MCP anyway, so their only browser fallback was dead. Agents worked around it with ad-hoc venvs. The script now carries PEP 723 inline metadata (`playwright==1.64.1`, pinned to the Chromium build already in the shared ms-playwright cache) and, when `playwright` isn't importable, re-executes itself via `uv run --script` (loop-guarded; a JSON error with exit 2 if uv is missing). A missing Chromium build is installed once on first launch failure. Invocation is unchanged (`python3 scripts/webrender.py …`); README lists `uv` as a prerequisite, and the research skill and researcher agent tell agents not to build venvs for it. Verified from Homebrew `python3` without playwright: selftest 3/3, live fetch, simulated missing uv, and an empty browser cache
- Background researchers no longer lose their entire report to a one-line status message (observed 3x on 2026-08-27: rate limits or the turn budget cut them off, and the last status line became the return value). Handoff is now file-based: each researcher gets an explicit report path under `generated-agents/[agent-name]/research/` (already whitelisted by the design-brief gate), writes incrementally, and returns path + executive summary; `Write`/`Edit` are re-allowed for the researcher subagent (agent files stay blocked by `require-design-brief.sh`) and `maxTurns` raised 30→80. Enforced mechanically by a `SubagentStop` hook (`researcher-report-gate.py`, python3-stdlib only so a missing dependency can't disarm it) that blocks the stop unless the final message references a ≥1KB report file or is itself a full report, with `stop_hook_active` loop protection. Reports must end with a mandatory `## Lücken & Failed Sources` section (URL, failure reason, expected relevance, retry suggestion — "Keine" if none), also hook-enforced, so rate-limited or blocked but potentially high-relevance sources surface instead of vanishing; the research skill tells the orchestrator to re-fetch hoch-relevant gaps before design. Live-verified 2026-08-28 (probe researcher was blocked once and forced into compliance; 4 real reports all passed the contract)
- Researcher fan-out disabled (`disallowedTools: Agent`) after a live run where 3 researchers spawned 15 delegates: 5 stalled on the 600s watchdog, an orphaned delegate delivered its report into the void (parent already finished), general-purpose children bypassed the report gate, and the fleet exhausted the shared WebSearch pool — stalling the spawners' own sub-tasks. Parallelism is now the orchestrator's job (≤4 researchers, explicit per-task search budgets, notification-rescue duty in the research skill). Session WebSearch cap raised 200→500 via `CLAUDE_CODE_MAX_WEB_SEARCHES_PER_SESSION` (verified against docs, v2.1.212+), and researchers get budget-discipline rules: search only to discover, fetch primary sources directly, never pull large assets verbatim into context (the main watchdog-kill cause). Report gate gained a deliberate `NO-REPORT: <reason>` no-op escape (line-start match only — a truncated status line can never produce it). Round-2 live verification after restart: spawn block confirmed at tool-registration level (`Task`/`Agent` absent for researcher and its would-be children), NO-REPORT escape passed the gate cleanly, and 4 parallel researchers with explicit 20–25-search budgets all completed contract-compliant with zero stalls, zero fan-out, and budget headroom (one reported 12/25 used); researchers now must report their WebSearch usage in the final summary
- Parallel research agents no longer fight over the session's single Playwright MCP browser (they replaced each other's pages mid-read, observed 2026-08-26). Three layers: `scripts/webrender.py` — a stateless fetcher that launches its own headless Chromium per invocation (parallel-safe, JSON output, PDF passthrough, cookie-banner dismissal, selftest incl. parallel-isolation probe); a PreToolUse lease hook (`playwright-lock.sh`/`.py`) that serializes any remaining `mcp__playwright__*` use per session with a TTL lease, fails closed on missing python3/unreadable payload/unidentifiable caller, and logs every decision for verifying the transcript-path-as-identity assumption; and an updated fetch ladder in the research/design skills plus `mcp__playwright` disallowed for the researcher subagent

### Changed
- Delivery eval gate (`require-evals-before-delivery.sh`) no longer depends on the filename `test-cases.md` (agents built in another language name their suite differently), but it now requires a real result instead of the bare word: an outcome token (PASS/FAIL/BESTANDEN/FEHLGESCHLAGEN, capitals) inside a `## Results` / `## Ergebnisse` section of any `evals/*.md`, or a table cell that is exactly that token. Prose like "PASS criteria" in a case definition no longer unlocks delivery; each file is checked on its own. The validate skill documents this result form
- Validate skill: sandbox-first section for agents that write their own state (snapshot every writable path and the read surface, restore between cases, one evaluator pass per workspace, verify headline findings against the current tree) and two structural checks: an instruction-only gate is not a gate (use a `Stop` hook and count its invocations), and every gate must be reachable under the agent's deployed permissions
- Opus-only policy pins the `opus` alias instead of a full model id, so pins never go stale. agentspawn's own `.claude/settings.json` moves from `claude-opus-4-8` to `opus` for both `model` and `env.CLAUDE_CODE_SUBAGENT_MODEL`, and the build skill now requires every generated workspace to write the same `env.CLAUDE_CODE_SUBAGENT_MODEL` block (previously only `model` was set, so fan-out subagents took the model from the launching shell) and `model: opus` in agent frontmatter, never a full id

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
