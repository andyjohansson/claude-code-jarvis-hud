#!/usr/bin/env bash
# ======================================================================
#  JARVIS HUD  ·  installer for Claude Code
#  Safe to run more than once. Backs up settings.json before changing it.
#
#    ./install.sh                     themes, status line, spinner verbs and tips
#    ./install.sh --auto-theme        also follow macOS dark and light mode
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
TIPS="$HUD_DIR/tips.json"
SYNC="$HUD_DIR/appearance-sync.sh"
PREVIOUS_SL="$HUD_DIR/previous-statusline.json"
NIGHT="custom:jarvis-hud"
DAY="custom:jarvis-hud-day"
AGENT_LABEL="com.github.andyjohansson.claude-code-jarvis-hud.appearance"
AGENT_PLIST="$HOME/Library/LaunchAgents/$AGENT_LABEL.plist"
STAMP="$(date +%Y%m%d-%H%M%S)"

cyan=$'\e[38;2;0;216;255m'; gold=$'\e[38;2;255;215;95m'; red=$'\e[38;2;255;77;94m'; r=$'\e[0m'
say()  { printf '%s\n' "${cyan}◆${r} $*"; }
warn() { printf '%s\n' "${gold}!${r} $*"; }
die()  { printf '%s\n' "${red}✕${r} $*" >&2; exit 1; }

force_statusline=0
auto_theme=0
uninstall=0
for arg in "$@"; do
  case "$arg" in
    --force-statusline) force_statusline=1 ;;
    --auto-theme)       auto_theme=1 ;;
    --uninstall)        uninstall=1 ;;
    -h|--help)          sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)                  die "Unknown option: $arg (try --help)" ;;
  esac
done

command -v jq >/dev/null || die "jq is required. Install it with: brew install jq (macOS) or your package manager."
if [ "$auto_theme" -eq 1 ] && [ "$(uname)" != "Darwin" ]; then
  die "--auto-theme follows macOS dark and light mode, so it only works on macOS."
fi

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

remove_agent() {
  if [ -f "$AGENT_PLIST" ]; then
    launchctl bootout "gui/$(id -u)" "$AGENT_PLIST" 2>/dev/null || true
    rm -f "$AGENT_PLIST"
    say "Stopped following macOS dark and light mode"
  fi
}

# ---------------------------------------------------------------- uninstall
if [ "$uninstall" -eq 1 ]; then
  # Status line that --force-statusline replaced, put back on uninstall
  previous='null'
  [ -f "$PREVIOUS_SL" ] && previous="$(cat "$PREVIOUS_SL")"
  edit_settings --arg night "$NIGHT" --arg day "$DAY" --arg sl "$STATUSLINE" \
    --arg tips "$TIPS" --argjson prev "$previous" '
    (if .theme == $night or .theme == $day then del(.theme) else . end)
    | (if .statusLine.command? == ("bash \"" + $sl + "\"")
        then (if $prev == null then del(.statusLine) else .statusLine = $prev end)
        else . end)
    | (if (.spinnerVerbs.verbs? // []) | index("Calibrating repulsors") then del(.spinnerVerbs) else . end)
    | (if .spinnerTipsOverride.tipsFile? == $tips then del(.spinnerTipsOverride) else . end)
  ' && say "Removed Jarvis HUD keys from settings.json" || say "settings.json had no Jarvis HUD keys"
  [ "$previous" != 'null' ] && say "Restored your previous status line"
  [ "$(uname)" = "Darwin" ] && remove_agent
  rm -f "$THEMES_DIR/jarvis-hud.json" "$THEMES_DIR/jarvis-hud-day.json"
  rm -rf "$HUD_DIR"
  say "Removed themes, status line and tips"
  say "Done. Restart Claude Code to see the change."
  exit 0
fi

# ---------------------------------------------------------------- install

# 1. Themes
themes_dir_existed=1
[ -d "$THEMES_DIR" ] || themes_dir_existed=0
mkdir -p "$THEMES_DIR"
cp "$REPO/themes/jarvis-hud.json" "$REPO/themes/jarvis-hud-day.json" "$THEMES_DIR/"
say "Installed Jarvis HUD and Jarvis HUD Day themes to ${THEMES_DIR/#$HOME/~}"

# 2. Status line script and tips
mkdir -p "$HUD_DIR"
cp "$REPO/statusline/statusline.sh" "$STATUSLINE"
chmod +x "$STATUSLINE"
cp "$REPO/spinner/tips.json" "$TIPS"
say "Installed status line and tips to ${HUD_DIR/#$HOME/~}"

# 3. settings.json: theme (keeps Day if you already use it) and spinner verbs
edit_settings --arg night "$NIGHT" --arg day "$DAY" --slurpfile verbs "$REPO/spinner/verbs.json" '
  (if .theme == $day then . else .theme = $night end)
  | .spinnerVerbs = $verbs[0]
' || true
say "Set the Jarvis HUD theme and spinner verbs"

# 4. settings.json: tips, without overwriting someone else's
current_tips="$(jq -r '.spinnerTipsOverride // empty | tostring' "$SETTINGS")"
if [ -n "$current_tips" ] && [ "$(jq -r '.spinnerTipsOverride.tipsFile? // empty' "$SETTINGS")" != "$TIPS" ]; then
  warn "You already have custom spinner tips, so they were left alone."
else
  edit_settings --arg tips "$TIPS" '.spinnerTipsOverride = {label: "J.A.R.V.I.S.", tipsFile: $tips}' || true
  say "Added J.A.R.V.I.S. tips under the spinner"
fi

# 5. settings.json: status line, without overwriting someone else's.
#    Refreshes every 30 s so the reset countdown stays current while idle.
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
  edit_settings --arg cmd "$sl_cmd" '.statusLine = {type: "command", command: $cmd, refreshInterval: 30}' || true
  say "Set the Jarvis HUD status line"
fi

# 6. Optional: follow macOS dark and light mode
if [ "$auto_theme" -eq 1 ]; then
  cp "$REPO/appearance/appearance-sync.sh" "$SYNC"
  chmod +x "$SYNC"
  mkdir -p "$(dirname "$AGENT_PLIST")"
  cat > "$AGENT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$AGENT_LABEL</string>
  <key>ProgramArguments</key>
  <array><string>/bin/bash</string><string>$SYNC</string></array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>CLAUDE_CONFIG_DIR</key><string>$CLAUDE_DIR</string>
    <key>PATH</key><string>/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin</string>
  </dict>
  <key>WatchPaths</key>
  <array><string>$HOME/Library/Preferences/.GlobalPreferences.plist</string></array>
  <key>StartInterval</key><integer>60</integer>
  <key>RunAtLoad</key><true/>
</dict>
</plist>
EOF
  launchctl bootout "gui/$(id -u)" "$AGENT_PLIST" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$AGENT_PLIST"
  bash "$SYNC"
  say "Following macOS dark and light mode (Jarvis HUD at night, Jarvis HUD Day by day)"
fi

if [ "$themes_dir_existed" -eq 0 ]; then
  say "Done. Restart Claude Code once so it picks up the new themes folder."
else
  say "Done. Open a new Claude Code session to see it."
fi
