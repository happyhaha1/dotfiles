# Dracula Purple

An Omarchy theme that uses the Dracula palette with **Dracula's purple
(`#bd93f9`) as the accent color** instead of the cyan (`#8be9fd`) that
[catlee/omarchy-dracula-theme](https://github.com/catlee/omarchy-dracula-theme)
uses.

Managed by chezmoi at `~/.config/omarchy/themes/dracula-purple/`; Omarchy's
`omarchy theme set dracula-purple` picks it up like any other user theme. It is
not a Git checkout, so `omarchy theme update` leaves it alone.

## What is in here

| File | Purpose |
| --- | --- |
| `colors.toml` | The Dracula palette with `accent = "#bd93f9"` and a solid purple `hyprland_active_border`. Omarchy renders every other config (Hyprland, shell/waybar, terminals, btop, tmux, VS Code, Obsidian, ...) from these keys. |
| `pi.json` | Pinned Pi theme. `omarchy-theme-set-pi` copies the current theme's `pi.json` to `~/.pi/agent/themes/omarchy-system.json`, so Pi shows Pi's Dracula theme exactly (see below). |
| `gtk.css` | Dracula surface hierarchy for GTK3/GTK4 apps, accent on the purple. Opt in with `ln -s ~/.local/state/omarchy/current/theme/gtk.css ~/.config/gtk-4.0/gtk.css`. |
| `icons.theme` | `Yaru-purple` folder icons. |
| `backgrounds/base.png` | Dracula moon-and-bats wallpaper. |
| `unlock.png`, `preview-unlock.png` | Unlock (Plymouth) artwork. |

Files Omarchy's templates generate (`shell.toml`, `btop.theme`, `neovim.lua`,
`chromium.theme`, terminal configs, ...) are deliberately not vendored here, so
they keep following `colors.toml`.

## Pi

With the stock Omarchy template, Pi's `omarchy-system` theme is built from the
theme palette but with Omarchy's own role mapping, which differs from the Dracula
theme Pi ships in `@sherif-fanous/pi-dracula`. `pi.json` here is that Dracula
theme (identical colors, only `name` is `omarchy-system`), and because a theme's
own file wins over a generated template, Pi follows the desktop palette and
still looks exactly like Pi's Dracula.

## Provenance

- Palette: Dracula (https://draculatheme.com).
- `colors.toml` structure, `gtk.css`, `icons.theme`, `unlock.png`,
  `preview-unlock.png` and `backgrounds/base.png` come from
  https://github.com/catlee/omarchy-dracula-theme.
- `pi.json` comes from https://github.com/sherif-fanous/pi-dracula (MIT).
