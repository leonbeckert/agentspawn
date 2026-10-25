#!/usr/bin/env python3
"""Lease lock for the shared Playwright MCP browser (called by playwright-lock.sh).

The Playwright MCP server is one browser per session, shared by the main loop
and every subagent. Tools operate on the *active* page, so two concurrent
users silently read each other's pages. This guard grants the browser to one
caller at a time:

- Owner identity = the hook payload's transcript_path (each agent has its own
  transcript file; the main loop has the session transcript). Fallback:
  session_id. Missing both -> deny (fail closed).
- The lease lives in $TMPDIR, keyed by session_id, with a TTL. Every call by
  the owner renews it; other callers are denied with guidance until it expires.
- Every decision is appended to a JSONL log next to the lock file so the
  identity assumption (distinct transcript_path per agent) can be verified
  against reality — see MAINTENANCE note in CLAUDE.md/skills.

Exit codes: 0 allow · 2 deny (stderr shown to the calling agent).
"""

from __future__ import annotations  # `float | None` on macOS /usr/bin/python3 (3.9) — else TypeError ⇒ exit 1 ⇒ call not blocked

import hashlib
import json
import os
import sys
import tempfile
import time

TTL_SECONDS = int(os.environ.get("PLAYWRIGHT_LOCK_TTL", "180"))


def lock_dir() -> str:
    return os.environ.get("PLAYWRIGHT_LOCK_DIR") or tempfile.gettempdir()


def deny(message: str) -> int:
    sys.stderr.write(message + "\n")
    return 2


def log_decision(path: str, record: dict) -> None:
    try:
        with open(path, "a", encoding="utf-8") as f:
            f.write(json.dumps(record, ensure_ascii=False) + "\n")
    except OSError:
        pass  # logging must never turn into a bypass or a crash


def decide(payload_raw: str, now: float | None = None) -> int:
    now = now or time.time()
    try:
        payload = json.loads(payload_raw)
    except (json.JSONDecodeError, TypeError):
        return deny("playwright-lock: Payload nicht lesbar — Browserzugriff verweigert (fail closed).")

    owner = payload.get("transcript_path") or payload.get("session_id")
    session = payload.get("session_id") or "global"
    if not owner:
        return deny(
            "playwright-lock: Aufrufer nicht identifizierbar (weder transcript_path noch "
            "session_id im Payload) — Browserzugriff verweigert (fail closed)."
        )

    key = hashlib.sha256(str(session).encode()).hexdigest()[:16]
    lock_path = os.path.join(lock_dir(), f"claude-playwright-lease-{key}.json")
    log_path = os.path.join(lock_dir(), f"claude-playwright-lease-{key}.log.jsonl")

    holder, held_ts = None, 0.0
    try:
        with open(lock_path, encoding="utf-8") as f:
            data = json.load(f)
        holder, held_ts = data.get("owner"), float(data.get("ts", 0))
    except (OSError, ValueError):
        pass  # no lock or unreadable lock -> treat as free (it gets rewritten below)

    expired = (now - held_ts) > TTL_SECONDS
    if holder is None or expired or holder == owner:
        tmp = lock_path + f".{os.getpid()}.tmp"
        try:
            with open(tmp, "w", encoding="utf-8") as f:
                json.dump({"owner": owner, "ts": now}, f)
            os.replace(tmp, lock_path)
        except OSError:
            return deny("playwright-lock: Lease-Datei nicht schreibbar — Browserzugriff verweigert (fail closed).")
        log_decision(log_path, {"ts": now, "decision": "allow", "owner": owner,
                                "tool": payload.get("tool_name"),
                                "took_over_expired": bool(holder and expired and holder != owner)})
        return 0

    remaining = int(TTL_SECONDS - (now - held_ts))
    log_decision(log_path, {"ts": now, "decision": "deny", "owner": owner, "holder": holder,
                            "tool": payload.get("tool_name")})
    return deny(
        "playwright-lock: Der Session-Browser ist gerade von einem anderen Agenten belegt "
        f"(Lease läuft in ≤{remaining}s ab). Den Playwright-MCP NICHT erneut versuchen. "
        "Stattdessen: (1) python3 scripts/webrender.py <URL> --out <dir> — eigener Browser "
        "pro Aufruf, parallel-sicher; (2) WebFetch; (3) wenn beides scheitert, die Quelle "
        "als LÜCKE markieren."
    )


def selftest() -> int:
    import shutil

    tmp = tempfile.mkdtemp(prefix="playwright-lock-selftest-")
    os.environ["PLAYWRIGHT_LOCK_DIR"] = tmp
    failures = []

    def payload(owner: str, session: str = "s1") -> str:
        return json.dumps({"transcript_path": owner, "session_id": session,
                           "tool_name": "mcp__playwright__browser_navigate"})

    t0 = time.time()
    # 1) Free lock -> first caller acquires.
    if decide(payload("/t/agent-A.jsonl"), now=t0) != 0:
        failures.append("acquire: expected allow")
    # 2) Same owner -> renew, allow.
    if decide(payload("/t/agent-A.jsonl"), now=t0 + 5) != 0:
        failures.append("renew: expected allow for holder")
    # 3) Other owner while held -> deny.
    if decide(payload("/t/agent-B.jsonl"), now=t0 + 10) != 2:
        failures.append("contention: expected deny for non-holder")
    # 4) After TTL expiry -> other owner takes over.
    if decide(payload("/t/agent-B.jsonl"), now=t0 + 10 + TTL_SECONDS + 1) != 0:
        failures.append("expiry: expected takeover after TTL")
    # 5) Malformed payload -> deny (fail closed).
    if decide("this is not json") != 2:
        failures.append("malformed: expected deny")
    # 6) No identity fields -> deny (fail closed).
    if decide(json.dumps({"tool_name": "mcp__playwright__browser_snapshot"})) != 2:
        failures.append("no-identity: expected deny")
    # 7) Counter-probe: with a DIFFERENT session, B is not blocked by A's lease
    #    (separate sessions have separate browsers — they must not serialize).
    if decide(payload("/t/agent-C.jsonl", session="s2"), now=t0 + 20) != 0:
        failures.append("cross-session: expected allow (independent browsers)")
    # 8) Probe of the probe: delete the enforcement (fresh dir), rerun contention —
    #    without a lease on disk the deny must NOT fire, proving case 3 tested
    #    the mechanism and not an accident.
    shutil.rmtree(tmp)
    os.makedirs(tmp)
    if decide(payload("/t/agent-B.jsonl"), now=t0) != 0:
        failures.append("control: deny fired with no lease present — case 3 proves nothing")

    if failures:
        print("SELFTEST FAIL")
        for f in failures:
            print(" -", f)
        return 1
    print("SELFTEST PASS (8/8: acquire, renew, contention, expiry, malformed, "
          "no-identity, cross-session, no-lease control)")
    return 0


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--selftest":
        sys.exit(selftest())
    sys.exit(decide(sys.stdin.read()))
