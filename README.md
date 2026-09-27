# TaianDotFilesNiri

Personal dotfiles for **niri** (Wayland compositor) on **Fedora**, with a
Quickshell-based desktop shell (bar, launcher, lockscreen, popups), matugen +
pywal dynamic theming, and a wlogout power menu.

## Components

| Area | Tool |
| --- | --- |
| Compositor | `niri` |
| Shell | `quickshell` (bar, launcher, notifications, network, music, lockscreen) |
| Idle/lock | `swayidle` + Quickshell lockscreen |
| Theming | `matugen` (primary) + `pywal`/`wal` (kitty) |
| Wallpaper | `awww` |
| Power menu | `wlogout` |
| Terminal | `kitty` (backup: `alacritty`) |
| Shell | `zsh` + `starship` + `zinit` |
| Clipboard | `clipse` + `wl-clipboard` |

## Requirements

See [`PACKAGES.md`](PACKAGES.md) for the essential Fedora packages. `install.sh`
installs them automatically.

## Install

```bash
./install.sh [--no-weak-deps]
```

The script:

1. Installs the essential Fedora packages (see `PACKAGES.md`) with `dnf install`.
   - `--no-weak-deps` passes `--setopt=install_weak_deps=False` to dnf.
2. Installs **JetBrainsMono Nerd Font** and the **Sunset-cursors** theme
   separately (they are intentionally *not* stowed).
   - For the cursor, set `SUNSET_CURSORS_SRC=/path/to/Sunset-cursors` if you
     keep a local copy.
3. Backs up conflicting configs (`~/.config/<pkg>`, `~/.zshrc`, `~/Pictures/Wallpapers`).
4. Stows the packages with `--no-folding` (so generated files stay out of the repo).
5. Seeds the theme once with a wallpaper.
6. Enables `hyprpolkitagent`.

Packages that could not be installed are printed at the end and written to
`failed-packages.txt` (gitignored) for manual handling.

User applications (`alacritty`, `nemo`, `zen-browser`, `qt6ct`, tray applets,
etc.) are **not** installed by the script; install them manually.

Manual equivalent:

```bash
stow --no-folding niri quickshell wlogout matugen kitty gtk-3.0 gtk-4.0 \
     fastfetch clipse zsh wallpapers
```

## Stow packages

- `niri` → `~/.config/niri` (+ `~/.config/xdg-desktop-portal/niri-portals.conf`)
- `quickshell` → `~/.config/quickshell`
- `wlogout` → `~/.config/wlogout`
- `matugen` → `~/.config/matugen`
- `kitty` → `~/.config/kitty`
- `gtk-3.0`, `gtk-4.0` → `~/.config/gtk-3.0`, `~/.config/gtk-4.0`
- `fastfetch` → `~/.config/fastfetch`
- `clipse` → `~/.config/clipse`
- `zsh` → `~/.zshrc`
- `wallpapers` → `~/Pictures/Wallpapers`

## Session

The session is started by **greetd** (with `tuigreet`) → **`niri-session`**, not
by running `niri` directly. `niri-session` runs niri as a systemd user service,
which activates `graphical-session.target`; that is what lets
`xdg-desktop-portal` (and therefore flatpaks) work.

This requires `greetd` enabled as the display manager and the default systemd
target set to `graphical.target`:

```bash
sudo systemctl enable greetd
sudo systemctl set-default graphical.target
```

## Theming

- **matugen** generates: `~/.local/state/quickshell/Theme.qml`, `wlogout/colors.css`,
  `gtk-3.0/gtk.css`, `gtk-4.0/gtk.css`, `niri/colors.kdl`, `swayosd/style.css`.
- **pywal** generates kitty colors (`~/.cache/wal/colors-kitty.conf`), which
  `kitty.conf` includes. Both generators run together in
  `quickshell/scripts/apply_wallpaper.sh` when you pick a wallpaper.
- All generated files are **gitignored**; regenerate them with:

  ```bash
  matugen image /path/to/wallpaper.jpg --source-color-index 0
  wal -qste -i /path/to/wallpaper.jpg
  ```

## Locking

Locking always goes through a single helper:

```bash
~/.config/quickshell/scripts/session-lock.sh
```

It is used by the niri keybind (`Super+L`), `wlogout`, `swayidle` (via
`niri/.config/niri/scripts/idle.sh`) and the Quickshell `SessionService`.

## Key bindings (selected)

| Bind | Action |
| --- | --- |
| `Super+Q` | Terminal (kitty) |
| `Super+R` | App launcher |
| `Super+Shift+R` | Wallpaper picker |
| `Super+M` | wlogout power menu |
| `Super+L` | Lock |
| `Super+Shift+M` | Quit niri |
| `Super+E` | Files (nemo) |
| `Super+Tab` | niri overview |

See `niri/.config/niri/TaianNiriM/keybinds.kdl` for the full list.

## Notes

- `niri` requires the refresh rate in `monitors.kdl` to match
  `niri msg outputs` exactly.
- Do **not** set `GDK_BACKEND` globally: it breaks the screencast portal.
- `XDG_MENU_PREFIX "arch-"` is kept temporarily while this config is still
  being edited from Arch; remove it on Fedora if menus misbehave.
