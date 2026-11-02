#!/usr/bin/env bash

# Shared bluetooth device registry: arg name -> "MAC label"
# Used by blconnect.sh (arg -> MAC) and i3blocks-bluetooth.sh (MAC -> label).
declare -A BT_DEVICES=(
    [jbl]="00:42:79:B7:C9:8D JBL"
    [px]="EC:66:D1:B5:29:8D PX"
    [air]="E0:EB:40:28:C8:9C AirPods"
    [razer]="44:5E:CD:21:72:61 Razer"
)
