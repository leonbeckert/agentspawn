# Check

Standalone availability checker. The user already has a name in mind — check it across all registries and report conflicts.

Do not suggest alternative names or brainstorm unless the user explicitly asks. This skill is for checking, not generating.

## Trigger

User invokes `/check [name]`, or asks "is [name] available?"

## Inputs

**From the user:**
- The name to check
- Optional: specific ecosystems to check (defaults to all)

**From project files:**
- `docs/oss-namer-guide.md` — API endpoints, normalization rules

## Workflow

### Step 1: Normalize

Before checking, prepare ecosystem-specific forms:

- **npm:** lowercase, hyphens for separators
- **PyPI:** normalize via PEP 503 (`re.sub(r"[-_.]+", "-", name.lower())`)
- **crates.io:** check both hyphen and underscore forms (they collide)
- **GitHub:** as-is (case-insensitive)
- **Domain:** lowercase, no special chars

### Step 2: Run All Checks

Run in parallel for speed:

```bash
NAME="the-name"

echo "=== Availability Report: $NAME ==="

# Package registries
(curl -s -o /dev/null -w "GitHub org/user:  %{http_code}\n" "https://api.github.com/users/$NAME") &
(curl -s -o /dev/null -w "npm:             %{http_code}\n" "https://registry.npmjs.org/$NAME") &

# PyPI — use normalized form
PYPI_NAME=$(python3 -c "import re; print(re.sub(r'[-_.]+', '-', '$NAME'.lower()))")
(curl -s -o /dev/null -w "PyPI:            %{http_code}\n" "https://pypi.org/pypi/$PYPI_NAME/json") &

# crates.io — needs User-Agent
(curl -s -o /dev/null -w "crates.io:       %{http_code}\n" -A "oss-namer/1.0" "https://crates.io/api/v1/crates/$NAME") &

# Domains
(curl -s -o /dev/null -w ".com:            %{http_code}\n" "https://rdap.verisign.com/com/v1/domain/$NAME.com") &
(curl -s -o /dev/null -w ".dev:            %{http_code}\n" "https://pubapi.registry.google/rdap/domain/$NAME.dev") &
(curl -s -o /dev/null -w ".io (whois):     " && whois "$NAME.io" 2>/dev/null | grep -qi "is available" && echo "available" || echo "check manually") &

wait
echo ""
echo "Key: 200=taken, 404=available"
```

### Step 3: Deep Check on Conflicts

For any registry that returns 200 (taken):

- **GitHub:** Fetch the profile to see if it's a user or org, active or inactive.
  ```bash
  curl -s "https://api.github.com/users/$NAME" | python3 -c "
  import sys, json
  d = json.load(sys.stdin)
  print(f\"Type: {d.get('type')} | Created: {d.get('created_at','?')[:10]} | Repos: {d.get('public_repos',0)}\")
  "
  ```

- **npm:** Check if the package is actively maintained or abandoned.
  ```bash
  curl -s "https://registry.npmjs.org/$NAME" | python3 -c "
  import sys, json
  d = json.load(sys.stdin)
  time = d.get('time', {})
  modified = time.get('modified', 'unknown')
  versions = list(d.get('versions', {}).keys())
  print(f\"Last modified: {modified[:10]} | Versions: {len(versions)} | Latest: {versions[-1] if versions else 'none'}\")
  "
  ```

- **PyPI:** Check the package metadata.
  ```bash
  curl -s "https://pypi.org/pypi/$PYPI_NAME/json" | python3 -c "
  import sys, json
  d = json.load(sys.stdin)
  info = d.get('info', {})
  print(f\"Summary: {info.get('summary','none')[:80]} | Version: {info.get('version','?')} | Author: {info.get('author','?')}\")
  "
  ```

### Step 4: Present Report

```
# Availability Report: [name]

| Registry | Status | Details |
|---|---|---|
| GitHub | Available | — |
| npm | Taken | Last updated 2019, 0 weekly downloads (abandoned?) |
| PyPI | Available | (checked normalized: [normalized-form]) |
| crates.io | Available | — |
| .com | Taken | Registered domain |
| .dev | Available | — |

## Summary
[Name] is available on [X/Y] target registries. The npm conflict
is with an abandoned package — you could request transfer via npm support,
or use a scoped package (@yourorg/name) as fallback.

## Trademark Quick Scan
[Results of WebSearch for "[name] trademark software"]
```

### Step 5: Ecosystem-Specific Warnings

Flag any ecosystem-specific issues:

- **PyPI:** If the name uses hyphens, warn about the import/install name split. Suggest the underscore form.
- **crates.io:** If the name uses hyphens, note it will auto-convert to underscores in Rust code.
- **npm:** If the name is close to an existing popular package (edit distance 1-2), warn about typosquatting perception.

## Good Example

User: "Is 'turnstile' available?"

```
# Availability Report: turnstile

| Registry | Status | Details |
|---|---|---|
| GitHub | Taken | Organization, 28 repos (Cloudflare Turnstile) |
| npm | Taken | @cloudflare/turnstile, active |
| PyPI | Available | — |
| crates.io | Available | — |
| .com | Taken | turnstile.com registered |
| .dev | Taken | turnstile.dev registered |

## Summary
"turnstile" is strongly associated with Cloudflare's CAPTCHA product.
Available on PyPI and crates.io, but the GitHub org and npm namespace
are owned by Cloudflare. Using this name would create confusion
in the JS/TS ecosystem. Recommended: find an alternative, or scope
to Python/Rust only if that's the sole target.

## Trademark Note
Cloudflare uses "Turnstile" as a product name. While not
necessarily a registered trademark for your use case, the strong
brand association makes this a risky choice.
```

## Bad Example

Just running the curl commands and dumping raw HTTP status codes without interpretation or recommendations.
