#!/usr/bin/env bash

OPTIONS="grp:alt_shift_toggle,ctrl:swapcaps"

usage() {
    echo "Use: init | eng | english | ger | german"
    exit 1
}

set_x11_layout() {
    setxkbmap -layout "$1" -option "${OPTIONS}"
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

case "$1" in
    init|eng|english)
        set_layout us,ru
        ;;
    ger|german)
        set_layout de,ru
        ;;
    *)
        usage
        ;;
esac
