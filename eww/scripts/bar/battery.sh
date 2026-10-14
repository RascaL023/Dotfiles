#!/usr/bin/env bash
# Baterai + ikon, disamakan dengan modul `battery` waybar:
#   format '{icon} {capacity}%',
#   format-icons [󰂎,󰁻,󰁼,󰁽,󰁾,󰁿,󰂀,󰂁,󰂂,󰁹] -> U+F008E,F007B,F007C,F007D,
#                F007E,F007F,F0080,F0081,F0082,F0079
#   format-charging 󰉁(U+F0241), states warning 20, critical 10.
#
# waybar default-nya "BAT0"; di mesin ini baterainya bernama BAT1.

bat=/sys/class/power_supply/BAT1
cap=$(cat "$bat/capacity" 2>/dev/null)
status=$(cat "$bat/status" 2>/dev/null)

if [ -z "$cap" ]; then
    printf '{"percent":0,"status":"Unknown","icon":"󰂎","class":""}\n'
    exit 0
fi

icons=("󰂎" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹")
n=${#icons[@]}
idx=$(( (cap * (n - 1) + 50) / 100 ))      # pembulatan ke ikon terdekat
[ "$idx" -ge "$n" ] && idx=$((n - 1))

# Kelas dipakai scss untuk warna: charging/warning/critical (lihat waybar).
if [ "$status" = "Charging" ]; then
    icon="󰉁"                            # U+F0241 - format-charging
    cls="charging"
elif [ "$cap" -le 10 ]; then
    icon=${icons[$idx]}
    cls="critical"
elif [ "$cap" -le 20 ]; then
    icon=${icons[$idx]}
    cls="warning"
else
    icon=${icons[$idx]}
    cls=""
fi

printf '{"percent":%s,"status":"%s","icon":"%s","class":"%s"}\n' \
    "$cap" "$status" "$icon" "$cls"
