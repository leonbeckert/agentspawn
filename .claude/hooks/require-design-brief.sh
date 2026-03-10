#!/bin/bash
# PreToolUse hook: blocks agent file writes unless a design-brief.md exists.
# This prevents agentspawn from skipping the design phase and jumping to build.
#
# For standalone agents: checks generated-agents/[name]/design-brief.md
# For project/user subagents: checks generated-agents/[name]/design-brief.md
#   (the design brief is always staged in generated-agents/ regardless of deployment target)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Allow if not writing to an agent output location
# We gate: generated-agents/, .claude/agents/, .claude/skills/, and docs/ prefixed with agent names
# But we can only reliably gate generated-agents/ since we know the pattern
if [[ "$FILE_PATH" != *"generated-agents/"* ]] && [[ "$FILE_PATH" != *".claude/agents/"* ]] && [[ "$FILE_PATH" != *".claude/skills/"* ]]; then
  exit 0
fi

# Allow writing design-brief.md itself (the design phase needs to create this)
if [[ "$(basename "$FILE_PATH")" == "design-brief.md" ]]; then
  exit 0
fi

# For generated-agents/ paths, check for design-brief.md in the agent directory
if [[ "$FILE_PATH" == *"generated-agents/"* ]]; then
  AGENT_DIR=$(echo "$FILE_PATH" | sed -n 's|\(.*generated-agents/[^/]*/\).*|\1|p')
  if [[ -n "$AGENT_DIR" ]] && [[ ! -f "${AGENT_DIR}design-brief.md" ]]; then
    echo "Blocked: No design brief found at ${AGENT_DIR}design-brief.md. Complete the design phase and get user approval before writing agent files. Use the design skill first." >&2
    exit 2
  fi
fi

# For .claude/agents/ or .claude/skills/ paths (project/user subagent deployment),
# check if ANY design-brief.md exists in generated-agents/
if [[ "$FILE_PATH" == *".claude/agents/"* ]] || [[ "$FILE_PATH" == *".claude/skills/"* ]]; then
  BRIEFS=$(find "$CLAUDE_PROJECT_DIR/generated-agents" -name "design-brief.md" 2>/dev/null)
  if [[ -z "$BRIEFS" ]]; then
    echo "Blocked: No design brief found in generated-agents/. Complete the design phase and get user approval before writing agent files. Use the design skill first." >&2
    exit 2
  fi
fi

exit 0
