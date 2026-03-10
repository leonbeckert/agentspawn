---
name: memory-recall
description: Search past session summaries and topic files for context relevant to current work. Use when resuming work on a previously built agent, continuing a prior session, or when the user references past decisions.
---

# Memory Recall

Search the project's session memory for context relevant to the current task.

## When to Use

- The user references a previous session or agent they built before
- You're about to start work on an agent that may have prior history
- The user asks "what did we decide about X" or "remind me about Y"
- MEMORY.md mentions an active thread related to the current task

## How to Search

1. **Start with the index.** Read `.claude/memory/MEMORY.md` for the overview of past work, active threads, and agent history.

2. **Search session summaries.** Use Grep to search `.claude/memory/sessions/` for relevant keywords:
   - Agent names (e.g., `transport-agent`)
   - Phase names (e.g., `build`, `validate`)
   - Specific topics (e.g., `deployment target`, `hook pattern`)
   - Tags in YAML frontmatter

3. **Read matching files.** Open the 2-3 most relevant session summary files. Focus on:
   - Decisions made
   - Open threads / follow-up items
   - Resume prompts

4. **Check topic files.** If the query relates to a recurring pattern, check `.claude/memory/topics/` for consolidated learnings.

## What to Extract

From the matching memories, extract only:
- Decisions that affect current work
- Constraints or conventions to follow
- Unresolved issues that need attention
- Artifact paths the user may need
- Resume context (where to pick up)

## What NOT to Do

- Do not read every session file — search first, read selectively
- Do not inject raw transcript content
- Do not surface irrelevant history just because it exists
- Do not read more than 3-4 session files per recall
