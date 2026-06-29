#!/usr/bin/env bash
#
# make-launcher.sh — build a macOS Dock launcher (.app) that opens a terminal,
# cd's into a directory, and starts a Claude Code session.
#
# Click the app in your Dock → a terminal window opens already inside the
# project, running your chosen command (e.g. `claude` or your `yolo` alias).
#
# Usage:
#   scripts/make-launcher.sh [options] <AppName> <WorkingDir>
#
# Options:
#   --cmd "<command>"   Command to run in the terminal. If omitted, you are
#                       prompted (claude / yolo if detected / custom).
#   --icon-text "AB"    1-2 chars for the generated icon. Default: derived
#                       from <AppName>.
#   --dest <dir>        Where to place the .app. Default: ~/Applications
#   --no-icon           Skip icon generation (use the default applet icon).
#   -y, --yes           Non-interactive: accept defaults, don't prompt.
#   -h, --help          Show this help.
#
# Examples:
#   scripts/make-launcher.sh AgentSpawn "$(pwd)"
#   scripts/make-launcher.sh --cmd yolo --icon-text AS MyAgent /path/to/agent
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GEN_ICON="$SCRIPT_DIR/gen-icon.js"

# ---- defaults -------------------------------------------------------------
CMD=""
ICON_TEXT=""
DEST="$HOME/Applications"
MAKE_ICON=1
ASSUME_YES=0
APP_NAME=""
WORKDIR=""

die() { printf 'error: %s\n' "$1" >&2; exit 1; }

usage() { sed -n '2,32p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

# ---- parse args -----------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --cmd) CMD="${2:-}"; shift 2 ;;
    --icon-text) ICON_TEXT="${2:-}"; shift 2 ;;
    --dest) DEST="${2:-}"; shift 2 ;;
    --no-icon) MAKE_ICON=0; shift ;;
    -y|--yes) ASSUME_YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) die "unknown option: $1" ;;
    *)
      if [ -z "$APP_NAME" ]; then APP_NAME="$1"
      elif [ -z "$WORKDIR" ]; then WORKDIR="$1"
      else die "unexpected argument: $1"; fi
      shift ;;
  esac
done

[ "$(uname)" = "Darwin" ] || die "this launcher generator only supports macOS"
[ -n "$APP_NAME" ] || die "missing <AppName>. See --help."
[ -n "$WORKDIR" ] || die "missing <WorkingDir>. See --help."
[ -d "$WORKDIR" ] || die "working dir does not exist: $WORKDIR"

# Absolute path to the working directory.
WORKDIR="$(cd "$WORKDIR" && pwd)"

# The user's login shell, used for non-interactive terminals (Ghostty -e).
LOGIN_SHELL="${SHELL:-/bin/zsh}"

# ---- determine launch command --------------------------------------------
# Detect a `yolo` alias/function/binary in the user's login shell.
yolo_available() {
  "$LOGIN_SHELL" -ic 'command -v yolo || alias yolo' >/dev/null 2>&1
}

if [ -z "$CMD" ]; then
  if [ "$ASSUME_YES" = "1" ] || [ ! -t 0 ]; then
    CMD="claude"
  else
    # Project env (subagent model, context window, etc.) is configured in
    # .claude/settings.json, so the only real choice here is whether to skip
    # the per-action permission prompts.
    echo "What should clicking $APP_NAME run?"
    echo "  1) claude                                  (approve actions as you go)"
    echo "  2) claude --dangerously-skip-permissions   (skip approval prompts)"
    if yolo_available; then
      echo "  3) yolo                                     (your shell alias)"
    fi
    echo "  c) custom command"
    printf "Choose [1]: "
    read -r choice || choice=""
    case "${choice:-1}" in
      1|"") CMD="claude" ;;
      2) CMD="claude --dangerously-skip-permissions" ;;
      3) CMD="yolo" ;;
      c|C) printf "Enter command: "; read -r CMD ;;
      *) CMD="$choice" ;;
    esac
  fi
fi
[ -n "$CMD" ] || die "no launch command given"

# ---- derive icon text -----------------------------------------------------
if [ -z "$ICON_TEXT" ]; then
  # First letters of up to two words (split on - _ space / camelCase).
  spaced="$(printf '%s' "$APP_NAME" \
    | sed -E 's/[-_/]+/ /g; s/([a-z])([A-Z])/\1 \2/g')"
  ICON_TEXT="$(printf '%s' "$spaced" | awk '{
    n = (NF > 2) ? 2 : NF
    s = ""
    for (i = 1; i <= n; i++) s = s toupper(substr($i,1,1))
    print s
  }')"
  [ -n "$ICON_TEXT" ] || ICON_TEXT="$(printf '%s' "$APP_NAME" | cut -c1 | tr '[:lower:]' '[:upper:]')"
