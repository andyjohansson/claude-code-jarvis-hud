#!/usr/bin/env bash
# ======================================================================
#  JARVIS HUD  ·  Claude Code status line
#  Reads session JSON on stdin, prints one HUD line.
#  Needs bash and jq. Works with any font (no Nerd Font needed).
# ======================================================================

input=$(cat)

# One jq call, unit-separator delimited so empty fields keep their place
IFS=$'\x1f' read -r model effort pct size cwd five_h five_reset seven_d <<EOF
$(printf '%s' "$input" | jq -r '[
  (.model.display_name // "Claude"),
  (.effort.level // ""),
  (.context_window.used_percentage // "" | tostring),
  (.context_window.context_window_size // "" | tostring),
  (.workspace.current_dir // .cwd // ""),
  (.rate_limits.five_hour.used_percentage // "" | tostring),
  (.rate_limits.five_hour.resets_at // "" | tostring),
  (.rate_limits.seven_day.used_percentage // "" | tostring)
] | join("\u001f")' 2>/dev/null)
EOF

# Palette, same as the Terminal profile and Starship prompt.
# Switches to the Day palette when the Jarvis HUD Day theme is active.
e=$'\e'
theme=$(jq -r '.theme // empty' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json" 2>/dev/null)
if [ "$theme" = "custom:jarvis-hud-day" ]; then
  cyan="$e[38;2;0;134;179m"
  text="$e[38;2;11;39;51m"
  dim="$e[38;2;159;188;203m"
  muted="$e[38;2;85;122;140m"
  gold="$e[38;2;166;107;0m"
  red="$e[38;2;214;40;57m"
else
  cyan="$e[38;2;0;216;255m"
  text="$e[38;2;212;243;255m"
  dim="$e[38;2;47;85;102m"
  muted="$e[38;2;111;147;165m"
  gold="$e[38;2;255;215;95m"
  red="$e[38;2;255;77;94m"
fi
bold="$e[1m"
r="$e[0m"

sep=" ${dim}┊${r} "

# Cyan below 50%, gold from 50%, red from 80%
level_color() {
  if   [ "$1" -ge 80 ]; then printf '%s' "$red"
  elif [ "$1" -ge 50 ]; then printf '%s' "$gold"
  else printf '%s' "$cyan"; fi
}

# 1000000 -> 1M, 310000 -> 310k
human() {
  if   [ "$1" -ge 1000000 ] && [ $(( $1 % 1000000 )) -eq 0 ]; then printf '%dM' $(( $1 / 1000000 ))
  elif [ "$1" -ge 1000 ]; then printf '%dk' $(( $1 / 1000 ))
  else printf '%d' "$1"; fi
}

# ◆ Model · effort. "Opus 5.5 (1M context)" becomes "Opus 5.5", the gauge shows the size
model="${model% (*}"
out="${bold}${cyan}◆${r} ${bold}${text}${model}${r}"
[ -n "$effort" ] && out="${out} ${dim}·${r} ${muted}${effort}${r}"

# ⟨▰▰▰▱▱▱▱▱▱▱⟩ 31% 310k/1M
if [ -n "$pct" ]; then
  p=${pct%.*}; [ -z "$p" ] && p=0
  [ "$p" -gt 100 ] && p=100
  filled=$(( (p + 5) / 10 )); [ "$filled" -gt 10 ] && filled=10
  bar=""; i=0
  while [ $i -lt 10 ]; do
    if [ $i -lt $filled ]; then bar="${bar}▰"; else bar="${bar}▱"; fi
    i=$(( i + 1 ))
  done
  c=$(level_color "$p")
  out="${out} ${dim}⟨${r}${c}${bar}${r}${dim}⟩${r} ${c}${p}%${r}"
  if [ -n "$size" ] && [ "$size" -gt 0 ] 2>/dev/null; then
    used=$(( p * size / 100 ))
    out="${out} ${muted}$(human "$used")/$(human "$size")${r}"
  fi
fi

# ⎇ branch ●
if [ -n "$cwd" ] && branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null); then
  [ -z "$branch" ] && branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    out="${out}${sep}${cyan}⎇ ${branch}${r}"
    if [ -n "$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | head -n 1)" ]; then
      out="${out} ${gold}●${r}"
    fi
  fi
fi

# …/last/three/dirs
if [ -n "$cwd" ]; then
  d="$cwd"
  case "$d" in "$HOME"*) d="~${d#"$HOME"}" ;; esac
  IFS='/' read -r -a parts <<< "$d"
  n=${#parts[@]}
  if [ "$n" -gt 3 ]; then
    d="…/${parts[$((n-3))]}/${parts[$((n-2))]}/${parts[$((n-1))]}"
  fi
  out="${out}${sep}${bold}${text}${d}${r}"
fi

# 5h 23% ↻1h12m ┊ 7d 41%, only what Claude Code reports
if [ -n "$five_h" ]; then
  f=${five_h%.*}; [ -z "$f" ] && f=0
  out="${out}${sep}${muted}5h${r} $(level_color "$f")${f}%${r}"
  if [ -n "$five_reset" ]; then
    left=$(( ${five_reset%.*} - $(date +%s) ))
    if [ "$left" -gt 0 ]; then
      h=$(( left / 3600 )); m=$(( left % 3600 / 60 ))
      if [ "$h" -gt 0 ]; then t="${h}h$(printf '%02d' "$m")m"; else t="${m}m"; fi
      out="${out} ${dim}↻${r}${muted}${t}${r}"
    fi
  fi
fi
if [ -n "$seven_d" ]; then
  s=${seven_d%.*}; [ -z "$s" ] && s=0
  out="${out}${sep}${muted}7d${r} $(level_color "$s")${s}%${r}"
fi

printf '%s' "$out"
