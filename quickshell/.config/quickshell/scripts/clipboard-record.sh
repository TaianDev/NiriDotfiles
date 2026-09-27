#!/usr/bin/env bash
# Records the current Wayland clipboard into the Quickshell clipboard history.
# Invoked by `wl-paste --watch` (content passed on stdin) and once at startup.
# Prints a single JSON line describing the captured entry on stdout.
set -u

state="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/clipboard"
mkdir -p "$state" 2>/dev/null || exit 0

types="$(wl-paste --list-types 2>/dev/null || true)"
[ -n "$types" ] || exit 0

if grep -qiE 'image/(png|jpeg|webp|gif|bmp)' <<<"$types"; then
    mime="$(grep -ioE 'image/(png|jpeg|webp|gif|bmp)' <<<"$types" | head -n1)"
    ext="${mime#image/}"
    [ "$ext" = "jpeg" ] && ext="jpg"

    tmp="$(mktemp "$state/.tmp.XXXXXX")" || exit 0
    if ! wl-paste --type "$mime" >"$tmp" 2>/dev/null || [ ! -s "$tmp" ]; then
        rm -f "$tmp"
        exit 0
    fi

    hash="$(sha256sum "$tmp" | cut -d' ' -f1)"
    dest="$state/img-$hash.$ext"
    [ -f "$dest" ] || mv -f "$tmp" "$dest"
    rm -f "$tmp"

    size="$(stat -c%s "$dest" 2>/dev/null || echo 0)"
    jq -cn --arg type image --arg mime "$mime" --arg file "$dest" \
        --arg hash "$hash" --argjson size "${size:-0}" \
        '{type:$type,mime:$mime,file:$file,hash:$hash,size:$size,ts:(now|floor)}'
else
    tmp="$(mktemp "$state/.tmp.XXXXXX")" || exit 0
    if ! wl-paste --no-newline >"$tmp" 2>/dev/null || [ ! -s "$tmp" ]; then
        rm -f "$tmp"
        exit 0
    fi

    hash="$(sha256sum "$tmp" | cut -d' ' -f1)"
    dest="$state/txt-$hash.txt"
    [ -f "$dest" ] || mv -f "$tmp" "$dest"
    rm -f "$tmp"

    jq -cn --arg type text --arg file "$dest" --arg hash "$hash" \
        --rawfile text "$dest" \
        '{type:$type,file:$file,hash:$hash,preview:($text[0:600]),length:($text|length),ts:(now|floor)}'
fi
