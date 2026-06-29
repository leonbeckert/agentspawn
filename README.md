# agentspawn

System that engineers production-grade AI agents. A 7-phase pipeline — classify, interview, research, design, build, validate, deliver — with hook-enforced quality gates and automated evaluation suites.

You describe what you need. agentspawn runs the full pipeline: classifies the agent type and complexity tier, interviews for requirements, researches the domain via a background subagent, produces a design brief for your approval, builds the agent files, validates against an eval suite, and delivers with usage instructions and a maintenance model.

Two phases are gate-enforced by shell hooks — the system cannot write agent files without an approved design brief, and cannot deliver without passing evals.

## Setup

### Prerequisites

- **[Claude Code](https://code.claude.com/docs/en/setup)** (required) — agentspawn
  runs entirely inside Claude Code. Install it with whichever method fits your
  platform (see below), then sign in. Claude Code needs a Claude **Pro, Max, Team,
  or Enterprise** plan or an **API/Console** account — the free Claude.ai plan does
  not include it.
- **Playwright MCP** (recommended) — gives generated agents (and the research
  phase) a real browser, so they can read JavaScript-rendered pages, dismiss
  cookie banners, and reach sites that block plain HTTP fetches. Without it,
  agents fall back to `WebFetch`, which fails on many modern sites.
- **macOS** — only required for the optional [Dock launcher](#dock-launcher-macos).

### Install Claude Code

Pick one method ([full install guide](https://code.claude.com/docs/en/setup)):

| Method | Platform | Command |
|---|---|---|
| **Native installer** (recommended) | macOS / Linux / WSL | `curl -fsSL https://claude.ai/install.sh \| bash` |
| **Native installer** | Windows PowerShell | `irm https://claude.ai/install.ps1 \| iex` |
| **Homebrew** | macOS / Linux | `brew install --cask claude-code` |
| **npm** (needs [Node 18+](https://nodejs.org/en/download)) | cross-platform | `npm install -g @anthropic-ai/claude-code` |
| **WinGet** | Windows | `winget install Anthropic.ClaudeCode` |
| **apt / dnf / apk** | Debian / Fedora / Alpine | [Linux package managers](https://code.claude.com/docs/en/setup#install-with-linux-package-managers) |
| **Desktop app** (GUI, no terminal) | macOS / Windows | [Download](https://code.claude.com/docs/en/desktop-quickstart) |

Then sign in by running `claude` and following the browser prompt. Verify with
`claude --version` or `claude doctor`.

### Add the Playwright browser tools (recommended)

```bash
claude mcp add playwright npx @playwright/mcp@latest
```

The server downloads its browser on first use. Restart Claude Code afterward so
the new tools load.

### Install agentspawn

```bash
git clone https://github.com/leonbeckert/agentspawn.git
cd agentspawn
claude
```

Then describe what you need:

```
> I need an agent that [your use case]
```

agentspawn ships sensible session defaults (Opus subagents, large auto-compact
window) via `.claude/settings.json`, so every user gets the same behavior with no
extra configuration. Optionally, add a one-click [Dock launcher](#dock-launcher-macos):

```bash
scripts/make-launcher.sh AgentSpawn "$(pwd)"
```

### Staying updated

A SessionStart hook checks whether your checkout is behind `origin/main` and, if so,
prints a one-line notice — e.g. _"agentspawn is 3 commit(s) behind origin/main — run
`git pull --ff-only`"_. The check is non-blocking: the network fetch runs detached in
the background (at most once every 6h), so it never slows down or hangs session start,
and it fails silently when offline or off `main`.

To update, run `git pull --ff-only`. To have agentspawn fast-forward **automatically**
when it's safe, set `AGENTSPAWN_AUTO_UPDATE=1`. Auto-apply only happens on a clean
working tree and a true fast-forward — so it won't clobber local changes or your
generated agents and memory. (Because the memory system writes on most sessions, the
tree is often dirty and it simply falls back to the notice.)

## Pipeline

| Phase | What | Your role |
|---|---|---|
| **Classify** | Agent type (Creative, Analytical, Operational, Regulated, Internal-Knowledge) + complexity tier (1-3) | Confirm |
| **Interview** | Structured discovery — 2-3 rounds shaped by agent type | Answer |
| **Research** | Domain knowledge via researcher subagent (background, read-only) | Review |
| **Design** | Design brief: failure taxonomy, skill plan, knowledge architecture | **Approve** |
| **Build** | Agent files — you invoke `/build` | Invoke |
| **Validate** | Eval suite via evaluator subagent — hard gates + scored dimensions | Review |
| **Deliver** | Usage instructions + maintenance model — you invoke `/deliver` | Invoke |

## Quality Gates

Shell hooks intercept tool calls and enforce phase ordering at runtime:

| Hook | What it enforces |
|---|---|
| `require-design-brief.sh` | Blocks writes to agent directories unless `design-brief.md` exists |
| `require-evals-before-delivery.sh` | Blocks delivery artifacts unless eval results exist |
| `check-user-level-budget.sh` | Warns at 5, blocks at 10 user-level agents (context budget guard) |
| `nudge-build-not-solve.sh` | One-time per-session reminder on web research — build an agent, don't solve the problem directly |

`/build` and `/deliver` require manual invocation — the system cannot auto-invoke them.

## Output

The pipeline produces Claude Code native files:

| File | Purpose |
|---|---|
| Agent definition (`.md`) | System prompt — identity, constraints, forbidden outputs, ambiguity strategy |
| Skills (`SKILL.md`) | Workflows with input specs, output templates, good + bad examples |
| Knowledge base (`docs/`) | Sourced domain data, checklists, volatile facts with review dates |
| Eval suite (`test-cases.md`) | Hard gates (binary, zero tolerance) + scored dimensions (1-5) |

Deployment targets:

| Target | Location | Use case |
|---|---|---|
| Standalone workspace | `generated-agents/[name]/` | The agent is the project |
| Project subagent | `.claude/agents/` + `.claude/skills/` | Agent augments existing work |
| User-level | `~/.claude/agents/` + `~/.claude/skills/` | Available in every session |

## Design Approach

Every agent gets a failure taxonomy before any files are written. The design brief ranks the top 3-5 failure modes by cost and maps each to a prevention mechanism — a rule in the system prompt, a template in a skill, an eval hard gate, or a hook.

The evaluation model separates **hard gates** (binary — any failure blocks release) from **scored dimensions** (1-5 on correctness, tone, completeness). Release criteria: all hard gates pass, ≥80% of representative cases score ≥3 on all dimensions.

Agent type determines everything downstream:

| Type | Research Intensity | Top Risk |
|---|---|---|
| Creative/Voice | Low | Tone drift, generic output |
| Analytical/Research | High | Stale facts, hallucinated citations |
| Operational/Workflow | Low | Missed edge cases |
| Regulated/High-Risk | Medium | Non-compliant output |
| Internal-Knowledge | None | Confidentiality leaks |

## Architecture

```
agentspawn/
├── CLAUDE.md                                 # System prompt and operating rules
├── .claude/
│   ├── settings.json                         # Hook wiring
│   ├── skills/                               # One skill per pipeline phase
│   │   ├── classify/    interview/    research/    design/
│   │   └── build/       validate/     deliver/     memory-recall/
│   ├── agents/
│   │   ├── researcher.md                     # Background research (Opus, read-only)
│   │   └── evaluator.md                      # Eval execution (autonomous, isolated)
│   └── hooks/
│       ├── require-design-brief.sh           # Gate: design before build
│       ├── require-evals-before-delivery.sh  # Gate: evals before delivery
│       ├── check-user-level-budget.sh        # Context budget guard
│       ├── nudge-build-not-solve.sh          # Nudge: build agents, don't solve directly
│       ├── check-for-updates.sh              # Notify (opt-in auto-FF) when behind origin/main
│       ├── session-start-memory.sh           # Cross-session memory injection
│       └── pre-compact-backup.sh             # Memory persistence before compaction
├── templates/                                # Scaffolding for generated agent files
├── reference/                                # Failure taxonomy, knowledge architecture
├── scripts/
│   ├── make-launcher.sh                      # Build a macOS Dock launcher (.app)
│   └── gen-icon.js                           # Dependency-free icon generator (JXA)
└── generated-agents/                         # Pipeline output
```

## Dock Launcher (macOS)

One-click Dock launchers let you start a session without opening a terminal and
typing. Clicking the app opens your terminal (iTerm2 → Ghostty → Terminal.app,
auto-detected), `cd`s into the project, and runs your chosen command.

Build one for agentspawn itself:

```bash
scripts/make-launcher.sh AgentSpawn "$(pwd)"
```

It prompts for the launch command (`claude`, `claude --dangerously-skip-permissions`,
your `yolo` alias if detected, or a custom command), generates a distinct colored
icon, and writes the `.app` to `~/Applications`. Drag it onto your Dock.

Session defaults (subagent model, auto-compact window, adaptive thinking) are set
for **every** agentspawn session via `.claude/settings.json` — launcher or plain
`claude`, every user gets them. Only `--dangerously-skip-permissions` is left as a
per-launch choice, since bypassing approval prompts should be opt-in.

Every standalone agent built by the pipeline can get its own launcher too — the
deliver phase offers one automatically. Each agent gets a uniquely colored icon
derived from its name, so they're easy to tell apart in the Dock.

```bash
# Generate manually for any directory:
scripts/make-launcher.sh --cmd yolo --icon-text MA "My Agent" /path/to/agent
```

No external tools required (icons are rendered via macOS's built-in JXA/Cocoa
bridge — no ImageMagick or Pillow).

## Troubleshooting: ask Claude Code to fix it

agentspawn is just markdown and shell scripts running **inside Claude Code** — and
Claude Code can read and edit every one of those files. So when something goes
wrong, the fastest fix is usually to describe the problem in the same session and
let it diagnose and repair itself. It can read its own skills, hooks, and scripts,
reason about the failure, and patch the offending file.

Paste the exact error or behavior and ask. For example:

- **A gate blocks you unexpectedly** — _"The design gate won't let me build even
  though `design-brief.md` exists. Read `.claude/hooks/require-design-brief.sh` and
  tell me why, then fix it."_
- **The Dock launcher misbehaves** — _"AgentSpawn.app opens the wrong terminal /
  doesn't run my command. Check `scripts/make-launcher.sh` and fix the detection."_
- **A generated agent gives weak output** — _"The agent you built returns generic
  results. Diagnose which phase caused it and fix that phase."_
- **A skill or hook errors out** — paste the error text and ask it to find the
  cause. Shell hooks print to stderr; copy that line in verbatim.
- **A web-research step keeps failing** — _"Research can't load this page. Confirm
  Playwright MCP is installed and fall back to it."_

For problems with **Claude Code itself** (install, login, missing tools), run
`claude doctor` for a diagnostic, and see the official
[install & login troubleshooting guide](https://code.claude.com/docs/en/troubleshoot-install).

If a fix turns out to be a recurring pattern rather than a one-off, ask Claude Code
to fold it into the relevant skill, hook, or `CLAUDE.md` so it doesn't happen again
— the same maintenance loop the pipeline uses for the agents it builds.

## Requirements

| Component | Status | Purpose |
|---|---|---|
| [Claude Code](https://code.claude.com/docs/en/setup) | Required | agentspawn runs inside it ([install options](#install-claude-code)) |
| [Playwright MCP](https://github.com/microsoft/playwright-mcp) | Recommended | Browser tools for agents and research |
| macOS | Optional | Dock launcher only |

See [Setup](#setup) for install commands.

## License

MIT
