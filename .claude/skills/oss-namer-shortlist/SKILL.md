# Shortlist

Generate the final scored shortlist with full availability checks. This is the deliverable.

## Trigger

User invokes `/shortlist`, or naturally transitions from brainstorming after narrowing directions.

## Inputs

**From the brainstorm session:**
- Promising naming directions the user liked
- Specific candidates that resonated
- Target ecosystems

**From project files:**
- `docs/oss-namer-guide.md` — availability endpoints, ecosystem rules, scoring criteria

## Workflow

### Step 1: Generate Candidates

From the brainstorm directions, generate 12-15 candidates. More than the final 8-10 because some will be eliminated by availability checks.

For each candidate, note:
- Strategy used (metaphorical, descriptive, mythological, etc.)
- Why it fits this specific project
- Potential concerns (pronunciation, meaning, length)

### Step 2: Run Availability Checks

For each candidate, run the batch check. Use parallel curl for efficiency:

```bash
NAME="candidate"
echo "=== $NAME ==="
(curl -s -o /dev/null -w "GitHub:     %{http_code}\n" "https://api.github.com/users/$NAME") &
(curl -s -o /dev/null -w "npm:        %{http_code}\n" "https://registry.npmjs.org/$NAME") &
(curl -s -o /dev/null -w "PyPI:       %{http_code}\n" "https://pypi.org/pypi/$NAME/json") &
(curl -s -o /dev/null -w "crates.io:  %{http_code}\n" -A "oss-namer/1.0" "https://crates.io/api/v1/crates/$NAME") &
(curl -s -o /dev/null -w "domain.com: %{http_code}\n" "https://rdap.verisign.com/com/v1/domain/$NAME.com") &
(curl -s -o /dev/null -w "domain.dev: %{http_code}\n" "https://pubapi.registry.google/rdap/domain/$NAME.dev") &
wait
```

**Important:** Check all candidates before presenting. Don't present names one at a time.

**PyPI normalization:** Before checking PyPI, normalize the name:
```bash
NORMALIZED=$(python3 -c "import re; print(re.sub(r'[-_.]+', '-', '$NAME'.lower()))")
curl -s -o /dev/null -w "%{http_code}" "https://pypi.org/pypi/$NORMALIZED/json"
```

**GitHub rate limit:** 60 requests/hour unauthenticated. With 12-15 candidates, you'll use ~15 requests (one per candidate for GitHub user/org check). Stay well within limits.

### Step 3: Score Candidates

Score each surviving candidate on 4 dimensions (1-5):

| Dimension | 5 = Best | 1 = Worst |
|---|---|---|
| **Memorability** | Unique, vivid mental image, 1-2 syllables | Generic, forgettable, >3 syllables |
| **Metaphor fit** | Metaphor explains the project in one step | No semantic connection to function |
| **Availability** | Available on all target registries + .com | Taken on primary registry |
| **Ecosystem fit** | Follows all conventions, import=install name | Violates naming rules, creates confusion |

### Step 4: Present the Shortlist

Present the top 8-10 candidates (drop any that are taken on the primary target registry). Format:

```
# Shortlist: [Project Name]

## Top Picks

### 1. [Name] — [one-line pitch]
Strategy: [metaphorical/descriptive/etc.]
Why: [2-3 sentences on why this name fits]
Scores: Memorability 5 | Metaphor 4 | Availability 5 | Ecosystem 5

| Registry | Status |
|---|---|
| GitHub | Available |
| npm | Available |
| PyPI | Available |
| crates.io | Available |
| .com | Taken |
| .dev | Available |

---

### 2. [Name] — [one-line pitch]
...
```

Order by total score (highest first). If scores are tied, prefer the name with better availability.

For multi-ecosystem targets: highlight which names are available on ALL target registries. This is the most valuable signal — a name available everywhere avoids fragmented branding.

### Step 5: Trademark Quick Scan

For the top 3 candidates, run a quick trademark search:
```
WebSearch: "[name]" trademark class 42 software
WebSearch: "[name]" software company
```

Note any potential conflicts in the shortlist presentation.

## Good Example

```
# Shortlist: Python Human-in-the-Loop Library

## Top Picks

### 1. Turnstile — one at a time, with permission
Strategy: Metaphorical
Why: A turnstile controls passage — you can't pass without authorization.
Exactly what this library does to AI agent actions. Short (2 syllables),
vivid physical image, connotes both security and controlled flow.
Scores: Memorability 5 | Metaphor 5 | Availability 4 | Ecosystem 5

| Registry | Status |
|---|---|
| GitHub | Available |
| npm | Taken (Cloudflare Turnstile) |
| PyPI | Available |
| .com | Taken |
| .dev | Available |

Note: npm conflict with Cloudflare's Turnstile CAPTCHA. Fine if
this is Python-only; flag if cross-ecosystem.
```

## Bad Example

Presenting a list of names without scores, without availability checks, or with more than 10 candidates. The user hired this agent to narrow, not to dump options.
