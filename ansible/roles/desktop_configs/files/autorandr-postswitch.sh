#!/usr/bin/env bash
set -euo pipefail

focused_workspace=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused) | .name')

move_workspaces() {
    local output=$1
    shift

    for workspace in "$@"; do
        i3-msg "workspace \"$workspace\"; move workspace to output $output" >/dev/null
    done
}

mapfile -t primary_workspaces < <(i3-msg -t get_workspaces | jq -r '.[] | select(.num >= 1 and .num <= 7) | .name')
mapfile -t secondary_workspaces < <(i3-msg -t get_workspaces | jq -r '.[] | select(.num >= 8 and .num <= 10) | .name')

move_workspaces primary "${primary_workspaces[@]}"
move_workspaces nonprimary "${secondary_workspaces[@]}"
i3-msg "workspace \"$focused_workspace\"" >/dev/null
