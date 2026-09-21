#!/usr/bin/env bash
# Outputs one pipe-delimited status line for NetworkStatusService.
# WIFI|SSID|AIRPLANE|DND|NIGHT|VOL|VOL_MUTE|MIC|MIC_MUTE|BRIGHT

set +e

WIFI_RADIO="$(LC_ALL=C nmcli -t -f WIFI radio 2>/dev/null)"
[ -z "$WIFI_RADIO" ] && WIFI_RADIO="disabled"

SSID="$(LC_ALL=C nmcli -t -f NAME,TYPE connection show --active 2>/dev/null \
    | grep '802-11-wireless' | cut -d: -f1 | head -n1)"

WLAN_BLOCKED="$(rfkill list wifi 2>/dev/null | grep -ci 'soft blocked: yes' || true)"
BT_BLOCKED="$(rfkill list bluetooth 2>/dev/null | grep -ci 'soft blocked: yes' || true)"

AIRPLANE="false"
if [ "$WLAN_BLOCKED" -gt 0 ] && [ "$BT_BLOCKED" -gt 0 ]; then
    AIRPLANE="true"
fi

WIFI="$WIFI_RADIO"
if [ "$AIRPLANE" = "true" ] || [ "$WLAN_BLOCKED" -gt 0 ]; then
    WIFI="disabled"
    SSID=""
fi

DND_STATE="false"
if command -v dunstctl >/dev/null 2>&1; then
    DND_STATE="$(timeout 0.4 dunstctl is-paused 2>/dev/null || echo false)"
elif command -v makoctl >/dev/null 2>&1; then
    if timeout 0.4 makoctl mode 2>/dev/null | grep -q 'dnd'; then
        DND_STATE="true"
    fi
fi

NIGHT_STATE="false"
pgrep -x wlsunset >/dev/null 2>&1 && NIGHT_STATE="true"

VS="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)"
VOL="$(echo "$VS" | awk '{print int($2 * 100)}')"
[ -z "$VOL" ] && VOL=0
VM="false"
echo "$VS" | grep -q 'MUTED' && VM="true"

MS="$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)"
MIC="$(echo "$MS" | awk '{print int($2 * 100)}')"
[ -z "$MIC" ] && MIC=0
MM="false"
echo "$MS" | grep -q 'MUTED' && MM="true"

BRIGHT="$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%')"
[ -z "$BRIGHT" ] && BRIGHT=0

printf '%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n' \
    "$WIFI" "$SSID" "$AIRPLANE" "$DND_STATE" "$NIGHT_STATE" \
    "$VOL" "$VM" "$MIC" "$MM" "$BRIGHT"
