#!/usr/bin/env bash
# Single direct invocation point for the Quickshell lockscreen.
# Used by: niri keybind (Super+L), wlogout, swayidle (idle.sh), SessionService.

if pgrep -f "quickshell -c .*lockscreen" >/dev/null 2>&1; then
    exit 0
fi

exec quickshell -c "$HOME/.config/quickshell/modules/lockscreen/"
