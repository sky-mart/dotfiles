#!/usr/bin/env bash

theme="$HOME/.config/rofi/power-menu.rasi"
if [[ ! -f "$theme" ]]; then
    theme="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/power-menu.rasi"
fi

choice=$(printf '%s\n' '  Lock' '  Suspend' '  Hibernate' '  Reboot' '  Power off' |
    rofi -dmenu -i -no-custom -no-sort -format i -p 'Power menu' \
        -theme "$theme") || exit 0

case "$choice" in
    0) exec i3-msg "exec --no-startup-id \"$HOME/.local/bin/lock.sh\"" ;;
    1) exec systemctl suspend ;;
    2) exec systemctl hibernate ;;
    3) exec systemctl reboot ;;
    4) exec systemctl poweroff ;;
    *) exit 2 ;;
esac
