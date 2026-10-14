#!/usr/bin/env bash

choice=$(printf '%s\n' lock suspend hibernate reboot 'power off' | rofi -dmenu -i -p power) || exit 0

case "$choice" in
    lock) exec i3-msg "exec --no-startup-id \"$HOME/.local/bin/lock.sh\"" ;;
    suspend) exec systemctl suspend ;;
    hibernate) exec systemctl hibernate ;;
    reboot) exec systemctl reboot ;;
    'power off') exec systemctl poweroff ;;
    *) exit 2 ;;
esac
