---
name: build
description: Write the agent files based on the approved design brief. Creates agent artifacts in the location specified by the deployment target. Supports standalone, project subagent, and user-level deployment.
disable-model-invocation: true
---

# Build Phase

Write the agent files. This skill requires manual invocation because building should only happen after the user approves the design brief.

**Before starting:** Read the design brief to confirm it exists and review the approved plan. Check the **Deployment Target** section to determine which output format to use. Read templates from `templates/` for scaffolding.

## Deployment Targets

The design brief specifies one of four deployment targets. Each produces a different file layout.

### Standalone Workspace

The agent is its own project. The user will `cd [agent-dir] && claude` to use it.

Write to `generated-agents/[agent-name]/`:

```
[agent-name]/
├── CLAUDE.md
├── guide.md               (or docs/ if large)
├── skills/
│   └── [skill-name].md
├── templates/
│   ├── principles.md       (stable: voice, values)
│   ├── current-facts.md    (volatile: pricing, team)
│   └── ...
├── evals/
│   └── test-cases.md
└── scripts/                (if tools needed)
```

### Project Subagent

The agent lives inside an existing project. The user is already in that project and wants the agent available as a subagent they can delegate to.

Write to the target project directory:

```
<target-project>/
├── .claude/
│   ├── agents/
│   │   └── [agent-name].md          # Subagent definition (system prompt + frontmatter)
│   └── skills/
│       ├── [agent-name]-[skill-1]/
│       │   └── SKILL.md
│       ├── [agent-name]-[skill-2]/
│       │   └── SKILL.md
│       └── ...
├── docs/
│   └── [agent-name]-guide.md        # Knowledge base (or [agent-name]-docs/ if large)
└── evals/
    └── [agent-name]-test-cases.md
```

**The subagent definition file** (`.claude/agents/[agent-name].md`) combines what would be CLAUDE.md + frontmatter:

```yaml
---
name: [agent-name]
description: [1-2 sentences — Claude uses this to decide when to delegate]
tools: [tool list appropriate to agent type]
disallowedTools: [tools to explicitly deny]
model: [inherit/sonnet/opus/haiku]
skills:
  - [agent-name]-[skill-1]
  - [agent-name]-[skill-2]
memory: project
permissionMode: [default/acceptEdits/dontAsk/bypassPermissions/plan]
maxTurns: [number]
background: [true/false]
hooks:
  PreToolUse:
    - matcher: "[tool-name]"
      hooks:
        - type: command
          command: "[validation-script]"
mcpServers: [server names or inline definitions]
isolation: [worktree]
---

[System prompt content — what would normally go in CLAUDE.md]
[Include: user profile, core constraints, output defaults, ambiguity strategy,
 context loading (referencing docs/[agent-name]-guide.md and skills), forbidden outputs]
```

**Frontmatter field guide** — only `name` and `description` are required. Include others based on the design brief:

| Field | When to Include | Guidance |
|---|---|---|
| `tools` | When the agent should NOT have full tool access | Allowlist. Omit to inherit all tools from parent |
| `disallowedTools` | When you need to block specific tools | Denylist. Prefer over `tools` when blocking only a few |
| `model` | When the agent needs a specific model | `sonnet` for speed/cost, `opus` for complex reasoning, `haiku` for fast read-only. Default: `inherit` |
| `skills` | When the agent has namespaced skills | Full skill content is injected at startup. Subagents don't inherit parent skills |
| `memory` | When the agent should learn across sessions | `project` for codebase-specific, `user` for cross-project. Creates persistent memory directory |
| `permissionMode` | When the agent needs different permission behavior | `dontAsk` for autonomous agents, `acceptEdits` for edit-heavy agents, `plan` for read-only |
| `maxTurns` | When you need to bound agent runtime | Prevents runaway agents. Set based on expected task complexity |
| `background` | When the agent is typically launched in parallel | `true` means always run as background task |
| `hooks` | When the agent needs runtime validation | PreToolUse for input validation, PostToolUse for output checks, Stop for cleanup |
| `mcpServers` | When the agent needs external tool access | Reference configured servers by name or define inline |
| `isolation` | When the agent modifies files that shouldn't affect the main worktree | `worktree` gives it an isolated git copy |

