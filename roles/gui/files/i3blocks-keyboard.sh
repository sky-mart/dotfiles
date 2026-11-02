#!/usr/bin/env bash

if [ "${BLOCK_BUTTON:-}" = "1" ]; then
    ~/.local/bin/kb-layout.sh next || exit $?
fi

layout="$(~/.local/bin/kb-layout.sh)" || exit $?
printf '⌨ %s\n' "${layout^^}"
