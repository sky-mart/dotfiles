#!/usr/bin/env bash

get_active_profile() {
    [ -n "$card" ] || return 0
    pactl list cards 2>/dev/null | awk -v card="$card" '
        /Name:/ {c=($2 == card)}
        c && /Active Profile:/ {sub(/^[ \t]*Active Profile:[ \t]*/, ""); print; exit}
    '
}

source "$(dirname "${BASH_SOURCE[0]}")/bt-devices.sh"

device=$(bluetoothctl devices Connected 2>/dev/null | head -1)
[ -n "$device" ] || exit 0
mac=$(cut -d' ' -f2 <<< "$device")
name=$(cut -d' ' -f3- <<< "$device")
card=$(pactl list cards short 2>/dev/null | awk -v card="bluez_card.${mac//:/_}" '$2 == card {print $2; exit}')

dev=$name
for entry in "${BT_DEVICES[@]}"; do
    [ "${entry%% *}" = "$mac" ] && dev="${entry#* }"
done

# i3blocks buttons: left disconnects, middle shows battery, right toggles profile.
case "${BLOCK_BUTTON:-}" in
    1)
        if bluetoothctl disconnect "$mac" >/dev/null 2>&1; then
            exit 0
        fi
        ;;
    2)
        battery=$(bluetoothctl info "$mac" 2>/dev/null | sed -n 's/.*Battery Percentage:.*(\([0-9][0-9]*\)).*/\1/p')
        battery_text="Battery level unavailable"
        [ -n "$battery" ] && battery_text="${battery}%"
        notify-send --app-name="Bluetooth" "Bluetooth battery: $dev" "$battery_text" >/dev/null 2>&1
        ;;
    3)
        if [ -n "$card" ]; then
            case "$(get_active_profile)" in
                a2dp*) pactl set-card-profile "$card" headset-head-unit >/dev/null 2>&1 ;;
                *) pactl set-card-profile "$card" a2dp-sink >/dev/null 2>&1 ;;
            esac
        fi
        ;;
esac

case "$(get_active_profile)" in
    a2dp*) label=A2DP ;;
    headset*) label=HFP ;;
    *) label="" ;;
esac

[ -n "$dev" ] && echo "<span size='large'></span> ${dev}${label:+ [$label]}"

exit 0