**Key differences from standalone:**
- CLAUDE.md content becomes the subagent's markdown body (the system prompt)
- Skills are prefixed with `[agent-name]-` to avoid namespace conflicts with other agents
- The `skills` frontmatter field preloads skill content into the subagent's context at startup — the agent gets the full content, not just availability
- Knowledge goes in `docs/` at the project root, not in a nested directory
- The agent operates from the project root — no `../` path issues
- Evals go in the project's `evals/` directory, prefixed by agent name
- Subagents receive only their system prompt + basic environment info, NOT the full Claude Code system prompt
- Subagents cannot spawn other subagents

### Multi-Project Subagent

The agent is needed in 2+ specific projects but not all projects. Build once, symlink to each target.

**Step 1:** Build the agent in `generated-agents/[agent-name]/` using the **project subagent** file layout (agent definition + namespaced skills + docs + evals).

**Step 2:** Create a `deploy.sh` script in the agent directory:

```bash
#!/bin/bash
# Deploy [agent-name] to target projects via symlinks.
# Source of truth: this directory. Symlinks ensure updates propagate automatically.
AGENT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENT_NAME="[agent-name]"

TARGETS=(
  "/path/to/project-a"
  "/path/to/project-b"
)

for PROJECT in "${TARGETS[@]}"; do
  # Agent definition
  mkdir -p "$PROJECT/.claude/agents"
  ln -sf "$AGENT_DIR/.claude/agents/$AGENT_NAME.md" "$PROJECT/.claude/agents/$AGENT_NAME.md"

  # Skills (symlink each skill directory)
  mkdir -p "$PROJECT/.claude/skills"
  for SKILL_DIR in "$AGENT_DIR/.claude/skills/$AGENT_NAME-"*/; do
    SKILL_NAME=$(basename "$SKILL_DIR")
    ln -sf "$SKILL_DIR" "$PROJECT/.claude/skills/$SKILL_NAME"
  done

  # Knowledge base (if exists)
  if [[ -d "$AGENT_DIR/docs" ]]; then
    mkdir -p "$PROJECT/docs"
    for DOC in "$AGENT_DIR/docs/$AGENT_NAME-"*; do
      ln -sf "$DOC" "$PROJECT/docs/$(basename "$DOC")"
    done
  fi

  echo "Deployed $AGENT_NAME to $PROJECT"
done
```

**Step 3:** Populate the `TARGETS` array with the project paths from the design brief. Make the script executable.

**Key properties:**
- Single source of truth in `generated-agents/` — edits propagate via symlinks
- Zero context cost in projects not listed as targets
- Each target project sees the agent in `/agents` as if it were a native project subagent
- The `deploy.sh` script is re-runnable (idempotent via `ln -sf`)
- To remove from a project: delete the symlinks

**File layout in `generated-agents/`:**

```
generated-agents/[agent-name]/
├── .claude/
│   ├── agents/
│   │   └── [agent-name].md
│   └── skills/
│       ├── [agent-name]-[skill-1]/
│       │   └── SKILL.md
│       └── ...
├── docs/
│   └── [agent-name]-guide.md
├── evals/
│   └── [agent-name]-test-cases.md
└── deploy.sh
```

### User-Level Agent

The agent is available in all projects on the user's machine. **Use sparingly** — each user-level agent loads into every session. A hook warns at 5 and blocks at 10 user-level agents.

Write to user-level directories:

```
~/.claude/
├── agents/
│   └── [agent-name].md              # Subagent definition
└── skills/
    ├── [agent-name]-[skill-1]/
    │   └── SKILL.md
    ├── [agent-name]-[skill-2]/
    │   └── SKILL.md
    └── ...
```

