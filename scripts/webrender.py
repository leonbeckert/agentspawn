#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["playwright==1.64.1"]
# ///
"""Stateless, parallel-safe page fetcher for research agents.

Each invocation launches its OWN headless Chromium, renders one URL, writes
text/HTML/screenshot to files, prints a JSON result to stdout, and exits.
No state is shared between invocations, so any number of agents can run it
concurrently — unlike the Playwright MCP server, whose single browser/tab is
shared by every agent in the session.

Usage:
  python3 scripts/webrender.py URL [--out DIR] [--format text|html|png|all]
                               [--timeout SECS] [--wait-until STATE]
                               [--no-cookie-dismiss]
  python3 scripts/webrender.py --selftest

Exit codes: 0 ok · 2 fetch/render failed (JSON error on stdout) · 3 bad usage.

Dependencies: the Playwright MCP server does NOT provide the Python library,
and agents call this with whatever `python3` is on PATH. If `playwright` isn't
importable, the script re-executes itself via `uv run --script`, which builds a
cached environment from the inline metadata above (pinned so the version
matches the Chromium build in the shared ms-playwright cache). A missing
Chromium is installed once on first launch failure.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time

BOOTSTRAP_ENV = "WEBRENDER_UV_BOOTSTRAPPED"


def ensure_playwright() -> None:
    """Re-exec under uv when the current interpreter lacks playwright."""
    try:
        import playwright  # noqa: F401
        return
    except ImportError:
        pass
    uv = shutil.which("uv") or next(
        (p for p in (os.path.expanduser("~/.local/bin/uv"), "/opt/homebrew/bin/uv")
         if os.access(p, os.X_OK)), None)
    if uv and not os.environ.get(BOOTSTRAP_ENV):
        os.environ[BOOTSTRAP_ENV] = "1"
        os.execv(uv, [uv, "run", "--quiet", "--script", os.path.abspath(__file__), *sys.argv[1:]])
    hint = ("install uv (https://docs.astral.sh/uv/) or run with a Python that has "
            "playwright==1.64.1" if not uv else "uv could not provide playwright")
    print(json.dumps({"ok": False, "error": f"python playwright unavailable: {hint}"},
                     ensure_ascii=False, indent=2))
    sys.exit(2)


def launch_chromium(p):
    """Launch headless Chromium, installing the pinned build once if it's missing."""
    try:
        return p.chromium.launch(headless=True)
    except Exception as e:
        if "Executable doesn't exist" not in str(e):
            raise
    subprocess.run([sys.executable, "-m", "playwright", "install", "chromium", "--only-shell"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    return p.chromium.launch(headless=True)

CONSENT_PATTERNS = re.compile(
    r"^(alle akzeptieren|akzeptieren|zustimmen|einverstanden|alles akzeptieren"
    r"|accept all|accept( cookies)?|i agree|agree|allow all|got it|ok(ay)?"
    r"|tout accepter|aceptar( todo)?|accetta( tutto)?)$",
    re.IGNORECASE,
)

UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
)


def slugify(url: str) -> str:
    slug = re.sub(r"^https?://", "", url)
    slug = re.sub(r"[^A-Za-z0-9.-]+", "-", slug).strip("-")
    return slug[:80] or "page"


def dismiss_cookie_banners(page) -> bool:
    """Best-effort click on a consent button, on the page and inside iframes."""
    clicked = False
    for frame in [page.main_frame, *page.frames]:
        try:
            buttons = frame.get_by_role("button")
            count = min(buttons.count(), 40)
            for i in range(count):
                btn = buttons.nth(i)
                label = (btn.inner_text(timeout=500) or "").strip()
                if CONSENT_PATTERNS.match(label):
                    btn.click(timeout=2000)
                    clicked = True
                    page.wait_for_timeout(800)
                    return clicked
        except Exception:
            continue
    return clicked


def fetch(url, out_dir, formats, timeout_s, wait_until, cookie_dismiss):
    from playwright.sync_api import sync_playwright

    os.makedirs(out_dir, exist_ok=True)
    base = os.path.join(out_dir, f"{slugify(url)}-{os.getpid()}")
    result = {"url": url, "ok": False, "files": {}}

    with sync_playwright() as p:
        browser = launch_chromium(p)
        context = browser.new_context(user_agent=UA, locale="de-DE", viewport={"width": 1440, "height": 2000})
        page = context.new_page()
        try:
            try:
                resp = page.goto(url, timeout=timeout_s * 1000, wait_until=wait_until)
            except Exception as nav_err:
                # PDFs and other downloads abort navigation in headless Chromium:
                # fall back to a plain request and save the bytes.
                api = context.request.get(url, timeout=timeout_s * 1000)
                if not api.ok:
                    raise nav_err
                ctype = api.headers.get("content-type", "")
                ext = ".pdf" if "pdf" in ctype else ".bin"
                path = base + ext
                with open(path, "wb") as f:
                    f.write(api.body())
                result.update(ok=True, kind="binary", http_status=api.status,
                              content_type=ctype, files={"binary": path},
                              hint="PDF? -> pdftotext -layout <datei> -")
                return result

            ctype = (resp.headers.get("content-type", "") if resp else "")
            if resp and ("pdf" in ctype or "octet-stream" in ctype):
                path = base + (".pdf" if "pdf" in ctype else ".bin")
                with open(path, "wb") as f:
                    f.write(resp.body())
                result.update(ok=True, kind="binary", http_status=resp.status,
                              content_type=ctype, files={"binary": path},
                              hint="PDF? -> pdftotext -layout <datei> -")
                return result

            if cookie_dismiss:
                result["cookie_banner_clicked"] = dismiss_cookie_banners(page)
            try:
                page.wait_for_load_state("networkidle", timeout=8000)
            except Exception:
                pass  # some pages never go idle; take what we have

            result.update(
                kind="page",
                http_status=resp.status if resp else None,
                final_url=page.url,
                title=page.title(),
            )
            if "text" in formats:
                text = page.inner_text("body")
                path = base + ".txt"
                with open(path, "w", encoding="utf-8") as f:
                    f.write(text)
                result["files"]["text"] = path
                result["text_chars"] = len(text)
            if "html" in formats:
                path = base + ".html"
                with open(path, "w", encoding="utf-8") as f:
                    f.write(page.content())
                result["files"]["html"] = path
            if "png" in formats:
                path = base + ".png"
                page.screenshot(path=path, full_page=True)
                result["files"]["png"] = path
            # An HTTP error page (404, 502 from an intercepting proxy, 403 bot
            # block) is a failed fetch, not content — files stay on disk for
            # inspection, but ok=false so callers can't mistake it for data.
            status = result.get("http_status")
            result["ok"] = status is None or status < 400  # None: non-HTTP scheme (data:)
            if not result["ok"]:
                result["error"] = f"HTTP status {status}"
            return result
        finally:
            browser.close()


def selftest() -> int:
    me = os.path.abspath(__file__)
    tmp = tempfile.mkdtemp(prefix="webrender-selftest-")
    failures = []

    # 1) Positive control: a data: URL must render and yield the exact text.
    r = subprocess.run([sys.executable, me, "data:text/html,<title>t1</title><p>alpha-content</p>",
                        "--out", tmp], capture_output=True, text=True)
    out = json.loads(r.stdout or "{}")
    if r.returncode != 0 or not out.get("ok"):
        failures.append(f"positive: exit {r.returncode}, out={r.stdout[:200]}")
    else:
        text = open(out["files"]["text"], encoding="utf-8").read()
        if "alpha-content" not in text:
            failures.append("positive: rendered text missing expected content")

    # 2) Negative control: an unreachable host must fail with exit 2, not fake data.
    r = subprocess.run([sys.executable, me, "https://does-not-exist.invalid/", "--out", tmp,
                        "--timeout", "10"], capture_output=True, text=True)
    if r.returncode != 2:
        failures.append(f"negative: expected exit 2, got {r.returncode}")

    # 3) Parallel probe: two concurrent invocations must not see each other's page.
    procs = []
    for tag in ("beta-one", "beta-two"):
        procs.append((tag, subprocess.Popen(
            [sys.executable, me, f"data:text/html,<p>{tag}</p>", "--out", tmp],
            stdout=subprocess.PIPE, text=True)))
    for tag, proc in procs:
        stdout, _ = proc.communicate(timeout=120)
        out = json.loads(stdout or "{}")
        text = open(out["files"]["text"], encoding="utf-8").read() if out.get("ok") else ""
        if tag not in text:
            failures.append(f"parallel: invocation for {tag!r} read wrong page: {text!r}")

    if failures:
        print("SELFTEST FAIL")
        for f in failures:
            print(" -", f)
        return 1
    print("SELFTEST PASS (3/3: positive, negative control, parallel isolation)")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("url", nargs="?")
    ap.add_argument("--out", default=None, help="output directory (default: new temp dir)")
    ap.add_argument("--format", default="text", help="comma list of text,html,png or 'all'")
    ap.add_argument("--timeout", type=int, default=45)
    ap.add_argument("--wait-until", default="domcontentloaded",
                    choices=["load", "domcontentloaded", "networkidle", "commit"])
    ap.add_argument("--no-cookie-dismiss", action="store_true")
    ap.add_argument("--selftest", action="store_true")
    args = ap.parse_args()
    ensure_playwright()

    if args.selftest:
        sys.exit(selftest())
    if not args.url:
        ap.print_usage(sys.stderr)
        sys.exit(3)

    formats = {"text", "html", "png"} if args.format == "all" else set(args.format.split(","))
    out_dir = args.out or tempfile.mkdtemp(prefix="webrender-")
    start = time.time()
    try:
        result = fetch(args.url, out_dir, formats, args.timeout, args.wait_until,
                       not args.no_cookie_dismiss)
        result["seconds"] = round(time.time() - start, 1)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        sys.exit(0 if result.get("ok") else 2)
    except Exception as e:
        print(json.dumps({"url": args.url, "ok": False, "error": f"{type(e).__name__}: {e}"},
                         ensure_ascii=False, indent=2))
        sys.exit(2)


if __name__ == "__main__":
    main()
