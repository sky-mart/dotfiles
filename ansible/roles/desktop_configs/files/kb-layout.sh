#!/usr/bin/env bash

OPTIONS="grp:alt_shift_toggle,ctrl:swapcaps"

case "$1" in
    init|eng)
        setxkbmap -layout us,ru -option "${OPTIONS}"
        ;;
    ger)
        setxkbmap -layout de,ru -option "${OPTIONS}"
        ;;
    *)
        echo "Use: init | ger | eng"
        exit 1
        ;;
esac
