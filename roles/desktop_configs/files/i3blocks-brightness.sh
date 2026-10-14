#!/usr/bin/env bash

command -v brightnessctl >/dev/null 2>&1 || exit 0

case "${BLOCK_BUTTON:-}" in
    1)
        brightnessctl --class=backlight set +5% >/dev/null || exit $?
        ;;
    3)
        brightnessctl --class=backlight set 5%- >/dev/null || exit $?
        ;;
esac

brightness=$(brightnessctl --class=backlight --machine-readable info 2>/dev/null) || exit 0

awk -F, '$2 == "backlight" && $4 ~ /^[0-9]+%$/ {
    print "<span size=\"large\">☀</span> " $4
    exit
}' <<< "$brightness"
