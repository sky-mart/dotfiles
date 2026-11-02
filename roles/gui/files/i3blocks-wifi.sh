#!/usr/bin/env bash

if [ "${BLOCK_BUTTON:-}" = 1 ]; then
    state_file="${XDG_RUNTIME_DIR:-/tmp}/i3blocks-network-visible"
    if [ -e "$state_file" ]; then
        rm -f "$state_file"
    else
        touch "$state_file"
    fi
    pkill -RTMIN+10 i3blocks
fi

ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2}')
if [ -n "$ssid" ]; then
    echo "<span size='large'></span> ${ssid}"
else
    wired_device=$(nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null | awk -F: '$2=="ethernet" && $3=="connected"{print $1; exit}')
    [ -n "$wired_device" ] && echo "<span size='large'>󰈀</span> ${wired_device}"
fi
