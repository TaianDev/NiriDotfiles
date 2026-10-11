#!/usr/bin/env bash
# Captura de región (grim + slurp) y anotación con satty.
# Quickshell se lanza desde niri (systemd --user) y no hereda el PATH del login
# shell; satty suele estar en ~/.cargo/bin, así que lo añadimos aquí igual que en
# apply_wallpaper.sh para que el binario se encuentre.
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

geometry="$(slurp)" || exit 0
[ -n "$geometry" ] || exit 0

grim -g "$geometry" -t ppm - | satty --filename -
