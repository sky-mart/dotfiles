#!/usr/bin/env bash

case $1 in
    jbl)
        mac_to_connect=00:42:79:B7:C9:8D
        ;;

    px)
        mac_to_connect=EC:66:D1:B5:29:8D
        ;;

    air)
        mac_to_connectE0:EB:40:28:C8:9C
        ;;

    *)
        exit 1
        ;;
esac

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
