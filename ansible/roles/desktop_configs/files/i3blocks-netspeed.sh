#!/usr/bin/env bash

iface=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
[ -z "$iface" ] && exit 0

rx_now=$(cat "/sys/class/net/${iface}/statistics/rx_bytes" 2>/dev/null)
tx_now=$(cat "/sys/class/net/${iface}/statistics/tx_bytes" 2>/dev/null)
[ -z "$rx_now" ] || [ -z "$tx_now" ] && exit 0

now=$(date +%s)
state_file="/tmp/i3blocks-netspeed-${iface}"

if [ -f "$state_file" ]; then
    read -r prev_time prev_rx prev_tx < "$state_file"
else
    prev_time=$now
    prev_rx=$rx_now
    prev_tx=$tx_now
fi

echo "$now $rx_now $tx_now" > "$state_file"

dt=$((now - prev_time))
[ "$dt" -le 0 ] && dt=1

rx_rate=$(( (rx_now - prev_rx) / dt ))
tx_rate=$(( (tx_now - prev_tx) / dt ))
[ "$rx_rate" -lt 0 ] && rx_rate=0
[ "$tx_rate" -lt 0 ] && tx_rate=0

human() {
    awk -v b="$1" 'BEGIN {
        if (b < 1024) printf "%4d B/s", b
        else if (b < 1024*1024) printf "%5.1fK/s", b/1024
        else printf "%5.1fM/s", b/1024/1024
    }'
}

echo "<span size='large'>↓</span> <span font_family='monospace'>$(human "$rx_rate")</span>  <span size='large'>↑</span> <span font_family='monospace'>$(human "$tx_rate")</span>"
