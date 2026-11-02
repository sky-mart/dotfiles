#!/usr/bin/env bash

# Keep the wrapper alive so unlocking can cancel the suspend timer.
cleanup() {
    kill "$suspend_pid" 2>/dev/null || true
    wait "$suspend_pid" 2>/dev/null || true
    kill "$locker_pid" 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 143' TERM
trap 'exit 130' INT
trap 'exit 129' HUP

i3lock \
    --nofork \
    --color=2e3440ff \
    --indicator \
    --radius=110 \
    --ring-width=10 \
    --line-uses-ring \
    --ring-color=4c566aff \
    --inside-color=3b4252ff \
    --ringver-color=88c0d0ff \
    --insidever-color=3b4252ff \
    --verif-color=d8dee9ff \
    --verifoutline-color=2e3440ff \
    --ringwrong-color=bf616aff \
    --insidewrong-color=3b4252ff \
    --wrong-color=d8dee9ff \
    --wrongoutline-color=2e3440ff \
    --keyhl-color=88c0d0ff \
    --bshl-color=bf616aff \
    --separator-color=2e3440ff \
    --time-color=00000000 \
    --timeoutline-color=00000000 \
    --date-color=00000000 \
    --dateoutline-color=00000000 \
    --keylayout=2 \
    --layout-color=d8dee9ff \
    --layoutoutline-color=2e3440ff \
    --layout-size=20 \
    --layout-pos="ix:iy+150" \
    --greeter-text="$(whoami)" \
    --greeter-color=d8dee9ff \
    --greeteroutline-color=2e3440ff \
    --greeter-size=32 \
    --greeter-pos="ix:iy-150" &
locker_pid=$!

# Only i3lock should hold the sleep inhibitor until it is ready.
if [[ -n ${XSS_SLEEP_LOCK_FD:-} ]]; then
    exec {XSS_SLEEP_LOCK_FD}<&-
fi

(
    trap - EXIT
    trap 'kill "$sleep_pid" 2>/dev/null; exit 0' TERM INT HUP
    sleep 600 & # 10 minutes
    sleep_pid=$!
    wait "$sleep_pid" || exit
    if kill -0 "$locker_pid" 2>/dev/null; then
        systemctl suspend
    fi
) &
suspend_pid=$!

wait "$locker_pid"
