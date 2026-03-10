#!/bin/bash
# SessionStart hook: inject project memory context at session start.
# Reads the memory index and lists recent sessions so Claude knows what's happened before.

MEMORY_FILE="$CLAUDE_PROJECT_DIR/.claude/memory/MEMORY.md"
SESSIONS_DIR="$CLAUDE_PROJECT_DIR/.claude/memory/sessions"

# If no memory file exists yet, nothing to inject
if [[ ! -f "$MEMORY_FILE" ]]; then
  exit 0
fi

# Check if memory has any real content (not just the empty template)
if grep -q "(none" "$MEMORY_FILE" && ! ls "$SESSIONS_DIR"/*.md &>/dev/null; then
  exit 0
fi

# Read the memory index (capped at 200 lines)
MEMORY=$(head -200 "$MEMORY_FILE")

# Get the 3 most recent session summary filenames for awareness
RECENT_FILES=""
if [[ -d "$SESSIONS_DIR" ]]; then
  RECENT_FILES=$(ls -t "$SESSIONS_DIR"/*.md 2>/dev/null | head -3)
fi

# Build context injection
OUTPUT="## Project Memory\n$MEMORY"

if [[ -n "$RECENT_FILES" ]]; then
  OUTPUT="$OUTPUT\n\n## Recent Session Files (use memory-recall skill for details)"
  while IFS= read -r filepath; do
    filename=$(basename "$filepath" .md)
    # Extract the objective line from each summary
    objective=$(grep -A1 "^## Objective" "$filepath" 2>/dev/null | tail -1 | head -c 120)
    if [[ -n "$objective" ]]; then
      OUTPUT="$OUTPUT\n- $filename: $objective"
    else
      OUTPUT="$OUTPUT\n- $filename"
    fi
  done <<< "$RECENT_FILES"
fi

echo -e "$OUTPUT"
exit 0
