#!/usr/bin/env bash
# Kecerahan layar + ikon, disamakan dengan modul `backlight` waybar:
#   format '{icon} {percent}%',
#   format-icons U+E38D,E3D3,E3D1,E3CF,E3CE,E3CD,E3CA,E3C8,E39B
# Sembilan ikon dibagi rata sepanjang 0-100%.
#
# Glif ditulis sebagai escape $'\uXXXX': karakter U+E38D sengaja tidak ditulis
# literal supaya tidak tertukar dengan ikon lain yang bentuknya serupa.

if ! command -v brightnessctl >/dev/null 2>&1; then
    printf '{"percent":0,"icon":"\ue38d"}\n'
    exit 0
fi

# brightnessctl -m -> "device,class,current,percent%,max"
pct=$(brightnessctl -m 2>/dev/null | awk -F, '{gsub(/%/, "", $4); print $4}')
[ -n "$pct" ] || pct=0

icons=($'\ue38d' $'\ue3d3' $'\ue3d1' $'\ue3cf' $'\ue3ce' \
        $'\ue3cd' $'\ue3ca' $'\ue3c8' $'\ue39b')
n=${#icons[@]}
idx=$(( pct * n / 101 ))
[ "$idx" -ge "$n" ] && idx=$((n - 1))

printf '{"percent":%d,"icon":"%s"}\n' "$pct" "${icons[$idx]}"
