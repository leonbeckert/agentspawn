#!/bin/bash
# PreToolUse hook: blocks writing delivery artifacts unless eval results exist.
# Delivery artifacts are MAINTENANCE.md and README.md in generated-agents/.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only gate files in generated-agents/
if [[ "$FILE_PATH" != *"generated-agents/"* ]]; then
  exit 0
fi

# Only block delivery-phase files
BASENAME=$(basename "$FILE_PATH")
if [[ "$BASENAME" != "MAINTENANCE.md" ]] && [[ "$BASENAME" != "README.md" ]]; then
  exit 0
fi

# Extract the agent directory
AGENT_DIR=$(echo "$FILE_PATH" | sed -n 's|\(.*generated-agents/[^/]*/\).*|\1|p')

if [[ -z "$AGENT_DIR" ]]; then
  exit 0
fi

# Block if the agent has no eval suite at all.
# Deliberately not bound to the filename "test-cases.md": agents built in another
# language name it differently (German ones use "testfaelle.md"), and a gate that
# blocks on a filename teaches people to rename files rather than run evals.
if [[ ! -d "${AGENT_DIR}evals" ]] || [[ -z $(ls -A "${AGENT_DIR}evals" 2>/dev/null) ]]; then
  echo "Blocked: No eval suite found in ${AGENT_DIR}evals/. Run /validate before /deliver." >&2
  exit 2
fi

# Block unless some eval file carries actual results — definitions alone aren't enough.
# A result counts only in the form /validate writes it (validate/SKILL.md § Output):
#   (a) an outcome token on a line inside a "## Results" / "## Ergebnisse" section
#       (the section ends at the next heading of the same or a higher level), or
#   (b) a table cell that is exactly the outcome token, e.g. "| T3 | PASS |".
# Tokens are case-sensitive (PASS, FAIL, BESTANDEN, FEHLGESCHLAGEN), so prose like
# "PASS criteria" or "Pass if ..." in a definitions file never unlocks delivery.
ergebnis_gefunden() {
  local f
  while IFS= read -r -d '' f; do
    awk '
      FNR == 1 { ebene = 0 }
      /^#+[ \t]/ {
        n = match($0, /[^#]/) - 1
        if (ebene && n <= ebene) ebene = 0
        if ($0 ~ /^#+[ \t]+(Results|Ergebnisse)([ \t:]|$)/) { ebene = n; next }
      }
      ebene && /(^|[^A-Za-z])(PASS|FAIL|BESTANDEN|FEHLGESCHLAGEN)([^A-Za-z]|$)/ { gefunden = 1; exit }
      /\|[ \t]*(✅|❌)?[ \t]*\**(PASS|FAIL|BESTANDEN|FEHLGESCHLAGEN)\**[ \t]*\|/ { gefunden = 1; exit }
      END { exit !gefunden }' "$f" 2>/dev/null && return 0
  done < <(find "${AGENT_DIR}evals" -type f -name '*.md' -print0 2>/dev/null)
  return 1
}
if ! ergebnis_gefunden; then
  echo "Blocked: no eval results in ${AGENT_DIR}evals/ — expected a '## Results' section (or '## Ergebnisse') with PASS/FAIL per case, or a table cell that is exactly PASS/FAIL. Run /validate before /deliver." >&2
  exit 2
fi

exit 0
