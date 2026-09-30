#!/usr/bin/env bash

bat=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
[ -z "$bat" ] && exit 0

capacity=$(cat "$bat/capacity" 2>/dev/null)
status=$(cat "$bat/status" 2>/dev/null)

if [ "$capacity" -ge 90 ]; then
    icon=$''
elif [ "$capacity" -ge 60 ]; then
    icon=$''
elif [ "$capacity" -ge 40 ]; then
    icon=$''
elif [ "$capacity" -ge 15 ]; then
    icon=$''
else
    icon=$''
fi

bolt=""
[ "$status" = "Charging" ] && bolt=$' '

echo "<span size='large'>${icon}</span> ${capacity}%${bolt}"
