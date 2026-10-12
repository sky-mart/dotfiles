#!/usr/bin/env bash

~/.local/bin/blconnect.sh jbl  # run once at startup

gdbus monitor --session --dest org.freedesktop.ScreenSaver |
while read -r line; do
    if [[ "$line" == *"ActiveChanged"* && "$line" == *"false"* ]]; then
        ~/.local/bin/blconnect.sh jbl
    fi
done
