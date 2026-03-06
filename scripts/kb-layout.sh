#!/usr/bin/env bash

STATE_FILE="$HOME/.cache/kb-last-layout"
# my layouts are us,ru,de

case "$1" in
    next)
        current=$(xkb-switch)
        next=$(xkb-switch -n)
        echo "$current" > "$STATE_FILE"
        ;;
    last)
        if [[ -f "$STATE_FILE" ]]; then
            last=$(cat "$STATE_FILE")
            current=$(xkb-switch)
            xkb-switch -s "$last"
            echo "$current" > "$STATE_FILE"
        fi
        ;;
    ger)
        echo "ru" > "$STATE_FILE"
        xkb-switch -s "de"
        ;;
    eng)
        echo "ru" > "$STATE_FILE"
        xkb-switch -s "us"
        ;;
    *)
        echo "Use: next | last"
        exit 1
        ;;
esac
