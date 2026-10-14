#!/usr/bin/env bash

if [ "${BLOCK_BUTTON:-}" = "1" ]; then
    "$HOME/.local/bin/power-menu.sh"
fi

echo "<span size='large'>⏻</span>"
