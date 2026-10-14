#!/usr/bin/env bash
# Volume keluaran (sink) + ikon, disamakan dengan modul `pulseaudio#output`
# waybar:
#   format '{icon} {volume}%', format-muted 󰝟(U+F075F),
#   format-icons default [󰕿(U+F057F), 󰖀(U+F0580), 󰕾(U+F057E)].
#
# `pactl` tidak tersedia di sistem ini, jadi pamixer yang dipakai.

if ! command -v pamixer >/dev/null 2>&1; then
    printf '{"percent":0,"muted":false,"icon":"󰕿"}\n'
    exit 0
fi

vol=$(pamixer --get-volume 2>/dev/null || echo 0)
muted=$(pamixer --get-mute 2>/dev/null || echo false)

if [ "$muted" = "true" ]; then
    icon="󰝟"                    # U+F075F - format-muted
    vol=0
elif [ "$vol" -ge 67 ]; then
    icon="󰕾"                    # U+F057E
elif [ "$vol" -ge 34 ]; then
    icon="󰖀"                    # U+F0580
else
    icon="󰕿"                    # U+F057F
fi

printf '{"percent":%s,"muted":%s,"icon":"%s"}\n' "$vol" "$muted" "$icon"
