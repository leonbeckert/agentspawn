---
name: interview
description: Conduct a structured discovery interview to gather agent requirements. Use after classification to understand scope, constraints, audience, and domain specifics.
---

# Discovery Interview

Gather the information needed to design the agent. Adapt questions to the agent type identified during classification.

## Before Asking Questions

1. **Check for existing files.** If the user has a CLAUDE.md, docs, prior outputs, or a codebase — read them first. Do not ask questions already answered in existing material.
2. **Research what you can.** If the user mentions their website, company, or public profile, fetch it before asking them to describe it.
3. **Review the classification.** Let the agent type guide which questions matter most.

## Interview Structure

### Round 1: Core Scope (4-5 questions)

- **Domain & Problem:** What exactly is the agent for? What specific problem does it solve?
- **User Profile:** Who are you? (Offer to fetch website/LinkedIn instead of making them type it.)
- **Output:** What should the agent produce? What format?
- **Audience:** Who consumes the output? If multiple stakeholders — who is primary, who approves, who can block?
- **Deployment:** Where should this agent live? Offer these options:
  1. **Standalone workspace** — Its own directory. You `cd` into it and run `claude`. Best when the agent IS the primary workspace (e.g., a consulting agent, a content production agent).
  2. **Project subagent** — Inside an existing project as `.claude/agents/` + `.claude/skills/`. Best when the agent augments one codebase (e.g., a migration helper, a code review agent).
  3. **Multi-project subagent** — Built once in `generated-agents/`, symlinked into 2+ specific projects. Best when the agent is needed in several but not all projects (e.g., a shared testing agent across related repos).
  4. **User-level agent** — In `~/.claude/agents/` + `~/.claude/skills/`. Loads into every session on this machine. Reserve for tools you genuinely use everywhere (e.g., a commit message writer). A hook will warn at 5 and block at 10 user-level agents.

  If the user is unsure, default to standalone for new-purpose agents, project subagent for single-codebase helpers, and multi-project for cross-repo needs. Prefer multi-project over user-level when the agent is only needed in specific projects.

### Round 2: Constraints & Context (3-4 questions, shaped by type)

**Creative/Voice agents:**
- Show me 2-3 examples of output you love. And 1-2 you hate.
- What's your voice? (Or: can I read your existing content to learn it?)
- What are the hard constraints? (Length, platform, language, no-go topics)

**Operational/Workflow agents:**
- Walk me through the process as you do it manually today.
- Where does it break? What are the most common edge cases?
- What systems/tools are involved? What's the source of truth?

**Regulated/High-Risk agents:**
- What jurisdictions/regulations apply?
- Who signs off? What's the escalation path?
- What can NEVER be claimed or produced? (Forbidden outputs)
- What's the cost of a wrong output? (Liability, compliance, reputation)

**Internal-Knowledge agents:**
- What internal documents should the agent know? (SOPs, templates, logs)
- How do I get access? Can you paste/share them?
- What's confidential vs. shareable?

**Analytical/Research agents:**
- What data sources matter most?
- How current does the data need to be?
- What's the output format? (Report, table, brief, dashboard input)

### Round 3: Operational Details (only if needed)

- How often will you use this?
- What tools/APIs does it integrate with?
- What changes in 3-6 months?

**If project subagent or user-level deployment:**
- Should the agent run autonomously or ask for permission before taking actions?
- Should it remember patterns across sessions (e.g., codebase conventions, recurring issues)?
- Does it need access to external services (databases, APIs, MCP servers)?
- Should it ever run in the background while you continue other work?

## Interview Rules

- **Maximum 3 rounds.** Most agents need 2.
- **Group 3-4 questions per round.** Don't ask one question at a time.
- **Don't ask what you can infer, research, or read from existing files.**
- **Offer options instead of open-ended questions where possible.**
- **In regulated/high-risk domains, keep asking until you've mapped forbidden outputs, approval chains, and escalation paths.** Don't optimize for brevity when a missed constraint breaks everything.

## "Enough" Means

You can predict, for any representative input, what the agent should produce and what it should refuse. If you can't do that yet, ask more. If you can, stop and move to research.
