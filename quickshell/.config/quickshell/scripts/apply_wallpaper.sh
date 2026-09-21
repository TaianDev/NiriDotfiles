#!/usr/bin/env bash

if [ -z "$1" ]; then
  echo "No wallpaper path provided. Won't update pywal and walcord colors."
  exit 1
fi

WALLPAPER_PATH="$1"

# 1. GENERATE RESOURCES (blocking; same order as pywal_global_update.sh)
wal -qste -i "$WALLPAPER_PATH"
matugen image "$WALLPAPER_PATH" --source-color-index 0

# 1.5 RELOAD OSD (swayosd-server only reads style.css on startup)
pkill -x swayosd-server 2>/dev/null || true
sleep 0.3
GSK_RENDERER=gl setsid -f swayosd-server --top-margin 0.95 >/dev/null 2>&1

# 2. APPLY THE WALLPAPER
awww img "$WALLPAPER_PATH" --transition-type wave --transition-fps 60 --transition-duration 2 &

# 3. RELOAD APPLICATIONS (Theme.qml is picked up by ThemeLoader; do not restart quickshell)
killall -SIGUSR1 kitty 2>/dev/null || true
