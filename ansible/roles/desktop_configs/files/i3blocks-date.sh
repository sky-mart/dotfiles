#!/usr/bin/env bash

reposition_calendar() {
    local win_w win_h out_x out_y out_w out_h attempt

    for attempt in 1 2 3 4 5; do
        read -r win_w win_h < <(
            i3-msg -t get_tree 2>/dev/null |
                jq -r '[.. | objects | select(.window_properties.title? == "Calendar widget")][0]
                    | select(. != null) | "\(.rect.width) \(.rect.height)"'
        )
        [ -n "$win_w" ] && break
        sleep 0.05
    done
    [ -z "$win_w" ] && return 0

    read -r out_x out_y out_w out_h < <(
        i3-msg -t get_outputs 2>/dev/null |
            jq -r '[.[] | select(.active and .primary)][0] | "\(.rect.x) \(.rect.y) \(.rect.width) \(.rect.height)"'
    )
    [ -z "$out_x" ] && return 0

    local margin=12 gap=34
    local x=$((out_x + out_w - win_w - margin))
    local y=$((out_y + out_h - win_h - gap))

    i3-msg "[title=\"^Calendar widget\$\"] move position ${x} ${y}" >/dev/null
}

if [ "${BLOCK_BUTTON:-}" = "1" ]; then
    quickshell ipc call calendar toggle
    reposition_calendar
fi

date '+%Y-%m-%d %H:%M:%S'
