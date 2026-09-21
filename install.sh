#!/usr/bin/env bash
# ============================================================================
# install.sh — TaianDotFilesNiri (Fedora)
# ============================================================================
# - Installs the essential Fedora packages the dotfiles rely on.
# - Installs fonts and cursor separately (not managed by stow).
# - Backs up existing configs, then stows the packages with --no-folding.
# - Seeds the matugen/wal theme once with a default wallpaper.
# - Prints (and writes) the list of packages that could not be installed.
# ============================================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(niri quickshell wlogout matugen kitty gtk-3.0 gtk-4.0 fastfetch clipse zsh wallpapers)

# Essential packages. "a|b" means: try "a", then "b".
ESSENTIAL=(
    niri quickshell kitty wlogout jq gettext gettext-envsubst curl unzip stow git
    matugen "python3-pywal|pywal" adw-gtk3-theme papirus-icon-theme google-noto-emoji-fonts
    awww swayosd wlsunset hypridle hyprpolkitagent clipse wl-clipboard
    pipewire pipewire-pulseaudio wireplumber pulseaudio-utils sound-theme-freedesktop
    brightnessctl playerctl
    NetworkManager bluez util-linux procps-ng psmisc dbus-tools flatpak
    gnome-keyring xdg-desktop-portal-gtk xdg-desktop-portal-gnome
    cava grim slurp satty btop
    translate-shell
    zsh starship fastfetch eza bat fzf
)

FAILED=()
NO_WEAK_DEPS=0
SET_SHELL=0

log()  { printf '\033[1;34m[+]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[=]\033[0m %s\n' "$*"; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Installs the essential Fedora packages for these dotfiles, installs the
JetBrainsMono Nerd Font and Sunset-cursors separately, stows the config
packages and seeds the theme.

Options:
  --no-weak-deps   Pass --setopt=install_weak_deps=False to dnf
  --set-shell      Set zsh as the login shell (chsh)
  -h, --help       Show this help
EOF
}

# --- 0. Arguments ------------------------------------------------------------
while [ "$#" -gt 0 ]; do
    case "$1" in
        --no-weak-deps) NO_WEAK_DEPS=1 ;;
        --set-shell) SET_SHELL=1 ;;
        -h|--help) usage; exit 0 ;;
        *) warn "Unknown option: $1"; usage; exit 1 ;;
    esac
    shift
done

# --- 1. Distro check ---------------------------------------------------------
if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
fi
if [ "${ID:-unknown}" != "fedora" ]; then
    warn "This installer targets Fedora (detected: ${ID:-unknown}). Continuing anyway."
fi

# --- 2. Install essential packages ------------------------------------------
install_packages() {
    local dnf_opts=(-y)
    [ "$NO_WEAK_DEPS" -eq 1 ] && dnf_opts+=(--setopt=install_weak_deps=False)

    if ! command -v dnf >/dev/null 2>&1; then
        warn "dnf not found; skipping package installation."
        FAILED=("${ESSENTIAL[@]}")
        return
    fi

    log "Requesting sudo..."
    if ! sudo -v; then
        warn "sudo failed; skipping package installation."
        FAILED=("${ESSENTIAL[@]}")
        return
    fi

    for spec in "${ESSENTIAL[@]}"; do
        local installed=0
        local alts=()
        IFS='|' read -r -a alts <<< "$spec"
        for pkg in "${alts[@]}"; do
            if sudo dnf install "${dnf_opts[@]}" "$pkg" >/dev/null 2>&1; then
                ok "installed: $pkg"
                installed=1
                break
            fi
        done
        if [ "$installed" -eq 0 ]; then
            warn "failed: ${alts[0]}"
            FAILED+=("${alts[0]}")
        fi
    done
}

# --- 3. Fonts (installed separately) ----------------------------------------
install_fonts() {
    if command -v fc-list >/dev/null 2>&1 \
        && [ "$(fc-list 2>/dev/null | grep -ic 'JetBrainsMono Nerd Font')" -gt 0 ]; then
        ok "JetBrainsMono Nerd Font already installed"
        return
    fi
    if ! command -v curl >/dev/null 2>&1 || ! command -v unzip >/dev/null 2>&1; then
        warn "curl/unzip not available; skipping font install."
        return
    fi
    local dest="$HOME/.local/share/fonts/JetBrainsMono"
    local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    local tmp
    tmp="$(mktemp -d)"
    log "Downloading JetBrainsMono Nerd Font..."
    curl -fL "$url" -o "$tmp/JetBrainsMono.zip"
    mkdir -p "$dest"
    unzip -o "$tmp/JetBrainsMono.zip" -d "$dest" >/dev/null
    rm -rf "$tmp"
    command -v fc-cache >/dev/null 2>&1 && fc-cache -f >/dev/null 2>&1 || true
    ok "Fonts installed in $dest"
}

