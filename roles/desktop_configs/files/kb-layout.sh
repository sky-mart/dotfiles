#!/usr/bin/env bash

OPTIONS="grp:alt_space_toggle,ctrl:swapcaps"
STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/kb-layout"

usage() {
    echo "Use: (no args, prints current layout) | init | eng | english | ger | german | reapply"
    exit 1
}

set_x11_layout() {
    setxkbmap -layout "$1" -option "${OPTIONS}"
    mkdir -p "$(dirname "${STATE_FILE}")"
    echo "$1" >"${STATE_FILE}"
}

reapply_x11_layout() {
    local layouts
    layouts="$(cat "${STATE_FILE}" 2>/dev/null || true)"
    set_x11_layout "${layouts:-us,ru}"
}

get_x11_layout() {
    local layouts group
    layouts="$(setxkbmap -query | awk '/^layout:/ {print $2}')"
    group="$(~/.local/bin/xkb-group)"
    echo "${layouts}" | cut -d',' -f"$((group + 1))"
}

set_plasma_layout() {
    local layouts="$1"
    local kwriteconfig

    if command -v kwriteconfig6 >/dev/null 2>&1; then
        kwriteconfig="kwriteconfig6"
    elif command -v kwriteconfig5 >/dev/null 2>&1; then
        kwriteconfig="kwriteconfig5"
    else
        echo "kwriteconfig5/6 is required to change layouts under Plasma Wayland" >&2
        exit 1
    fi

    "$kwriteconfig" --file kxkbrc --group Layout --key Use true
    "$kwriteconfig" --file kxkbrc --group Layout --key ResetOldOptions true
    "$kwriteconfig" --file kxkbrc --group Layout --key LayoutList "$layouts"
    "$kwriteconfig" --file kxkbrc --group Layout --key VariantList ,
    "$kwriteconfig" --file kxkbrc --group Layout --key LayoutLoopCount 2
    "$kwriteconfig" --file kxkbrc --group Layout --key Options "$OPTIONS"

    dbus-send --session --type=signal --reply-timeout=100 \
        --dest=org.kde.keyboard /Layouts org.kde.keyboard.reloadConfig \
        >/dev/null 2>&1 || true
}

get_plasma_layout() {
    local qdbus

    if command -v qdbus6 >/dev/null 2>&1; then
        qdbus="qdbus6"
    elif command -v qdbus >/dev/null 2>&1; then
        qdbus="qdbus"
    else
        echo "qdbus/qdbus6 is required to query the layout under Plasma Wayland" >&2
        exit 1
    fi

    "$qdbus" org.kde.keyboard /Layouts org.kde.KeyboardLayouts.getLayout
}

set_layout() {
    local layouts="$1"

    case "${XDG_SESSION_TYPE:-}" in
        wayland)
            if [ "${XDG_CURRENT_DESKTOP:-}" = "KDE" ] || [ -n "${KDE_FULL_SESSION:-}" ]; then
                set_plasma_layout "$layouts"
            else
                echo "Wayland layout changes are compositor-specific; this script currently supports KDE Plasma Wayland" >&2
                exit 1
            fi
            ;;
        *)
            set_x11_layout "$layouts"
            ;;
    esac
}

get_layout() {
    case "${XDG_SESSION_TYPE:-}" in
        wayland)
            if [ "${XDG_CURRENT_DESKTOP:-}" = "KDE" ] || [ -n "${KDE_FULL_SESSION:-}" ]; then
                get_plasma_layout
            else
                echo "Wayland layout changes are compositor-specific; this script currently supports KDE Plasma Wayland" >&2
                exit 1
            fi
            ;;
        *)
            get_x11_layout
            ;;
    esac
}

case "$1" in
    "")
        get_layout
        ;;
    init|eng|english)
        set_layout us,ru
        ;;
    ger|german)
        set_layout de,ru
        ;;
    reapply)
        case "${XDG_SESSION_TYPE:-}" in
            wayland) exit 0 ;;
            *) reapply_x11_layout ;;
        esac
        ;;
    *)
        usage
        ;;
esac
