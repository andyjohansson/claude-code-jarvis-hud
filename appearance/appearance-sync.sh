#!/usr/bin/env bash
# ======================================================================
#  JARVIS HUD  ·  follow macOS dark and light mode
#  Run by a LaunchAgent when the system appearance may have changed.
#  Only switches between the two Jarvis HUD themes. If you picked any
#  other theme in /theme, it leaves your choice alone.
# ======================================================================

SETTINGS="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"
NIGHT="custom:jarvis-hud"
DAY="custom:jarvis-hud-day"

[ -f "$SETTINGS" ] || exit 0
command -v jq >/dev/null || exit 0

if [ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" = "Dark" ]; then
  want="$NIGHT"
else
  want="$DAY"
fi

current="$(jq -r '.theme // empty' "$SETTINGS" 2>/dev/null)" || exit 0
[ "$current" = "$NIGHT" ] || [ "$current" = "$DAY" ] || exit 0
[ "$current" = "$want" ] && exit 0

tmp="$(mktemp "$SETTINGS.XXXXXX")" || exit 0
if jq --arg t "$want" '.theme = $t' "$SETTINGS" > "$tmp" && jq -e 'type == "object"' "$tmp" >/dev/null; then
  mv "$tmp" "$SETTINGS"
else
  rm -f "$tmp"
fi
