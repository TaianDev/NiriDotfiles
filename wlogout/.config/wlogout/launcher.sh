#!/usr/bin/env bash

#// Check if wlogout is already running

if pgrep -x "wlogout" >/dev/null; then
  pkill -x "wlogout"
  exit 0
fi

#// set file variables

wlogoutStyle=1
wlogoutStyle=${wlogoutStyle:-$WLOGOUT_STYLE}
confDir="${confDir:-$HOME/.config}"
wLayout="${confDir}/wlogout/layout_${wlogoutStyle}"
wlTmplt="${confDir}/wlogout/style_${wlogoutStyle}.css"

if [ ! -f "${wLayout}" ] || [ ! -f "${wlTmplt}" ]; then
  echo "ERROR: Config ${wlogoutStyle} not found..."
  wlogoutStyle=1
  wLayout="${confDir}/wlogout/layout_${wlogoutStyle}"
  wlTmplt="${confDir}/wlogout/style_${wlogoutStyle}.css"
fi

#// detect monitor res (niri)

niri_out=$(niri msg --json focused-output)
y_mon=$(echo "$niri_out" | jq '.logical.height')
hypr_scale=$(echo "$niri_out" | jq -r '.logical.scale' | awk '{printf "%.0f", $1 * 100}')
#// scale config layout and style

wlColms=5
export mgn=$((y_mon * 28 / hypr_scale))
export hvr=$((y_mon * 23 / hypr_scale))

#// scale font size

export fntSize=$((y_mon * 2 / 100))

#// detect wallpaper brightness

export BtnCol="white"

#// eval border radius (niri does not expose the radius; a fixed value is used)

hypr_border="${hypr_border:-10}"
export active_rad=$((hypr_border * 5))
export button_rad=$((hypr_border * 8))

#// eval config files

wlStyle="$(envsubst <"${wlTmplt}")"

#// launch wlogout

wlogout -b "${wlColms}" -c 0 -r 0 -m 0 --layout "${wLayout}" --css <(echo "${wlStyle}") --protocol layer-shell
