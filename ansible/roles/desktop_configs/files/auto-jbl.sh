#!/usr/bin/env bash

dbus-monitor --session "type='signal',interface='org.freedesktop.ScreenSaver'" |
while read -r line; do
    if [[ "$line" == *"boolean false"* ]]; then
        ~/.local/bin/blconnect.sh jbl
    fi
done
