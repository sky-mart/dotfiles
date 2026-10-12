#!/usr/bin/env bash

case "${BLOCK_BUTTON:-}" in
    1|4)
        pactl set-sink-volume @DEFAULT_SINK@ +5%
        ;;
    2)
        pactl set-sink-mute @DEFAULT_SINK@ toggle
        ;;
    3|5)
        pactl set-sink-volume @DEFAULT_SINK@ -5%
        ;;
esac

mute_status="$(pactl get-sink-mute @DEFAULT_SINK@)"

case "$mute_status" in
    *yes*)
        echo "<span size='large'></span> mute"
        ;;
    *)
        pactl get-sink-volume @DEFAULT_SINK@ |
            awk -v icon="" 'NR == 1 { print "<span size=\"large\">" icon "</span> " $5 }'
        ;;
esac
