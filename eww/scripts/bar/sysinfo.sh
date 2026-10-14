#!/usr/bin/env bash
# Pemakaian CPU dan memori + kelas peringatan, disamakan dengan modul
# `cpu` dan `memory` waybar:
#   cpu    : interval 2, warning 75, critical 90, ikon 󰍛(U+F035B),
#            format-warning/critical 󰀨(U+F0028)
#   memory : interval 10, warning 75, critical 90, ikon 󰘚(U+F061A),
#            format-warning/critical 󰀧(U+F0027)

cpu_usage() {
    # Baca /proc/stat dua kali; pemakaian = 1 - delta idle / delta total.
    read -r _ a b c d e f g h _ < /proc/stat
    idle1=$((d + e)); total1=$((a + b + c + d + e + f + g + h))
    sleep 0.2
    read -r _ a b c d e f g h _ < /proc/stat
    idle2=$((d + e)); total2=$((a + b + c + d + e + f + g + h))
    dt=$((total2 - total1)); di=$((idle2 - idle1))
    if [ "$dt" -le 0 ]; then
        echo 0
    else
        echo $(( (100 * (dt - di) + dt / 2) / dt ))
    fi
}

mem_percent() {
    awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2}
         END { if (t > 0) printf "%d", (100 * (t - a) + t / 2) / t; else print 0 }' \
        /proc/meminfo
}

cls() { # $1 = nilai, $2 = ikon normal, $3 = ikon peringatan
    if [ "$1" -ge 90 ]; then
        printf '{"class":"critical","icon":"%s"}' "$3"
    elif [ "$1" -ge 75 ]; then
        printf '{"class":"warning","icon":"%s"}' "$3"
    else
        printf '{"class":"","icon":"%s"}' "$2"
    fi
}

cpu=$(cpu_usage)
mem=$(mem_percent)

printf '{"cpu":%d,"ram":%d,"cpu_state":%s,"ram_state":%s}\n' \
    "$cpu" "$mem" \
    "$(cls "$cpu" "󰍛" "󰀨")" \
    "$(cls "$mem" "󰘚" "󰀧")"
