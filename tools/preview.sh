#!/usr/bin/env bash
# Renders the status line with sample sessions, no Claude Code needed.
#   bash tools/preview.sh

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SL="$REPO/statusline/statusline.sh"

sample() {
  printf '{"model":{"display_name":"%s"},"effort":{"level":"%s"},"workspace":{"current_dir":"%s"},"context_window":{"used_percentage":%s,"context_window_size":%s}%s}' "$@"
}

show() { printf '  %-14s ' "$1"; shift; sample "$@" | bash "$SL"; printf '\n'; }

printf '\n'
show "fresh"    "Opus 5.5"   "high"   "$REPO" 4  1000000 ''
show "working"  "Opus 5.5"   "xhigh"  "$REPO" 31 1000000 ",\"rate_limits\":{\"five_hour\":{\"used_percentage\":23.5,\"resets_at\":$(( $(date +%s) + 4320 ))},\"seven_day\":{\"used_percentage\":41.2}}"
show "filling"  "Sonnet 5.5" "medium" "$HOME" 62 200000  ',"rate_limits":{"five_hour":{"used_percentage":58}}'
show "critical" "Haiku 5.5"  ""       "/tmp"  91 200000  ",\"rate_limits\":{\"five_hour\":{\"used_percentage\":86.2,\"resets_at\":$(( $(date +%s) + 1500 ))},\"seven_day\":{\"used_percentage\":83}}"
show "minimal"  "Claude"     ""       ""      null null  ''
printf '\n'