# --- 4. Cursor (installed separately) ---------------------------------------
install_cursor() {
    local dest="$HOME/.local/share/icons/Sunset-cursors"
    if [ -d "$dest" ]; then
        ok "Sunset-cursors already installed"
        return
    fi
    if [ -n "${SUNSET_CURSORS_SRC:-}" ] && [ -d "${SUNSET_CURSORS_SRC}" ]; then
        mkdir -p "$(dirname "$dest")"
        cp -a "$SUNSET_CURSORS_SRC" "$dest"
        ok "Cursor installed in $dest"
    else
        warn "Sunset-cursors not found."
        warn "Set SUNSET_CURSORS_SRC=/path/to/Sunset-cursors and re-run, or copy it"
        warn "manually into ~/.local/share/icons/Sunset-cursors."
    fi
}

# --- 4b. Login shell (optional) ---------------------------------------------
set_shell() {
    [ "$SET_SHELL" -eq 1 ] || return 0
    local zsh_bin
    zsh_bin="$(command -v zsh || true)"
    if [ -z "$zsh_bin" ]; then
        warn "zsh not found; cannot set the login shell."
        return
    fi
    if [ "${SHELL:-}" = "$zsh_bin" ]; then
        ok "Login shell is already zsh"
        return
    fi
    log "Setting zsh as the login shell..."
    if chsh -s "$zsh_bin"; then
        ok "Login shell set to zsh"
    else
        warn "chsh failed; set it manually with: chsh -s $zsh_bin"
    fi
}

# --- 5. Backup + stow --------------------------------------------------------
backup_path() {
    local path="$1"
    if [ -e "$path" ] && [ ! -L "$path" ]; then
        warn "Existing $path found. Backing up to ${path}.bak"
        rm -rf "${path}.bak"
        mv "$path" "${path}.bak"
    fi
}

stow_packages() {
    local config_pkgs=(niri quickshell wlogout matugen kitty gtk-3.0 gtk-4.0 fastfetch clipse)
    for pkg in "${config_pkgs[@]}"; do
        backup_path "$HOME/.config/$pkg"
    done
    backup_path "$HOME/.zshrc"
    backup_path "$HOME/Pictures/Wallpapers"
    backup_path "$HOME/.config/xdg-desktop-portal/niri-portals.conf"

    for pkg in "${PACKAGES[@]}"; do
        if [ ! -d "$REPO_DIR/$pkg" ]; then
            warn "Package not found, skipping: $pkg"
            continue
        fi
        log "Stowing $pkg"
        stow --no-folding -d "$REPO_DIR" -t "$HOME" "$pkg"
    done
}

# --- 6. Seed theme -----------------------------------------------------------
seed_theme() {
    local wp=""
    if [ -d "$HOME/Pictures/Wallpapers" ]; then
        wp="$(find "$HOME/Pictures/Wallpapers" -maxdepth 1 -type f \
            \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.webp' \) -print -quit)"
    fi
    if [ -z "$wp" ]; then
        warn "No wallpaper found to seed the theme. Apply one later from the launcher."
        return
    fi
    log "Seeding theme with: $wp"
    command -v wal >/dev/null 2>&1 && wal -qste -i "$wp" || true
    command -v matugen >/dev/null 2>&1 && matugen image "$wp" --source-color-index 0 || true
    ok "Theme generated"
}

# --- 7. Optional user services ----------------------------------------------
enable_services() {
    systemctl --user enable --now hyprpolkitagent 2>/dev/null && ok "hyprpolkitagent enabled" || true
}

# --- 8. Report failures ------------------------------------------------------
report_failures() {
    if [ "${#FAILED[@]}" -eq 0 ]; then
        ok "All essential packages are installed."
        return
    fi
    echo
    warn "The following packages could NOT be installed automatically:"
    printf '  - %s\n' "${FAILED[@]}"
    printf '%s\n' "${FAILED[@]}" > "$REPO_DIR/failed-packages.txt"
    warn "List written to: $REPO_DIR/failed-packages.txt"
    warn "Install them manually (COPR / RPM Fusion / pip) and re-run if needed."
}

# --- Main --------------------------------------------------------------------
main() {
    install_packages
    install_fonts
    install_cursor
    set_shell

    if ! command -v stow >/dev/null 2>&1; then
        warn "stow is not available; cannot link dotfiles."
        report_failures
        exit 1
    fi

    stow_packages
    seed_theme
    enable_services
    report_failures

    echo
    ok "Done. Log out and back in (or start niri) to apply the changes."
}

main
