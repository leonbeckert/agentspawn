# agentspawn Memory

## Active Threads
<!-- Currently in-progress work. Remove when completed. -->
(none)

## Agents Built
<!-- One line per agent: name | date | deployment target | status -->
- bachelorarbeit-assistent | 2026-03-10 | standalone (`generated-agents/bachelorarbeit-assistent/`) | validated, needs /deliver
- bmw-cv-agent | 2026-03-10 | standalone (`generated-agents/bmw-cv-agent/`) | validated (Tier 1, /deliver optional)
- bmw-interview-prep | 2026-03-12 | standalone (`generated-agents/bmw-interview-prep/`) | validated (19/19 PASS)
- bmw-motivationsschreiben-agent | 2026-03-10 | standalone (`generated-agents/bmw-motivationsschreiben-agent/`) | validated (Tier 1, /deliver optional)
- context-distiller | 2026-03-10 | user-level (`~/.claude/agents/context-distiller.md`) | validated, needs /deliver
- cuda-showcase | 2026-03-10 | standalone (`generated-agents/cuda-showcase/`) | built, needs /validate
- deep-researcher | 2026-03-11 | standalone (`generated-agents/deep-researcher/`) | delivered, needs live test
- job-fit-analyzer | 2026-03-10 | standalone (`generated-agents/job-fit-analyzer/`) | validated (Tier 1, /deliver optional)
- openai-cv | 2026-03-11 | standalone (`generated-agents/openai-cv/`) | validated, needs /deliver
- openclaw-webinar-rewriter | 2026-03-10 | standalone (`generated-agents/openclaw-webinar-rewriter/`) | built, needs /validate
- os-release | 2026-03-10 | user-level (`~/.claude/agents/os-release.md`) | validated, needs /deliver
- oss-namer | 2026-03-09 | multi-project (`generated-agents/oss-namer/`) | delivered
- bmw-press-scraper | 2026-03-13 | standalone (`generated-agents/bmw-press-scraper/`) | validated (8/8 HG PASS, 751 articles scraped)
- bmw-technical-strategy | 2026-03-13 | standalone (`generated-agents/bmw-technical-strategy/`) | validated (15/15 PASS, 4.83/5 avg)
- playbook-generator | 2026-03-11 | standalone (`generated-agents/playbook-generator/`) | validated, needs first live playbook

## Key Conventions
<!-- Patterns discovered across 3+ sessions. Promote from session summaries. -->
- **Always use opus.** All agents (standalone, subagent, user-level) must use `claude-opus-4-6`. Standalone agents get `"model": "claude-opus-4-6"` in `.claude/settings.json`. Subagents get `model: opus` in frontmatter. No exceptions.
- **PDF toolchains vary by use case.** See [topics/pdf-toolchains.md](topics/pdf-toolchains.md) for decision matrix.
- **German register must match audience.** Du/Sie/neutral depends on context. See [topics/german-language-agents.md](topics/german-language-agents.md).
- **Source credibility uses 3 tiers.** Evidenz > Orientierung > Heuristik. See [topics/source-credibility.md](topics/source-credibility.md).
- **Research-heavy agents need parallel research architecture.** If an agent must gather information across many topics (3+), design it with parallel research subagents from the start. A single sequential skill is an architectural miss. Symptom of getting this wrong: trying to do the agent's research yourself at build time.

## Topic Files
- [pdf-toolchains.md](topics/pdf-toolchains.md) — toolchain decision matrix for formatted output
- [german-language-agents.md](topics/german-language-agents.md) — Du/Sie, tone patterns, marketing blacklist
- [source-credibility.md](topics/source-credibility.md) — 3-tier framework for research agents
- [self-improvement-audit-2026-03-12.md](topics/self-improvement-audit-2026-03-12.md) — audit findings and action items

## Recent Sessions
<!-- Last 10 sessions, most recent first. Move older entries to topics/ when this section grows. -->
- 2026-03-13 | bmw-press-scraper | full pipeline (classify→validate) | (session in this conversation)
- 2026-03-13 | bmw-technical-strategy | full pipeline (classify→validate) | (prior conversation)
- 2026-03-12 | bmw-interview-prep | build+validate | (no session file — built today)
- 2026-03-11 | playbook-generator | build+validate | [session](sessions/2026-03-11T1700Z-build-playbook-generator.md)
- 2026-03-11 | deep-researcher | full pipeline | [session](sessions/2026-03-11T1745Z-deliver-deep-researcher.md)
- 2026-03-11 | openai-cv | build+validate | [session](sessions/2026-03-10T0006Z-build-openai-cv.md)
- 2026-03-10 | bachelorarbeit-assistent | build+validate | [session](sessions/2026-03-10T0000Z-build-bachelorarbeit-assistent.md)
- 2026-03-10 | bmw-cv-agent | build+validate | [session](sessions/2026-03-10T0001Z-build-bmw-cv-agent.md)
- 2026-03-10 | bmw-motivationsschreiben | build+validate | [session](sessions/2026-03-10T0002Z-build-bmw-motivationsschreiben-agent.md)
- 2026-03-10 | context-distiller | build+validate | [session](sessions/2026-03-10T0003Z-build-context-distiller.md)
- 2026-03-10 | job-fit-analyzer | build+validate | [session](sessions/2026-03-10T0005Z-build-job-fit-analyzer.md)
<!-- Older sessions (files retained, removed from index per pruning rule): -->
<!-- 2026-03-10 | os-release | build+validate | sessions/2026-03-10T0008Z-build-os-release.md -->
<!-- 2026-03-10 | context-distiller | build+validate | sessions/2026-03-10T0003Z-build-context-distiller.md -->
<!-- 2026-03-10 | cuda-showcase | build | sessions/2026-03-10T0004Z-build-cuda-showcase.md -->
<!-- 2026-03-10 | openclaw-webinar-rewriter | build | sessions/2026-03-10T0007Z-build-openclaw-webinar-rewriter.md -->
<!-- 2026-03-09 | oss-namer | build+validate+deliver | sessions/2026-03-09T0000Z-build-oss-namer.md -->
