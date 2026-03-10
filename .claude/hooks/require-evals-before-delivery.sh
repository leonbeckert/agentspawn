#!/bin/bash
# PreToolUse hook: blocks writing delivery artifacts unless eval results exist.
# Delivery artifacts are MAINTENANCE.md and README.md in generated-agents/.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only gate files in generated-agents/
if [[ "$FILE_PATH" != *"generated-agents/"* ]]; then
  exit 0
fi

# Only block delivery-phase files
BASENAME=$(basename "$FILE_PATH")
if [[ "$BASENAME" != "MAINTENANCE.md" ]] && [[ "$BASENAME" != "README.md" ]]; then
  exit 0
fi

# Extract the agent directory
AGENT_DIR=$(echo "$FILE_PATH" | sed -n 's|\(.*generated-agents/[^/]*/\).*|\1|p')

if [[ -z "$AGENT_DIR" ]]; then
  exit 0
fi

# Block if no test-cases.md exists
if [[ ! -f "${AGENT_DIR}evals/test-cases.md" ]]; then
  echo "Blocked: No eval results found at ${AGENT_DIR}evals/test-cases.md. Run /validate before /deliver." >&2
  exit 2
fi

exit 0
