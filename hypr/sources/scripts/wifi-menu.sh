#!/usr/bin/env bash

ROFI_LAUNCHER=rofi-ctl

networks=$(nmcli -t -f SSID,SIGNAL dev wifi list | \
  awk -F: '{if ($1 != "") print $1 " (" $2"%)"}' | sort -u)
chosen=$(echo -e "$networks" | "$ROFI_LAUNCHER" menu -p "WiFi:")
[ -z "$chosen" ] && exit 0

ssid=$(echo "$chosen" | sed 's/ (.*//')
if nmcli dev wifi connect "$ssid"; then
    notify-send -t 3000 "   WiFi Connected!" "       Successfully connected to $ssid"
    exit 0
fi

password=$("$ROFI_LAUNCHER" password -p "Password for $ssid:")
[ -z "$password" ] && {
    notify-send -t 3000 "󰤮   WiFi Connection" "       Canceled connecting to $ssid"
    exit 1
}

if nmcli dev wifi connect "$ssid" password "$password"; then
    notify-send -t 3000 "   WiFi Connected!" "       Successfully connected to $ssid"
else
    notify-send -t 3000 "󰤮   WiFi Connection Failed..." "       Failed to connect to $ssid"
fi
