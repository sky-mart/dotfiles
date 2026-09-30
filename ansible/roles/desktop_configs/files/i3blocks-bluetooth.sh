#!/usr/bin/env bash

get_active_profile() {
    pactl list cards 2>/dev/null | awk '/Name: bluez_card/{c=1} c && /Active Profile:/{sub(/^[ \t]*Active Profile:[ \t]*/,""); print; c=0}'
}

card=$(pactl list cards short 2>/dev/null | awk '/bluez_card/{print $2}')

if [ -n "$card" ] && [ "${BLOCK_BUTTON:-}" = "1" ]; then
    case "$(get_active_profile)" in
        a2dp*) pactl set-card-profile "$card" headset-head-unit ;;
        *) pactl set-card-profile "$card" a2dp-sink ;;
    esac
fi

source "$(dirname "${BASH_SOURCE[0]}")/bt-devices.sh"

mac=$(bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f2)
name=$(bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-)

dev=$name
for entry in "${BT_DEVICES[@]}"; do
    [ "${entry%% *}" = "$mac" ] && dev="${entry#* }"
done

case "$(get_active_profile)" in
    a2dp*) label=A2DP ;;
    headset*) label=HFP ;;
    *) label="" ;;
esac

[ -n "$dev" ] && echo "<span size='large'></span> ${dev}${label:+ [$label]}"

exit 0
