#!/bin/bash
# PreToolUse hook: checks context budget before writing user-level agents or skills.
# Warns at 5+ user-level agents, blocks at 10+.
# Each user-level agent's description loads into EVERY Claude Code session on this machine.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only check writes to user-level agent/skill directories
USER_AGENTS="$HOME/.claude/agents"
USER_SKILLS="$HOME/.claude/skills"

if [[ "$FILE_PATH" != "$USER_AGENTS"/* ]] && [[ "$FILE_PATH" != "$USER_SKILLS"/* ]]; then
  exit 0
fi

# Count existing user-level agents (only .md files in agents/)
AGENT_COUNT=0
if [[ -d "$USER_AGENTS" ]]; then
  AGENT_COUNT=$(find "$USER_AGENTS" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
fi

# Count existing user-level skills (directories in skills/)
SKILL_COUNT=0
if [[ -d "$USER_SKILLS" ]]; then
  SKILL_COUNT=$(find "$USER_SKILLS" -maxdepth 1 -type d 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
fi

# Block at 10+ agents — user-level is not the right target at this scale
if [[ "$FILE_PATH" == "$USER_AGENTS"/* ]] && [[ "$AGENT_COUNT" -ge 10 ]]; then
  cat >&2 <<MSG
Blocked: $AGENT_COUNT user-level agents already exist in ~/.claude/agents/.
Each agent description loads into EVERY Claude Code session, consuming context tokens.
At 10+ agents, delegation accuracy degrades and context overhead becomes significant.

Consider instead:
- Project subagent: deploy to specific projects via .claude/agents/ in each project
- Multi-project subagent: build once in generated-agents/, symlink to target projects
- Review existing user-level agents: remove any that aren't used across all projects

Existing agents: $(ls "$USER_AGENTS"/*.md 2>/dev/null | xargs -I{} basename {} .md | tr '\n' ', ')
MSG
  exit 2
fi

# Warn at 5+ agents (don't block, just inform)
if [[ "$FILE_PATH" == "$USER_AGENTS"/* ]] && [[ "$AGENT_COUNT" -ge 5 ]]; then
  cat >&2 <<MSG
Warning: $AGENT_COUNT user-level agents already exist in ~/.claude/agents/.
Each loads into every session. Consider whether this agent truly needs to be available everywhere.
Alternatives: project subagent (one project) or multi-project subagent (symlinks to specific projects).
MSG
  # Exit 0 — warn but don't block
  exit 0
fi

exit 0
