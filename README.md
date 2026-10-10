# Claude Code Jarvis HUD

A sci-fi HUD look for **Claude Code**, inspired by the holographic interfaces in the Iron Man and Avengers films. Arc-reactor cyan on near-black, a HUD status line with a live context gauge, and J.A.R.V.I.S. lines in the spinner while Claude works.

Works in any terminal: Terminal.app, iTerm2, Ghostty, Warp, the VS Code terminal and Linux.

Part of a set:

- [Terminal Jarvis HUD](https://github.com/andyjohansson/terminal-jarvis-hud): the matching macOS Terminal profile, Starship prompt and start banner
- [Obsidian Jarvis HUD](https://github.com/andyjohansson/obsidian-jarvis-hud): the same look for your notes

<!-- TODO: demo GIF in screenshots/ -->

## What's included

| Part | File | What it does |
|---|---|---|
| Color theme | `themes/jarvis-hud.json` | Recolors Claude Code itself: spinner, startup mascot, borders, text, diffs, plan mode, skills, subagent colors, message backgrounds |
| Status line | `statusline/statusline.sh` | Model, effort, context gauge, git branch, folder and 5-hour usage |
| Spinner verbs | `spinner/verbs.json` | "Calibrating repulsors", "Routing power to the arc reactor" and 62 more |
| Installer | `install.sh` | Sets it all up, backs up your settings, safe to run again |

The status line only uses standard Unicode symbols, so no Nerd Font is needed.

```
◆ Opus 5.5 · high ⟨▰▰▰▱▱▱▱▱▱▱⟩ 31% 310k/1M ┊ ⎇ main ● ┊ ~/Dev/my-project ┊ 5h 23%
```

The context gauge and the 5-hour usage turn **gold** at 50% and **red** at 80%. Parts that Claude Code doesn't report are left out.

## Install

```bash
git clone https://github.com/andyjohansson/claude-code-jarvis-hud.git ~/Dev/claude-code-jarvis-hud
cd ~/Dev/claude-code-jarvis-hud
./install.sh
```

The installer:

1. Copies the theme to `~/.claude/themes/jarvis-hud.json`
2. Copies the status line to `~/.claude/jarvis-hud/statusline.sh`
3. Backs up `~/.claude/settings.json`, then sets `theme`, `spinnerVerbs` and `statusLine`. Your other settings, hooks and permissions are left as they are.

If `~/.claude/themes` didn't exist before, restart Claude Code once so it finds the theme. You can switch themes any time with `/theme`.

If you already have a status line, it is kept. To use the Jarvis HUD one instead:

```bash
./install.sh --force-statusline
```

Your old status line is saved and comes back if you uninstall.

It needs [jq](https://jqlang.org), which ships with macOS 15 and later. Otherwise run `brew install jq` or use your package manager.

## Preview

```bash
bash tools/preview.sh
```

Renders the status line for a few sample sessions (fresh, working, filling up, critical) without starting Claude Code.

## Customize

| What | How |
|---|---|
| Switch themes | `/theme` in Claude Code. Jarvis HUD is listed among the custom themes |
| Tweak colors | Edit `~/.claude/themes/jarvis-hud.json`. Claude Code reloads it live. See the [color tokens](https://code.claude.com/docs/en/terminal-config#create-a-custom-theme) |
| Keep the built-in verbs too | Set `"mode": "append"` in `spinner/verbs.json` and run `./install.sh` again |
| Write your own verbs | Edit the list in `spinner/verbs.json` and run `./install.sh` again |

## Palette

| Role | Color |
|---|---|
| Accent, spinner | `#00D8FF` |
| Shimmer, plan mode | `#7DEEFF` |
| Text | `#D4F3FF` |
| Muted | `#6F93A5` |
| Dim, borders | `#2F5566` |
| Success | `#3DFFB8` |
| Warning, your label | `#FFD75F` |
| Error | `#FF4D5E` |
| Subagents | HUD tones of red, blue, green, yellow, purple, orange, pink and cyan |

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

Removes the theme, the status line and the spinner verbs, and restores your previous status line if the installer replaced one. Your `settings.json` backups are kept.

## Credits

Not affiliated with Marvel, Disney or Anthropic, the name is a nod to the films.

## License

[MIT](LICENSE)
