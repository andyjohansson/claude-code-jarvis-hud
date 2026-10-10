#!/usr/bin/env bash
# ======================================================================
#  JARVIS HUD  ·  installer for Claude Code
#  Safe to run more than once. Backs up settings.json before changing it.
#
#    ./install.sh                     install theme, status line, spinner verbs
#    ./install.sh --force-statusline  replace an existing status line too
#    ./install.sh --uninstall         remove everything this installed
# ======================================================================
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS="$CLAUDE_DIR/settings.json"
THEMES_DIR="$CLAUDE_DIR/themes"
HUD_DIR="$CLAUDE_DIR/jarvis-hud"
STATUSLINE="$HUD_DIR/statusline.sh"
PREVIOUS_SL="$HUD_DIR/previous-statusline.json"
THEME_ID="custom:jarvis-hud"
STAMP="$(date +%Y%m%d-%H%M%S)"

cyan=$'\e[38;2;0;216;255m'; gold=$'\e[38;2;255;215;95m'; red=$'\e[38;2;255;77;94m'; r=$'\e[0m'
say()  { printf '%s\n' "${cyan}◆${r} $*"; }
warn() { printf '%s\n' "${gold}!${r} $*"; }
die()  { printf '%s\n' "${red}✕${r} $*" >&2; exit 1; }

force_statusline=0
uninstall=0
for arg in "$@"; do
  case "$arg" in
    --force-statusline) force_statusline=1 ;;
    --uninstall)        uninstall=1 ;;
    -h|--help)          sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)                  die "Unknown option: $arg (try --help)" ;;
  esac
done

command -v jq >/dev/null || die "jq is required. Install it with: brew install jq (macOS) or your package manager."

mkdir -p "$CLAUDE_DIR"
backed_up=0
if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
  backed_up=1   # nothing worth backing up
fi
jq -e 'type == "object"' "$SETTINGS" >/dev/null 2>&1 \
  || die "$SETTINGS is not valid JSON. Fix it first, nothing was changed."

# Run a jq filter over settings.json. Backs up once per run, writes atomically.
edit_settings() {
  local tmp backup
  tmp="$(mktemp "$SETTINGS.XXXXXX")"
  if jq "$@" "$SETTINGS" > "$tmp" && jq -e 'type == "object"' "$tmp" >/dev/null; then
    if ! cmp -s "$tmp" "$SETTINGS"; then
      if [ "$backed_up" -eq 0 ]; then
        backup="$SETTINGS.jarvis-backup-$STAMP"
        [ -e "$backup" ] && backup="$backup-$$"
        cp "$SETTINGS" "$backup"
        warn "Backed up settings.json to $(basename "$backup")"
        backed_up=1
      fi
      mv "$tmp" "$SETTINGS"
      return 0
    fi
  fi
  rm -f "$tmp"
  return 1
}

# ---------------------------------------------------------------- uninstall
if [ "$uninstall" -eq 1 ]; then
  # Status line that --force-statusline replaced, put back on uninstall
  previous='null'
  [ -f "$PREVIOUS_SL" ] && previous="$(cat "$PREVIOUS_SL")"
  edit_settings --arg theme "$THEME_ID" --arg sl "$STATUSLINE" --argjson prev "$previous" '
    (if .theme == $theme then del(.theme) else . end)
    | (if .statusLine.command? == ("bash \"" + $sl + "\"")
        then (if $prev == null then del(.statusLine) else .statusLine = $prev end)
        else . end)
    | (if (.spinnerVerbs.verbs? // []) | index("Calibrating repulsors") then del(.spinnerVerbs) else . end)
  ' && say "Removed Jarvis HUD keys from settings.json" || say "settings.json had no Jarvis HUD keys"
  [ "$previous" != 'null' ] && say "Restored your previous status line"
  rm -f "$THEMES_DIR/jarvis-hud.json"
  rm -rf "$HUD_DIR"
  say "Removed theme and status line files"
  say "Done. Restart Claude Code to see the change."
  exit 0
fi

# ---------------------------------------------------------------- install

# 1. Theme
themes_dir_existed=1
[ -d "$THEMES_DIR" ] || themes_dir_existed=0
mkdir -p "$THEMES_DIR"
cp "$REPO/themes/jarvis-hud.json" "$THEMES_DIR/jarvis-hud.json"
say "Installed theme to ${THEMES_DIR/#$HOME/~}/jarvis-hud.json"

# 2. Status line script
mkdir -p "$HUD_DIR"
cp "$REPO/statusline/statusline.sh" "$STATUSLINE"
chmod +x "$STATUSLINE"
say "Installed status line to ${STATUSLINE/#$HOME/~}"

# 3. settings.json: theme and spinner verbs
edit_settings --arg theme "$THEME_ID" --slurpfile verbs "$REPO/spinner/verbs.json" \
  '.theme = $theme | .spinnerVerbs = $verbs[0]' || true
say "Set theme to Jarvis HUD and added spinner verbs"

# 4. settings.json: status line, without overwriting someone else's
sl_cmd="bash \"$STATUSLINE\""
current="$(jq -r '.statusLine.command? // empty' "$SETTINGS")"
if [ -n "$current" ] && [ "$current" != "$sl_cmd" ] && [ "$force_statusline" -eq 0 ]; then
  warn "You already have a status line, so it was left alone:"
  printf '    %s\n' "$current"
  warn "Run ./install.sh --force-statusline to replace it (settings.json is backed up first)."
else
  # Keep the replaced status line so --uninstall can restore it
  if [ -n "$current" ] && [ "$current" != "$sl_cmd" ]; then
    jq '.statusLine' "$SETTINGS" > "$PREVIOUS_SL"
  fi
  edit_settings --arg cmd "$sl_cmd" '.statusLine = {type: "command", command: $cmd}' || true
  say "Set the Jarvis HUD status line"
fi

if [ "$themes_dir_existed" -eq 0 ]; then
  say "Done. Restart Claude Code once so it picks up the new themes folder."
else
  say "Done. Open a new Claude Code session to see it."
fi
