# Knowledge Architecture Reference

Reference for organizing knowledge by volatility and access pattern in generated agents.

## Knowledge Layers

| Layer | What Goes Here | File | When Loaded | Review Frequency |
|---|---|---|---|---|
| **Always-loaded** | Identity, core rules, top 5 constraints, output defaults, ambiguity strategy | `CLAUDE.md` | Every session | Quarterly |
| **On-demand reference** | Frameworks, methodologies, decision trees, detailed rules, output templates | `skills/*.md` | When skill triggered | When outputs drift |
| **Deep reference** | Market data, competitor analysis, case studies, regulations, sourced facts | `guide.md` or `docs/*.md` | When agent searches | Biannually |
| **Stable principles** | Brand voice, positioning, values — things that don't change | `templates/principles.md` | On demand | Annually |
| **Current business facts** | Pricing, team size, active clients, current offerings | `templates/current-facts.md` | On demand | Quarterly |
| **Volatile/campaign** | Seasonal offers, event-specific content, time-limited data | `templates/current-campaign.md` | On demand | Monthly (delete when expired) |
| **Client-specific** | Per-client notes, preferences, history | `clients/[name].md` | Only for that client | Per engagement |

## Sizing Guidelines

| File | Target Size | When to Split |
|---|---|---|
| CLAUDE.md | Tier 1: 30-60, Tier 2: 80-120, Tier 3: 80-150 lines | When over budget → move to skill or template |
| guide.md | Up to ~500 lines | Split into `docs/` with topic-specific files |
| Individual skill | Up to 200 lines | Split into skill + supporting files |
| Individual template | As needed | — |

## Retrieval Ergonomics

- Every filename should answer a retrieval question: `docs/market-data-2026.md` not `docs/research.md`
- Every file starts with a one-line purpose statement: `# Market Data 2026 — KMU AI adoption rates and forecasts`
- Avoid generic filenames beyond root essentials (CLAUDE.md, guide.md)
- When in doubt, name the file after the question it answers

## When guide.md Exceeds ~500 Lines

Split into `docs/` with descriptive, retrieval-oriented filenames:

```
docs/
├── market-data-2026.md        # "What are the market numbers?"
├── competitor-pricing.md      # "What do competitors charge?"
├── legal-dsgvo.md             # "What are the DSGVO requirements?"
├── case-studies.md            # "What results have we achieved?"
└── industry-benchmarks.md     # "What's the industry standard?"
```

Update CLAUDE.md's Context Loading section to reference `docs/` instead of `guide.md`.
