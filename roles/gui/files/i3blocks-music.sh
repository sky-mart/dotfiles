#!/usr/bin/env bash

players=$(playerctl -l 2>/dev/null)
[ -n "$players" ] || exit 33

selected_player=
while IFS= read -r candidate; do
    [ -n "$candidate" ] || continue
    [ -n "$selected_player" ] || selected_player=$candidate
    status=$(playerctl --player="$candidate" status 2>/dev/null) || continue
    if [ "$status" = Playing ]; then
        selected_player=$candidate
        break
    fi
done <<< "$players"

if [ "${BLOCK_BUTTON:-}" = 1 ]; then
    player=${selected_player#org.mpris.MediaPlayer2.}
    player=${player%%.*}
    if [[ "$player" =~ ^[[:alnum:]_-]+$ ]]; then
        i3-msg "[class=\"(?i)^${player}\"] focus" >/dev/null
    fi
fi

display=$(playerctl --player="$selected_player" metadata --format '{{artist}} - {{title}}' 2>/dev/null)
if [ -n "$display" ]; then
    printf '%s\n' "$display"
else
    player=${selected_player#org.mpris.MediaPlayer2.}
    printf '%s\n' "${player%%.*}"
fi
