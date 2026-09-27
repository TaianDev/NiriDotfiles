#!/usr/bin/env bash

# Single instance: avoids starting a second swayidle when the script is run
# manually while the autostart instance is still alive. Two daemons would
# duplicate lock/DPMS/suspend and race each other.
if pgrep -x swayidle >/dev/null 2>&1; then
  exit 0
fi

LOCK_CMD="$HOME/.config/quickshell/scripts/session-lock.sh"

# NOTE: deliberately no `-w` (wait for command to finish). `-w` makes swayidle
# block until the command exits; since session-lock.sh runs the lockscreen in
# the foreground (`exec quickshell`), that freezes swayidle's event loop for the
# whole lock. Idle/logind events then queue up and get replayed right after
# unlocking (re-lock, `power-off-monitors` and `systemctl suspend` out of time).
# It also deadlocks `systemctl suspend` against swayidle's own logind
# "sleep delay" inhibitor.
#
# Without `-w`, swayidle forks the commands and keeps processing events:
# `power-off-monitors` still fires 60 s after the lock, and `before-sleep`
# launches the locker detached with `setsid -f` so it does not hold the
# inhibitor.
exec swayidle -w \
  timeout 480 "setsid -f $LOCK_CMD" \
  timeout 900 "systemctl suspend" \
  before-sleep "setsid -f $LOCK_CMD" \
  lock "setsid -f $LOCK_CMD"
