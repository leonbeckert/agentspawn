#!/bin/bash
# PreToolUse hook (WebFetch|WebSearch): soft nudge enforcing the Prime Directive
# — agentspawn builds agents, it does not solve the user's problem directly.
#
# Web research at the very start of a session is the danger zone: it usually means
# Claude is about to ANSWER the user's problem instead of building an agent for it.
# This hook surfaces a one-time reminder so Claude reconsiders the framing.
#
# Design — deliberately soft, not a hard gate:
# - Fires at most ONCE per session. The block is self-clearing: after the reminder,
#   re-issuing the same call proceeds. So legitimate Research-phase work loses at
#   most one round-trip; it is never permanently blocked.
#
# Note: we intentionally do NOT skip based on existing design briefs — a populated
# generated-agents/ always has them, which would suppress the nudge entirely. The
# once-per-session limit is what keeps it from nagging.

INPUT=$(cat)

# Once-per-session marker, keyed by session id, so this never nags twice.
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
MARKER_DIR="${TMPDIR:-/tmp}/agentspawn-nudge"
mkdir -p "$MARKER_DIR" 2>/dev/null
MARKER="$MARKER_DIR/$SESSION_ID"
if [[ -f "$MARKER" ]]; then
  exit 0
fi
: > "$MARKER" 2>/dev/null

# First web research of the session, no agent in progress → nudge once.
cat >&2 <<'MSG'
⚠ agentspawn Prime Directive check — Build agents, don't solve problems directly.

You're about to do web research. If this lookup is meant to ANSWER the user's
problem, STOP — that is the agent's job, not yours. Reframe the request as an agent
to build and enter the Classify phase.

If this IS legitimate Research-phase work for an agent you are already building
(past classification and interview), just re-issue the call to proceed. This
reminder fires only once per session and will not block you again.
MSG
exit 2
