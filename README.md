# Claude Code Jarvis HUD

A sci-fi HUD look for **Claude Code**, inspired by the holographic interfaces in the Iron Man and Avengers films. Arc-reactor cyan on near-black, a HUD status line with a live context gauge, and J.A.R.V.I.S. lines and tips in the spinner while Claude works. Comes with a light Day variant that can follow macOS dark and light mode.

Works in any terminal: Terminal.app, iTerm2, Ghostty, Warp, the VS Code terminal and Linux.

Part of a set:

- [Terminal Jarvis HUD](https://github.com/andyjohansson/terminal-jarvis-hud): the matching macOS Terminal profile, Starship prompt and start banner
- [Obsidian Jarvis HUD](https://github.com/andyjohansson/obsidian-jarvis-hud): the same look for your notes

<!-- TODO: demo GIF in screenshots/ -->

## What's included

| Part | File | What it does |
|---|---|---|
| Color themes | `themes/jarvis-hud.json`, `themes/jarvis-hud-day.json` | Recolors Claude Code itself: spinner, startup mascot, borders, text, diffs, plan mode, skills, subagent colors, message backgrounds |
| Status line | `statusline/statusline.sh` | Model, effort, context gauge, git branch, folder, 5-hour usage with reset countdown, and 7-day usage |
| Spinner verbs | `spinner/verbs.json` | "Calibrating repulsors", "Building it in a cave with a box of scraps" and 70 more |
| Spinner tips | `spinner/tips.json` | Useful Claude Code tips in J.A.R.V.I.S.'s voice, shown alongside the built-in tips |
| Arc reactor spinner | `mod/jarvis-reactor/` | Optional. Replaces the working spinner with a two-line arc reactor, installed as a Claude Code plugin |
| Appearance sync | `appearance/appearance-sync.sh` | Optional. Switches between Jarvis HUD and Jarvis HUD Day with macOS dark and light mode |
| Installer | `install.sh` | Sets it all up, backs up your settings, safe to run again |

The status line only uses standard Unicode symbols, so no Nerd Font is needed.

```
◆ Opus 5.5 · high ⟨▰▰▰▱▱▱▱▱▱▱⟩ 31% 310k/1M ┊ ⎇ main ● ┊ ~/Dev/my-project ┊ 5h 23% ↻1h12m ┊ 7d 41%
```

The context gauge and the usage limits turn **gold** at 50% and **red** at 80%. `↻` counts down to when the 5-hour limit resets. Parts that Claude Code doesn't report are left out, and the colors switch to a matching palette when the Day theme is active.

## Install

```bash
git clone https://github.com/andyjohansson/claude-code-jarvis-hud.git ~/Dev/claude-code-jarvis-hud
cd ~/Dev/claude-code-jarvis-hud
./install.sh
```

The installer:

1. Copies both themes to `~/.claude/themes/`
2. Copies the status line and tips to `~/.claude/jarvis-hud/`
3. Backs up `~/.claude/settings.json`, then sets `theme`, `spinnerVerbs`, `spinnerTipsOverride` and `statusLine`. Your other settings, hooks and permissions are left as they are.

If `~/.claude/themes` didn't exist before, restart Claude Code once so it finds the theme. You can switch themes any time with `/theme`.

If you already have a status line or custom spinner tips, they are kept. To use the Jarvis HUD status line instead:

```bash
./install.sh --force-statusline
```

Your old status line is saved and comes back if you uninstall.

### Follow macOS dark and light mode

```bash
./install.sh --auto-theme
```

Installs a small LaunchAgent that switches between **Jarvis HUD** (dark) and **Jarvis HUD Day** (light) when macOS changes appearance. It only switches between the two Jarvis themes, so if you pick another theme in `/theme`, it leaves your choice alone. Claude Code's built-in `auto` theme can't switch between custom themes yet ([#93034](https://github.com/anthropics/claude-code/issues/93034)), which is why this exists.

Jarvis HUD Day is made for a light terminal background. Use `--auto-theme` only if your terminal also switches to a light background in light mode, as Ghostty, iTerm2 and WezTerm can. Apple Terminal keeps one profile, so with a dark profile like [Terminal Jarvis HUD](https://github.com/andyjohansson/terminal-jarvis-hud), stay on Jarvis HUD.

It needs [jq](https://jqlang.org), which ships with macOS 15 and later. Otherwise run `brew install jq` or use your package manager.

### Arc reactor spinner

```
⠔⡁⢍⢂ Calibrating repulsors…
⠣⢑⣈⠘ (12s · esc to interrupt)
```

An optional mod that replaces Claude Code's working spinner with the arc reactor from [Obsidian Jarvis HUD](https://github.com/andyjohansson/obsidian-jarvis-hud), drawn in braille dots across two lines: an outer ring of segments sweeping clockwise and two inner arcs turning the other way. Type this at the Claude Code prompt:

```
/plugin install jarvis-reactor --marketplace andyjohansson/claude-code-jarvis-hud
```

Answer `y` to add the marketplace, then pick **user scope** so the reactor runs in every session. Remove it with `/plugin uninstall jarvis-reactor`.

It uses Claude Code's mod API, which is in early access and may change between releases. In the desktop app, Claude Code keeps its own spinner. The reactor line shows elapsed time but not the token count, which mods can't read yet.

## Preview

```bash
bash tools/preview.sh
```

Renders the status line for a few sample sessions (fresh, working, filling up, critical) without starting Claude Code.

## Customize

| What | How |
|---|---|
| Switch themes | `/theme` in Claude Code. Jarvis HUD and Jarvis HUD Day are listed among the custom themes |
| Tweak colors | Edit `~/.claude/themes/jarvis-hud.json`. Claude Code reloads it live. See the [color tokens](https://code.claude.com/docs/en/terminal-config#create-a-custom-theme) |
| Keep the built-in verbs too | Set `"mode": "append"` in `spinner/verbs.json` and run `./install.sh` again |
| Write your own verbs | Edit the list in `spinner/verbs.json` and run `./install.sh` again |
| Edit the tips | Edit `spinner/tips.json` and run `./install.sh` again. Claude Code reads tips when a session starts |
| Turn tips off | `"spinnerTipsEnabled": false` in `~/.claude/settings.json` hides all tips |

## Palette

| Role | Jarvis HUD | Jarvis HUD Day |
|---|---|---|
| Accent, spinner | `#00D8FF` | `#0086B3` |
| Shimmer, plan mode | `#7DEEFF` | `#0077A3` |
| Text | `#D4F3FF` | `#0B2733` |
| Muted | `#6F93A5` | `#557A8C` |
| Dim, borders | `#2F5566` | `#9FBCCB` |
| Success | `#3DFFB8` | `#00875A` |
| Warning, your label | `#FFD75F` | `#A66B00` |
| Error | `#FF4D5E` | `#D62839` |
| Subagents | HUD tones of red, blue, green, yellow, purple, orange, pink and cyan | Same, darker for light backgrounds |

## Known limitations

As of 2026-10-10, tested with Claude Code 2.1.296:

- **Inline code and other markdown in Claude's replies keep Claude Code's default lavender.** Markdown is colored from the built-in dark palette even when a custom theme is active, so no theme file can change it. Reported in [anthropics/claude-code#73837](https://github.com/anthropics/claude-code/issues/73837).
- **Diff backgrounds keep the default green and red.** The theme sets HUD teal and crimson, but Claude Code's diff view ignores custom overrides. Reported in [#85660](https://github.com/anthropics/claude-code/issues/85660).
- **The ultracode badge stays purple.** Its color ignores custom overrides. Reported in [#70398](https://github.com/anthropics/claude-code/issues/70398).
- **Apple Terminal shows 256 colors.** Claude Code limits Terminal.app to the 256-color palette, so some shades are rounded. Terminals with full color support, such as iTerm2 and Ghostty, show the exact colors.

## Uninstall

```bash
./install.sh --uninstall
```

Removes the themes, status line, spinner verbs, tips and the appearance LaunchAgent, and restores your previous status line if the installer replaced one. Your `settings.json` backups are kept.

## Credits

Not affiliated with Marvel, Disney or Anthropic, the name is a nod to the films.

## License

[MIT](LICENSE)
