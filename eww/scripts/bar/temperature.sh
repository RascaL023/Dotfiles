#!/usr/bin/env bash
# Suhu CPU + ikon, disalin dari perilaku modul `temperature` waybar.
#
# waybar: thermal-zone 1, critical-threshold 90,
#         format-icons [󱃃(U+F10C3), 󰔏(U+F050F), 󱃂(U+F10C2)],
#         format-critical 󰀦(U+F0026).
# `sensors` tidak ada di sistem ini, jadi nilainya dibaca langsung dari sysfs
# (thermal_zone1 = x86_pkg_temp, jenis sensor yang sama dengan "coretemp"
#  yang dipakai waybar).

zone=/sys/class/thermal/thermal_zone1/temp
raw=$(cat "$zone" 2>/dev/null) || raw=0
c=$(( (raw + 500) / 1000 ))     # mili-derajat -> derajat, dibulatkan

# Tiga ikon dibagi rata di bawah ambang kritis (90 / 3 = 30 derajat per ikon).
if [ "$c" -ge 90 ]; then
    icon="󰀦"                    # U+F0026 - format-critical
    cls="critical"
elif [ "$c" -ge 60 ]; then
    icon="󱃂"                    # U+F10C2
    cls=""
elif [ "$c" -ge 30 ]; then
    icon="󰔏"                    # U+F050F
    cls=""
else
    icon="󱃃"                    # U+F10C3
    cls=""
fi

printf '{"c":%d,"icon":"%s","class":"%s","critical":%s}\n' \
    "$c" "$icon" "$cls" "$([ "$c" -ge 90 ] && echo true || echo false)"
