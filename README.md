# hypr-dots

A Hyprland rice for Arch Linux — Waybar, Rofi, SwayNC, Kitty, with a Gruvbox-inspired aesthetic. Config written in Hyprland's native Lua syntax (requires Hyprland 0.55+).

![Hyprland Desktop](assets/screenshots/desktop.png)

## Features

- **Hyprland** compositor (Lua config) with custom animations, gaps, blur
- **Waybar** with workspace switcher, cava audio visualizer, tray drawer, network/clock/battery
- **Rofi** app launcher, emoji picker, window switcher, and custom menus (Wi-Fi, keybinds, rice quick-actions)
- **SwayNC** notification center
- **Kitty** terminal + **Fish** shell + **Starship** prompt
- **Fastfetch** / **btop** system info
- **Waypaper** wallpaper manager
- **Hyprlock** screen lock + **Hypridle** idle daemon + **Wlogout** power menu
- **Hyprshot** screenshots + **Hyprpicker** color picker
- Bibata cursor theme

## Requirements

- **Arch Linux** (or Arch-based: EndeavourOS, CachyOS, Garuda)
- **Hyprland 0.55+** (for native Lua config support)
- An **AUR helper** — `paru` or `yay` (installer installs `yay` if neither is found)
- A display manager (SDDM, GDM, Ly) or a TTY to launch Hyprland from

> **Not on Arch?** Install the equivalent packages yourself (see `packages.txt` and `aur-packages.txt`), then run `./install.sh --no-deps`.

## Install (one command)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ratto-101/hypr-dots/main/install.sh)"
```

This will:
1. Clone the repo to `~/.local/share/hypr-dots`
2. Install all pacman + AUR dependencies
3. Back up your existing `~/.config/` to `~/.config-backup-<timestamp>/`
4. Symlink the rice's configs into `~/.config/`, `~/.local/bin/`, etc.

Then **log out** and select **Hyprland** from your display manager (or run `Hyprland` from a TTY).

## Install (manual clone)

```bash
git clone https://github.com/ratto-101/hypr-dots.git
cd hypr-dots
./install.sh
```

### Installer flags

| Flag | Effect |
|------|--------|
| `--no-deps` | Skip package install, only deploy configs |
| `--no-backup` | Overwrite existing configs without making backups |
| `--uninstall` | Remove symlinks (backups stay in `~/.config-backup-*`) |
| `-h`, `--help` | Show help |

## Keybindings

| Key | Action |
|-----|--------|
| `Super + Enter` | Terminal (Kitty) |
| `Super + W` | Browser (Brave Origin) |
| `Super + E` | File manager (Nautilus) |
| `Super + T` | Text editor |
| `Super + C` | Calculator |
| `Super + Space` | App launcher (Rofi) |
| `Super + Period` | Emoji picker |
| `Super + Tab` | Window switcher (Rofi) |
| `Super + Q` | Close window |
| `Super + F` | Fullscreen |
| `Super + D` | Internal fullscreen |
| `Super + Alt + Space` | Toggle floating |
| `Super + J` | Toggle split |
| `Super + Arrows` | Move focus |
| `Super + Shift + Arrows` | Move window |
| `Super + 1-0` | Switch to workspace 1-10 |
| `Super + S` | Toggle scratchpad |
| `Super + Shift + S` | Move window to scratchpad |
| `Super + L` | Lock screen (Hyprlock) |
| `Super + Alt + C` | Power menu (Wlogout) |
| `Super + X` / `Super + A` | Toggle notification center |
| `Super + V` | Clipboard history |
| `Super + P` | Color picker |
| `Print` | Screenshot full screen |
| `Super + Print` | Screenshot window |
| `Super + Shift + X` | Screenshot region |
| `Super + Shift + W` | Wallpaper selector |
| `Super + Shift + P` | Toggle power profile |
| `Super + Shift + L` | Toggle laptop mode |
| `Super + Shift + M` | Rice quick-actions menu |
| `Super + Shift + /` | Keybinds cheat sheet |
| `Super + R` | Restart Waybar |
| `Super + Shift + Esc` | btop in Kitty |
| `Ctrl + Alt + Delete` | Power menu |

> **Tip:** Press `Super + Shift + /` anytime to see all keybinds in a rofi menu.

## Customisation

All configs are symlinked from `~/.local/share/hypr-dots/` into your `~/.config/`. Edit files in the repo directory so changes survive updates.

| What | Where |
|------|-------|
| Hyprland config (Lua) | `~/.config/hypr/hyprland.lua` |
| Default apps | `~/.config/hypr/config/variables.lua` |
| Keybinds | `~/.config/hypr/config/binds.lua` |
| Autostart | `~/.config/hypr/config/autostart.lua` |
| Environment vars | `~/.config/hypr/config/environment.lua` |
| Window rules | `~/.config/hypr/config/windowrules.lua` |
| Waybar modules | `~/.config/waybar/config.jsonc` |
| Waybar styling | `~/.config/waybar/style.css` |
| Rofi theme | `~/.config/rofi/` |
| Shell prompt | `~/.config/starship.toml` |

## Uninstall

```bash
~/.local/share/hypr-dots/install.sh --uninstall
```

Removes the symlinks. Your original configs are preserved in `~/.config-backup-<timestamp>/`. Packages are left installed — remove manually with `paru -Rs <pkg>` if you want.

## Credits

- Built on [Hyprland](https://hyprland.org) by Vaxry
- Config structure inspired by [CachyOS's Hyprland defaults](https://github.com/CachyOS/cachyos-hyprland-settings)
- Cursor: [Bibata](https://github.com/ful1e5/Bibata_Cursor)
- Fonts: [JetBrains Mono Nerd Font](https://www.nerdfonts.com/)

## License

MIT — see [LICENSE](LICENSE).
