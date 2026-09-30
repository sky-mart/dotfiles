#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/bt-devices.sh"

entry="${BT_DEVICES[$1]}"
[ -n "$entry" ] || exit 1
mac_to_connect="${entry%% *}"

already_connected=false

# disconnect all devices first
for mac in $(hcitool con | rg \< | awk '{print $3}'); do
    if [ "$mac" == "$mac_to_connect" ]; then
        already_connected=true
    else
        bluetoothctl disconnect $mac
    fi
done

if [ "$already_connected" = false ]; then
    bluetoothctl connect $mac_to_connect
fi
