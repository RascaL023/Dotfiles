#!/usr/bin/env bash
# Status Wi-Fi + ikon, disamakan dengan modul `network` waybar:
#   format-icons [󰤟(U+F091F), 󰤢(U+F0922), 󰤥(U+F0925), 󰤨(U+F0928)] per kekuatan,
#   format-disconnected 󰤯(U+F092F), format-disabled 󰤮(U+F092E),
#   format-ethernet 󰈀(U+F0200).

line=$(nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | grep '^yes' | head -n1)

if [ -z "$line" ]; then
    printf '{"icon":"󰤯","ssid":"","signal":0,"state":"disconnected"}\n'
    exit 0
fi

# Format nmcli: "<active>:<ssid>:<signal>" - ssid bisa memuat titik dua yang
# di-escape, jadi pecah dari kanan.
signal=${line##*:}
rest=${line%:*}
ssid=${rest#*:}
ssid=${ssid//\\:/:}

# Empat ikon dibagi per 25% kekuatan sinyal.
if   [ "$signal" -ge 75 ]; then icon="󰤨"    # U+F0928
elif [ "$signal" -ge 50 ]; then icon="󰤥"    # U+F0925
elif [ "$signal" -ge 25 ]; then icon="󰤢"    # U+F0922
else                            icon="󰤟"    # U+F091F
fi

printf '{"icon":"%s","ssid":"%s","signal":%s,"state":"wifi"}\n' \
    "$icon" "$ssid" "$signal"
