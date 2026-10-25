---
name: research
description: Gather domain knowledge for the agent being built. Intensity depends on agent type — from no research (internal-knowledge) to deep parallel research (analytical). Use after the interview phase.
---

# Research Phase

Gather the knowledge the agent needs. Research intensity was determined during classification.

## When to Research Deeply (Analytical/Research, some Creative)

Use the **researcher subagent** for parallel investigation. Launch separate research tasks for:
- Market data, trends, adoption rates, key statistics
- Competitor analysis, pricing, positioning
- Best practices, proven frameworks, methodologies
- Legal/regulatory context
- The user's existing public presence

### Report handoff is file-based

Researchers hand over their work as files, not chat text — a background
agent's final message gets truncated to a status line far too easily
(rate limits, turn budget; observed 3x on 2026-08-27):

1. Before launching, create `generated-agents/[agent-name]/research/`.
2. Give every researcher an **explicit absolute report path** in its task
   prompt, e.g. `.../research/de-vs-en-markt.md`. One file per researcher.
3. Researchers write incrementally; a `SubagentStop` hook
   (`researcher-report-gate.py`) blocks them from finishing without a
   usable report file or full report text.
4. After completion, **read the report files** — the return message is only
   path + executive summary. If a researcher died mid-run, its partial file
   still exists; check it before relaunching the whole task.
5. Every report ends with a mandatory `## Lücken & Failed Sources` section
   (sources that failed on rate limits, bot walls, paywalls — with expected
   relevance and a retry suggestion). Before moving to design, review these
   sections across all reports: re-fetch the hoch-relevant ones yourself
   (webrender.py, retry after cooldown, or ask the user for access) or
   carry them into the design brief as known gaps.

### Fan-out and budget rules (learned 2026-08-28)

- **Researchers work alone — they must not spawn subagents** (frontmatter
  disallows it). Observed failure: 3 researchers fanned out into 18 agents,
  exhausted the shared WebSearch pool, stalled 5 delegates on the 600s
  watchdog, and one orphaned delegate delivered its report into the void
  because its parent had already finished. Parallelism = more researchers
  launched by YOU, each with a narrow topic.
- **WebSearch is one shared pool per session** (default 200; agentspawn
  sets 500 via `CLAUDE_CODE_MAX_WEB_SEARCHES_PER_SESSION` in settings.json;
  a capped call silently returns nothing). Launch at most ~4 researchers in
  parallel and state an explicit search budget in each task prompt (e.g.
  "max. 25 WebSearch-Aufrufe; danach nur noch direkte WebFetches"). Search
  discovers sources; fetching primary domains does the actual work.
- **If a researcher dies or stalls** (watchdog kill, rate limit), its
  incremental report file survives — read it before relaunching, and
  relaunch with a narrower remit covering only what's missing.
- **If a completed agent's report arrives only as message text** (e.g. an
  orphaned delegate's task notification), persist it into `research/`
  yourself immediately — notifications are not storage.

## When to Research Lightly (Operational, Internal-Knowledge)

- Search for established patterns and conventions in the domain
- Check for regulatory requirements
- Look for prior art (templates, checklists, decision trees)
- Most context comes from the user's own files, not the web

## When NOT to Research Externally

- The agent is powered entirely by private context (SOPs, codebase, CRM)
- The domain is so specialized that public sources are noise
- The user has already provided comprehensive input

## Fetch Strategy (web research)

When gathering live web data, during this phase or in any generated agent that
reads the web:

1. Try `WebFetch` first — fast and cheap. PDFs: WebFetch reports binary
   content but still saves the file to the session directory — extract with
   `pdftotext -layout <file> -`.
2. If a page is blocked (bot protection, JS rendering, cookie wall), use
   `python3 scripts/webrender.py <URL> --out <dir>` — it launches its **own
   headless browser per invocation** and prints JSON with the saved file
   paths. This is the ONLY browser fallback for parallel subagents.
3. **Playwright MCP** (`mcp__playwright__*`) only for genuinely interactive
   flows (logins, multi-step clicking) — and only from the main loop, one
   user at a time. The session browser is a **shared singleton**: parallel
   agents navigating it replace each other's pages and read wrong content
   (observed 2026-08-26). A PreToolUse lease hook
   (`.claude/hooks/playwright-lock.sh`) denies concurrent use; researcher
   subagents have the MCP disallowed outright.
4. If every rung fails, note the gap — don't fabricate.

Any **generated agent** that consumes live web data should be designed with
the same ladder: give it a stateless per-invocation fetcher script (copy or
adapt `scripts/webrender.py`) rather than a shared MCP browser wherever the
agent may run work in parallel, and state the WebFetch → script → (serial,
interactive-only) browser escalation in its CLAUDE.md.

## Private Context Ingestion

For agents that rely on private documents:

### Step 1: Artifact Intake

Ask the user to share source materials. For each, classify:

| Artifact | Type | Confidentiality | Volatility | Use In Agent |
|---|---|---|---|---|
| [name] | SOP / Policy / Template / Log / Transcript | Internal-only / Redactable / Public | Stable / Quarterly / Monthly | CLAUDE.md / guide.md / skill / template |

### Step 2: Extract, Don't Dump

Don't copy-paste raw documents. Extract:
- Decision rules and branching logic
- Domain vocabulary and definitions
- Conventions and formatting requirements
- Edge cases and exceptions
- Explicit constraints and prohibitions

### Step 3: Mark Confidentiality Boundaries

```
What the agent may include in outputs:
- [list]

What the agent may use as context but NOT include in outputs:
- [list]

What the agent must NEVER reference:
- [list]
```

### Step 4: Source-of-Truth Precedence

For agents with multiple knowledge sources, define which wins when they conflict:

```
Source-of-truth precedence (highest to lowest):
1. [e.g., Current regulation text > internal policy > guide.md > general knowledge]
2. [e.g., Client brief > brand guidelines > skill defaults]

When sources conflict: flag the conflict, state which source you're following and why.
```

Essential for regulated and internal-knowledge agents. Usually unnecessary for creative agents.

## Source Strength (Analytical/Research agents)

Classify each piece of information by reliability:

| Strength | Definition | Use In Output |
|---|---|---|
| **Evidence** | Primary data, official statistics, regulation text | Can support output claims directly |
| **Orientation** | Industry reports, expert opinion, case studies | Context and framing, not hard claims |
| **Heuristic** | Community practice, rules of thumb, anecdotes | Background only — always hedge |

Mark source strength in guide.md so the agent distinguishes what supports a claim from what merely informed the framing.

## Research Rules

- Every factual claim in guide.md needs a source URL (for web-researched content)
- Private/internal content should note its origin and date
- Prefer primary sources over blog aggregators
- If you can't find data, note the gap — don't fabricate

## Research Checkpoints

After research, BEFORE moving to design:
- **Does research invalidate any interview assumptions?** If yes, re-interview.
- **Are there domain constraints you didn't ask about?** If yes, ask now.
- **Is the agent type still correct?** Reclassify if needed.
