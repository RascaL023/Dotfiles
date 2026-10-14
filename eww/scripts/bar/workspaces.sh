#!/usr/bin/env bash
# Daftar workspace niri sebagai array JSON, satu array per baris.
#
# Dipakai eww sebagai `deflisten`: setiap baris yang dicetak langsung jadi
# nilai baru untuk `(for w in {ws} ...)`.
#
# niri tidak punya "5 workspace tetap" seperti konfigurasi waybar; workspace
# dibuat dan dihapus sesuai kebutuhan, jadi yang dikirim hanya yang benar-benar
# ada. Flag per workspace:
#   active   -> workspace yang sedang fokus  (dipakai kelas "active" waybar)
#   occupied -> ada jendela di sana          (dipakai kelas "occupied")
#   urgent   -> jendela minta perhatian      (dipakai kelas "urgent")

emit() {
    niri msg -j workspaces 2>/dev/null |
        jq -c '[.[] | {idx: .idx,
                       active: .is_focused,
                       occupied: (.active_window_id != null),
                       urgent: .is_urgent}]'
}

emit

# event-stream cuma dipakai sebagai pemicu; isinya format Debug Rust (bukan
# JSON), jadi setelah ada kejadian yang relevan kita tanyakan JSON-nya lagi.
niri msg event-stream 2>/dev/null | while read -r line; do
    case "$line" in
        Workspaces\ changed:*|Workspace\ activated*|Windows\ changed:*|Window\ focus\ changed*)
            emit
            ;;
    esac
done
