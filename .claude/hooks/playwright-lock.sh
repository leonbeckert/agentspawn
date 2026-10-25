#!/bin/bash
# PreToolUse guard for mcp__playwright__* — the Playwright MCP browser is a
# session-wide singleton; concurrent agents corrupt each other's pages.
# This wrapper fails CLOSED: if the real guard cannot run, the browser call
# is denied rather than waved through (exit 2 blocks the tool call).

payload="$(cat)"

if ! command -v "${PLAYWRIGHT_LOCK_PYTHON:-python3}" >/dev/null 2>&1; then
  echo "playwright-lock: python3 nicht gefunden — Browserzugriff vorsorglich verweigert (fail closed). Nutze stattdessen WebFetch oder scripts/webrender.py." >&2
  exit 2
fi

printf '%s' "$payload" | "${PLAYWRIGHT_LOCK_PYTHON:-python3}" "$(cd "$(dirname "$0")" && pwd)/playwright-lock.py"
exit $?
