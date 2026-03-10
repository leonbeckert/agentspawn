#!/bin/bash
# PreCompact hook: remind Claude to persist important context before compaction.
# Compaction is lossy — anything not written to disk may be lost.

INPUT=$(cat)
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "auto"')

# Only act on auto-compaction (manual /compact is intentional)
if [[ "$TRIGGER" != "auto" ]]; then
  exit 0
fi

# Check if there are any session files already (if so, Claude is likely maintaining memory)
SESSIONS_DIR="$CLAUDE_PROJECT_DIR/.claude/memory/sessions"
SESSION_COUNT=$(ls "$SESSIONS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')

cat <<'REMINDER'
Context is about to be compacted. Before continuing:

1. If you have unsaved decisions, task progress, or important findings from this session, write a session summary to .claude/memory/sessions/ now.
2. Update .claude/memory/MEMORY.md if active threads or agent status has changed.
3. After compaction, re-read .claude/memory/MEMORY.md to restore context.

Compaction preserves CLAUDE.md but compresses conversation history. Anything not on disk may be lost.
REMINDER

exit 0