fi

# ---- derive a stable color from the name ----------------------------------
PALETTE=(4A90D9 7B5EA7 2E9E6B C0563B D9A23B 3A8FB7 B5497A 5B8C5A 8A6D3B 4C6EF5)
hash="$(printf '%s' "$APP_NAME" | cksum | cut -d' ' -f1)"
COLOR="${PALETTE[$(( hash % ${#PALETTE[@]} ))]}"

# ---- build the shell line typed into the terminal -------------------------
# Pre-quoted at build time so paths with spaces survive.
printf -v QUOTED_DIR '%q' "$WORKDIR"
SHELL_LINE="cd $QUOTED_DIR && $CMD"

# Escape for embedding inside an AppleScript double-quoted string literal.
as_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
AS_SHELL_LINE="$(as_escape "$SHELL_LINE")"
AS_WORKDIR="$(as_escape "$WORKDIR")"
AS_CMD="$(as_escape "$CMD")"
AS_LOGIN_SHELL="$(as_escape "$LOGIN_SHELL")"

# ---- compose the AppleScript ----------------------------------------------
# At click time it auto-detects an installed terminal (iTerm2 → Ghostty →
# Terminal.app) and opens a window already running the command.
read -r -d '' APPLESCRIPT <<APPLESCRIPT_EOF || true
on appInstalled(bundleID)
	try
		do shell script "mdfind \"kMDItemCFBundleIdentifier == '" & bundleID & "'\" | grep -q ."
		return true
	on error
		return false
	end try
end appInstalled

on run
	set shellLine to "$AS_SHELL_LINE"
	set workDir to "$AS_WORKDIR"
	set theCmd to "$AS_CMD"
	set loginShell to "$AS_LOGIN_SHELL"

	if appInstalled("com.googlecode.iterm2") then
		tell application "iTerm"
			activate
			set newWindow to (create window with default profile)
			tell current session of newWindow
				write text shellLine
			end tell
		end tell
	else if appInstalled("com.mitchellh.ghostty") then
		set q to quoted form of shellLine
		do shell script "open -na Ghostty --args -e " & quoted form of loginShell & " -ic " & q
	else
		tell application "Terminal"
			activate
			do script shellLine
		end tell
	end if
end run
APPLESCRIPT_EOF

# ---- build the .app bundle ------------------------------------------------
mkdir -p "$DEST"
APP_PATH="$DEST/$APP_NAME.app"
if [ -e "$APP_PATH" ]; then
  rm -rf "$APP_PATH"
fi

TMP_SCPT="$(mktemp -t make-launcher).applescript"
printf '%s\n' "$APPLESCRIPT" > "$TMP_SCPT"
osacompile -o "$APP_PATH" "$TMP_SCPT"
rm -f "$TMP_SCPT"

# ---- generate and install the icon ----------------------------------------
if [ "$MAKE_ICON" = "1" ] && [ -f "$GEN_ICON" ]; then
  if icon_png="$(mktemp -t launcher-icon).png" && \
     osascript -l JavaScript "$GEN_ICON" "$icon_png" "$ICON_TEXT" "$COLOR" >/dev/null 2>&1; then
    iconset="$(mktemp -d -t launcher-iconset)/Icon.iconset"
    mkdir -p "$iconset"
    ok=1
    for s in 16 32 128 256 512; do
      sips -z "$s" "$s" "$icon_png" --out "$iconset/icon_${s}x${s}.png" >/dev/null 2>&1 || ok=0
      d=$(( s * 2 ))
      sips -z "$d" "$d" "$icon_png" --out "$iconset/icon_${s}x${s}@2x.png" >/dev/null 2>&1 || ok=0
    done
    if [ "$ok" = "1" ] && iconutil -c icns "$iconset" -o "$APP_PATH/Contents/Resources/applet.icns" 2>/dev/null; then
      touch "$APP_PATH"
    else
      echo "warning: icon install failed; using default applet icon" >&2
    fi
    rm -rf "$icon_png" "$(dirname "$iconset")"
  else
    echo "warning: icon generation failed; using default applet icon" >&2
  fi
fi

# ---- report ---------------------------------------------------------------
cat <<DONE

✓ Launcher created: $APP_PATH
  Opens:   $WORKDIR
  Runs:    $CMD
  Icon:    $ICON_TEXT (#$COLOR)

Pin it: open Finder → ${DEST/#$HOME/~}, then drag "$APP_NAME" onto your Dock.
First click may prompt macOS to allow controlling your terminal — click OK.
DONE
