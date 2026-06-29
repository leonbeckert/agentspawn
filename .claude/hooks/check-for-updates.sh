#!/bin/bash
# SessionStart hook: tell the user when agentspawn is behind its GitHub main, and
# (opt-in) fast-forward automatically when it's safe.
#
# Design goals — never slow down or break session start:
# - Network (git fetch) runs DETACHED in the background on a timer, so it adds no
#   startup latency and can't hang the session. The notice you see reflects the
#   last completed fetch (so it can be one session stale on first falling behind).
# - The "how far behind" number is recomputed from LOCAL refs every session, so it
#   is always accurate to the last fetch and drops to zero the moment you pull.
# - Fails open: not a git checkout, no origin, off main, offline, SSH not loaded —
#   all exit silently. An update check must never degrade session start.
#
# Auto-apply is OPT-IN and guarded. It only fast-forwards when ALL hold:
#   - env AGENTSPAWN_AUTO_UPDATE=1
#   - current branch is main
#   - working tree is clean (agentspawn's memory writes usually make it dirty, so
#     this rarely fires — by design; notify is the safe default)
#   - the update is a true fast-forward (no divergence)

set -u

PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"
INTERVAL=21600   # refresh at most once every 6h
FETCH_TIMEOUT=20 # seconds, bounds the background fetch

git() { command git -C "$PROJ" "$@"; }

# --- guards: only operate on a real checkout of main with an origin remote ------
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
git remote get-url origin >/dev/null 2>&1 || exit 0
[ "$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" = "main" ] || exit 0

GIT_DIR_PATH="$(git rev-parse --git-dir 2>/dev/null)" || exit 0
case "$GIT_DIR_PATH" in /*) ;; *) GIT_DIR_PATH="$PROJ/$GIT_DIR_PATH" ;; esac
STAMP="$GIT_DIR_PATH/agentspawn-update-check"

# --- display: compute "behind" from local refs (no network) ---------------------
if git rev-parse --verify --quiet origin/main >/dev/null 2>&1; then
  BEHIND="$(git rev-list --count HEAD..origin/main 2>/dev/null || echo 0)"
  if [ "${BEHIND:-0}" -gt 0 ]; then
    APPLIED=0
    if [ "${AGENTSPAWN_AUTO_UPDATE:-0}" = "1" ] \
       && [ -z "$(git status --porcelain 2>/dev/null)" ] \
       && git merge-base --is-ancestor HEAD origin/main 2>/dev/null; then
      if git merge --ff-only origin/main >/dev/null 2>&1; then
        echo "✓ agentspawn auto-updated: fast-forwarded $BEHIND commit(s) from origin/main."
        APPLIED=1
      fi
    fi
    if [ "$APPLIED" -eq 0 ]; then
      echo "⬆ agentspawn is $BEHIND commit(s) behind origin/main — run \`git pull --ff-only\` to update."
      echo "  (Set AGENTSPAWN_AUTO_UPDATE=1 to auto fast-forward when your working tree is clean.)"
    fi
  fi
fi

# --- refresh: background fetch on a timer (detached, bounded, fail-open) ---------
NOW="$(date +%s 2>/dev/null || echo 0)"
LAST="$(cat "$STAMP" 2>/dev/null || echo 0)"
case "$LAST" in ''|*[!0-9]*) LAST=0 ;; esac
if [ "$NOW" -ne 0 ] && [ $(( NOW - LAST )) -ge "$INTERVAL" ]; then
  echo "$NOW" > "$STAMP" 2>/dev/null
  TBIN=""
  if command -v timeout  >/dev/null 2>&1; then TBIN="timeout $FETCH_TIMEOUT"
  elif command -v gtimeout >/dev/null 2>&1; then TBIN="gtimeout $FETCH_TIMEOUT"; fi
  nohup bash -c "$TBIN command git -C '$PROJ' fetch --quiet origin main" >/dev/null 2>&1 &
fi

exit 0
