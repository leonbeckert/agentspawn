#!/bin/bash
# PreToolUse hook: blocks agent file writes unless design-brief.md exists AND
# the user has approved it (indicated by .design-approved sentinel file).
#
# Flow:
# 1. Agent writes design-brief.md → allowed (this file is always writable)
# 2. Agent presents design to user, user says "build it"
# 3. Agent creates .design-approved → allowed (sentinel is writable if brief exists)
# 4. Agent writes CLAUDE.md, skills, etc. → allowed (both brief and approval exist)
#
# Without .design-approved, the agent can only write the design brief itself.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Allow if not writing to an agent output location
if [[ "$FILE_PATH" != *"generated-agents/"* ]] && [[ "$FILE_PATH" != *".claude/agents/"* ]] && [[ "$FILE_PATH" != *".claude/skills/"* ]]; then
  exit 0
fi

# Allow writing design-brief.md itself (the design phase needs to create this)
if [[ "$(basename "$FILE_PATH")" == "design-brief.md" ]]; then
  exit 0
fi

# Allow writing evals/test-cases.md (evals can be written alongside design)
if [[ "$(basename "$FILE_PATH")" == "test-cases.md" ]] && [[ "$FILE_PATH" == *"/evals/"* ]]; then
  exit 0
fi

# For generated-agents/ paths, check for BOTH design-brief.md AND .design-approved
if [[ "$FILE_PATH" == *"generated-agents/"* ]]; then
  AGENT_DIR=$(echo "$FILE_PATH" | sed -n 's|\(.*generated-agents/[^/]*/\).*|\1|p')
  if [[ -n "$AGENT_DIR" ]]; then
    # Gate 1: design brief must exist
    if [[ ! -f "${AGENT_DIR}design-brief.md" ]]; then
      echo "Blocked: No design brief found at ${AGENT_DIR}design-brief.md. Complete the design phase first." >&2
      exit 2
    fi

    # Allow creating .design-approved sentinel (if brief exists)
    if [[ "$(basename "$FILE_PATH")" == ".design-approved" ]]; then
      exit 0
    fi

    # Gate 2: user must have approved the design
    if [[ ! -f "${AGENT_DIR}.design-approved" ]]; then
      echo "Blocked: Design brief exists but user has not approved it yet. Present the design brief to the user and wait for explicit approval. When approved, create ${AGENT_DIR}.design-approved to proceed." >&2
      exit 2
    fi
  fi
fi

# For .claude/agents/ or .claude/skills/ paths (project/user subagent deployment),
# check if a design-approved sentinel exists in generated-agents/
if [[ "$FILE_PATH" == *".claude/agents/"* ]] || [[ "$FILE_PATH" == *".claude/skills/"* ]]; then
  APPROVED=$(find "$CLAUDE_PROJECT_DIR/generated-agents" -name ".design-approved" 2>/dev/null)
  if [[ -z "$APPROVED" ]]; then
    echo "Blocked: No approved design brief found in generated-agents/. Complete the design phase and get user approval before writing agent files." >&2
    exit 2
  fi
fi

exit 0