**Key differences from project subagent:**
- No project-specific knowledge (guide.md/docs/) — the agent works across projects
- Skills must be self-contained (can't reference project-specific files)
- Use `memory: user` instead of `memory: project` in the subagent frontmatter
- Evals are written to `generated-agents/[agent-name]/evals/` (the factory's staging area) since there's no single project to put them in
- Hooks in frontmatter must reference scripts at absolute paths or paths relative to any project root

## Writing the System Prompt (CLAUDE.md or Subagent Body)

Read `templates/claude-md.md` for the template structure.

**Line budget:** Tier 1: 30-60, Tier 2: 80-120, Tier 3: 80-150. A more serious agent does NOT mean a longer system prompt — manage risk through tighter skills, stronger evals, validators, and narrower scope.

**Principles:**
1. Every line must prevent a specific failure. If you can't name the failure, delete the line.
2. Explain WHY. "Use active voice because the audience skims on mobile" > "Use active voice."
3. Alternatives over prohibitions. "Instead of X, use Y because Z" > "Don't do X."
4. Normal language. Claude overtriggers on "CRITICAL"/"YOU MUST." Reserve emphasis for 1-2 rules max.
5. Don't replicate what Claude already knows. Standard conventions don't belong here.
6. Forbidden outputs must be explicit and specific, not vague.
7. Include real user examples when available — they anchor quality better than abstract descriptions.

**Must include:**
- Context Loading section: read skills/, guide.md/docs/, templates/ before responding. Do NOT ask the user for information already in project files. Adjust file paths based on deployment target.
- Ambiguity Strategy: when to ask vs. assume, calibrated to this agent's risk profile.
- Forbidden Outputs: for regulated/high-risk agents.

## Writing guide.md / Knowledge Base

Organized by topic, not chronologically. Tables over paragraphs.
- Web-researched content: include source URLs
- Private/internal content: note origin and date
- Volatile facts: mark with `[Review: YYYY-MM]`
- When exceeding ~500 lines: split into `docs/` with descriptive filenames

For project subagents: prefix files with the agent name (e.g., `docs/[agent-name]-guide.md`) to avoid conflicts with other project docs.

## Writing Skills

Read `templates/skill.md` for the template structure.

**Per skill:**
- Separate "from the user" inputs from "from project files" inputs explicitly
- Include one good AND one bad example (Tier 2+)
- Specify clarification triggers — when the agent should ask before generating
- Match freedom to fragility: exact templates for high-risk, loose guidelines for creative
- Keep under 200 lines

For project/user-level subagents: prefix skill directory names with `[agent-name]-` to namespace them.

## Writing Evals

Read `templates/eval-suite.md` for the template structure.

**Evaluation model: hard gates + scored dimensions.**

Hard gates (binary pass/fail — any failure = no-ship):
- Define from the failure taxonomy in the design brief
- Common gates: no confidentiality leak, no forbidden output, no fabricated citation, correct escalation behavior

Scored dimensions (1-5):
- Correctness, Tone/Voice, Completeness
- Weight dimensions per agent type

**Tier-specific scope:**
- Tier 1: 5 representative cases
- Tier 2: 10-15 representative + 5 edge + 3 adversarial
- Tier 3: Full suite covering all failure modes, all forbidden-output classes, all ambiguity branches

**Release criteria:**
- All hard gates pass on all test cases (zero tolerance)
- ≥80% of representative cases score ≥3 on all scored dimensions
- Tier 3: ≥90% score ≥4 on Correctness, human review of 3+ outputs

## Writing Templates

Date volatile content. Include `[Review: YYYY-MM]` markers. Every filename answers a retrieval question.

For standalone agents only — project/user-level subagents typically don't need a separate templates/ directory since knowledge lives in docs/ or skill supporting files.

## Build Rules

- Follow the design brief. Don't add skills or features not in the approved plan.
- If you discover a gap during building, note it — don't silently expand scope.
- Write files in dependency order: system prompt first (it's the anchor), then knowledge base, then skills, then evals.
- Match the deployment target exactly. Don't write standalone structure when the brief says project subagent.
