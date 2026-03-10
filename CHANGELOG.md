# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

## [0.1.0] - 2026-03-09

### Added
- 7-phase agent engineering pipeline: classify, interview, research, design, build, validate, deliver
- Hook-enforced gates: design-before-build, evals-before-delivery
- Context budget guard for user-level agents (warn at 5, block at 10)
- Persistent memory system with session summaries and cross-session recall
- Researcher subagent (Sonnet, background, read-only)
- Evaluator subagent (read-only, strict scoring)
- Three deployment targets: standalone workspace, project subagent, user-level agent
- Templates for CLAUDE.md, skills, eval suites, session summaries, maintenance models
- Reference material: failure taxonomy, knowledge architecture, source index
- Pre-compact transcript backup hook
