#!/usr/bin/env python3
"""SubagentStop gate for researcher subagents.

Blocks a researcher from finishing when its final message doesn't hand over
a real report. The contract (see .claude/agents/researcher.md): write the
full report to a file under research/, and end with the absolute path plus
a short executive summary. Observed failure 2026-08-27: three researchers
ended on a one-line status ("hit rate limits", "research complete") and the
entire report was lost — the caller only ever sees the final message.

Pass criteria (any):
  a) final message references an existing .md file of >= MIN_FILE_BYTES
     that contains the mandatory gap section ("Lücken & Failed Sources",
     "Keine" allowed as its content), or
  b) final message itself is >= MIN_SELF_CONTAINED_CHARS AND contains the
     gap section (self-contained report — legacy behavior), or
  c) final message contains a deliberate no-op marker line starting with
     "NO-REPORT:" (dry runs / hook tests / aborted assignments). A
     truncated status line can never accidentally produce this marker.

Loop safety: allow the stop when stop_hook_active is true (exactly one
forced retry); Claude Code additionally hard-caps at 8 continuations.
No external dependencies beyond python3 stdlib — a missing dependency must
never silently disarm this gate.
"""
import json
import os
import re
import sys

MIN_FILE_BYTES = 1000
MIN_SELF_CONTAINED_CHARS = 2000
# Anchored to a markdown heading (e.g. "## Lücken & Failed Sources"): a bare mention of
# "gaps" in prose or in an unrelated .md (CHANGELOG) must not satisfy the contract.
GAP_SECTION_RE = re.compile(r"(?im)^\s{0,3}#{1,6}\s+.*(l(ü|ue)cken|failed sources|gaps)")

REASON = (
    "Return contract not met: your final message is the ONLY thing the "
    "caller receives, and it contains neither a usable report file nor a "
    "full report. Do this now: (1) write your COMPLETE findings — every "
    "finding, source URL, source-strength label — to your report file "
    "under generated-agents/[agent-name]/research/ ; (2) end the report "
    "with the mandatory '## Lücken & Failed Sources' section listing every "
    "source you could not fetch (URL, why it failed, expected relevance, "
    "retry suggestion) — write 'Keine' if none; (3) reply with the "
    "absolute file path plus a 5-10 line executive summary. A partial "
    "report with marked gaps passes; a status line does not."
)


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        # Malformed payload: don't guess — allow, this gate only understands
        # the documented SubagentStop shape.
        return 0

    if payload.get("stop_hook_active"):
        return 0
    # Matcher in settings.json already filters, but stay defensive.
    if payload.get("agent_type") != "researcher":
        return 0

    msg = payload.get("last_assistant_message") or ""
    cwd = payload.get("cwd") or os.getcwd()

    # (c) deliberate no-op marker — must start a line, not appear mid-text
    if re.search(r"(?m)^\s*NO-REPORT:", msg):
        return 0

    # (a) any referenced .md file that exists, has substance, and carries
    # the mandatory gap section
    for candidate in re.findall(r"[\w~./\-]+\.md\b", msg):
        path = os.path.expanduser(candidate)
        if not os.path.isabs(path):
            path = os.path.join(cwd, path)
        try:
            if os.path.getsize(path) < MIN_FILE_BYTES:
                continue
            with open(path, encoding="utf-8", errors="replace") as fh:
                if GAP_SECTION_RE.search(fh.read()):
                    return 0
        except OSError:
            continue

    # (b) self-contained report in the message itself
    if len(msg) >= MIN_SELF_CONTAINED_CHARS and GAP_SECTION_RE.search(msg):
        return 0

    print(REASON, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
