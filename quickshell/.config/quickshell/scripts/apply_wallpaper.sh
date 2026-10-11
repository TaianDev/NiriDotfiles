#!/usr/bin/env bash

# Quickshell is spawned by niri via niri.service (systemd --user), which does not
# inherit the login shell PATH. Make sure user-installed tools resolve here too.
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

if [ -z "$1" ]; then
  echo "No wallpaper path provided. Won't update pywal and walcord colors." >&2
  exit 1
fi

WALLPAPER_PATH="$1"
shift || true

# ── Defaults (same behaviour as before) ──
SCHEME="scheme-tonal-spot" # matugen --type
MODE="dark"                # matugen --mode (light|dark|smart)
CONTRAST="0"               # matugen --contrast (-1..1)
SRC_INDEX="0"              # matugen --source-color-index (0..4)
TRANSITION="wave"          # awww --transition-type

while [ $# -gt 0 ]; do
  case "$1" in
  --scheme)
    SCHEME="$2"
    shift 2
    ;;
  --mode)
    MODE="$2"
    shift 2
    ;;
  --contrast)
    CONTRAST="$2"
    shift 2
    ;;
  --source-index)
    SRC_INDEX="$2"
    shift 2
    ;;
  --transition)
    TRANSITION="$2"
    shift 2
    ;;
  *) shift ;;
  esac
done

# 0. VERIFY REQUIRED TOOLS (fail loudly instead of silently skipping them)
for tool in wal matugen awww; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "apply_wallpaper: required tool '$tool' not found in PATH ($PATH)" >&2
    exit 1
  fi
done

# Theme.qml is generated outside ~/.config/quickshell on purpose: Quickshell
# hot-reloads its config when a .qml inside that dir changes, which would kill
# this script before the OSD/wallpaper steps below run.
mkdir -p "$HOME/.local/state/quickshell"

# 1. GENERATE RESOURCES (blocking; same order as pywal_global_update.sh)
if ! wal -q -i "$WALLPAPER_PATH"; then
  echo "apply_wallpaper: 'wal' failed for $WALLPAPER_PATH" >&2
  exit 1
fi

if ! matugen image "$WALLPAPER_PATH" \
  --source-color-index "$SRC_INDEX" \
  --type "$SCHEME" \
  --mode "$MODE" \
  --contrast "$CONTRAST"; then
  echo "apply_wallpaper: 'matugen' failed for $WALLPAPER_PATH" >&2
  exit 1
fi

# 1.5 RELOAD OSD (swayosd-server only reads style.css on startup)
pkill -x swayosd-server 2>/dev/null || true
sleep 0.3
GSK_RENDERER=gl setsid -f swayosd-server --top-margin 0.95 >/dev/null 2>&1

# 2. APPLY THE WALLPAPER
awww img "$WALLPAPER_PATH" --transition-type "$TRANSITION" \
  --transition-fps 60 --transition-duration 1.5 &

# 3. RELOAD APPLICATIONS (Theme.qml is watched by ThemeLoader; no shell restart needed)
killall -SIGUSR1 kitty 2>/dev/null || true
