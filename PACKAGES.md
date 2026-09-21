# Packages — Fedora (essentials)

Only the packages these dotfiles need to boot and run. **User applications are
installed manually** (browsers, editors, office, media, games, etc.).

`install.sh` installs this set automatically and writes any package it could not
install to `failed-packages.txt` for manual handling.

## Repositories

Enable RPM Fusion (drivers, codecs, some apps):

```bash
sudo dnf install \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
```

Packages that are usually **not** in the base repos (COPR / pip) are listed at
the end.

## Core

| Package | Notes |
| --- | --- |
| `niri` | Compositor |
| `quickshell` | Shell (provides the `qs` binary too) |
| `kitty` | Terminal |
| `wlogout` | Power menu |
| `jq` | Used by `wlogout/launcher.sh` |
| `gettext` | GNU gettext tools |
| `gettext-envsubst` | Provides `envsubst` (used by `wlogout/launcher.sh`) |
| `curl`, `unzip` | Installer (fonts) and weather widget |
| `stow` | Dotfile linking |
| `git` | zinit bootstrap |

## Theming

| Package | Notes |
| --- | --- |
| `matugen` | Generates Theme.qml, gtk.css, colors.kdl, swayosd, wlogout |
| `python3-pywal` | `wal`; kitty colors |
| `adw-gtk3-theme` | GTK theme (`adw-gtk3` / `adw-gtk3-dark`) |
| `papirus-icon-theme` | Icons (`Papirus-Dark`) |
| `google-noto-emoji-fonts` | Color emoji for app content (notifications, web) |

## Wayland / daemons

| Package | Notes |
| --- | --- |
| `awww` | Wallpaper daemon (`awww-daemon`, `awww img`, `awww query`) |
| `swayosd` | Volume/brightness OSD |
| `wlsunset` | Night light |
| `hypridle` | Idle/lock/suspend |
| `hyprpolkitagent` | Polkit authentication agent |
| `clipse` | Clipboard manager |
| `wl-clipboard` | `wl-paste` / `wl-copy` |

## Audio / hardware

| Package | Notes |
| --- | --- |
| `pipewire` | Audio server |
| `pipewire-pulseaudio` | PulseAudio server (binary `pipewire-pulse`) |
| `wireplumber` | Session manager (`wpctl`) |
| `pulseaudio-utils` | `paplay` (alarm sound) |
| `sound-theme-freedesktop` | Provides `alarm-clock-elapsed.oga` |
| `brightnessctl` | Brightness |
| `playerctl` | Media keys |

## Network / Bluetooth / base

| Package | Notes |
| --- | --- |
| `NetworkManager` | `nmcli` |
| `bluez` | `bluetoothctl` |
| `util-linux` | `rfkill`, `setsid` |
| `procps-ng` | `pgrep`, `pkill`, `free`, `uptime` |
| `psmisc` | `killall` |
| `dbus-tools` | `dbus-update-activation-environment` |
| `flatpak` | Bar update pill |

## Portals / keyring (required by niri)

| Package | Notes |
| --- | --- |
| `gnome-keyring` | Secret portal |
| `xdg-desktop-portal-gtk` | File chooser / fallback |
| `xdg-desktop-portal-gnome` | Screencast / screenshots |

## Shell UI

| Package | Notes |
| --- | --- |
| `cava` | Bar music backdrop + lockscreen visualizer |
| `grim`, `slurp` | Screenshot capture |
| `satty` | Screenshot annotation |
| `btop` | System monitor (opened from the bar) |
| `translate-shell` | `trans`; assistant translator |

## Terminal (zsh)

| Package | Notes |
| --- | --- |
| `zsh` | Shell |
| `starship` | Prompt |
| `fastfetch` | System info |
| `eza` | `ls` replacement (fzf-tab preview) |
| `bat` | `cat` replacement |
| `fzf` | Fuzzy finder (fzf-tab) |

## Assets installed separately (not via dnf/stow)

- **Fonts:** JetBrainsMono Nerd Font → `~/.local/share/fonts/JetBrainsMono/`
  (installed by `install.sh` from the Nerd Fonts releases).
- **Cursor:** `Sunset-cursors` → `~/.local/share/icons/Sunset-cursors/`
  (set `SUNSET_CURSORS_SRC=/path/to/Sunset-cursors` for `install.sh`).
- **Wallpapers:** tracked in this repo (`wallpapers/Pictures/Wallpapers`) and
  stowed to `~/Pictures/Wallpapers`.

## Usually not in the base repos (COPR / pip)

If `install.sh` reports these in `failed-packages.txt`, install them manually:

- `matugen` → COPR / cargo (`cargo install matugen`)
- `pywal` (`wal`) → `pip install pywal` or COPR
- `swayosd` → COPR
- `awww` → COPR / source (the dotfiles use the `awww` binary names)
- `hypridle`, `hyprpolkitagent`, `quickshell`, `clipse` → verify availability
  for your Fedora release; otherwise COPR.

## Not included (install manually if you want them)

`nm-applet` (`network-manager-applet`), `blueman`, `nemo`, `zen-browser`,
`qt6ct`, `flatpak`-managed apps, and every user application. The shell already
provides its own network/Bluetooth UI, so the tray applets are optional.
