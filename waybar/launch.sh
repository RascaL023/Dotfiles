#!/usr/bin/env bash
# Jalankan waybar dengan config sesuai compositor yang aktif.
#
#   ~/.config/waybar/launch.sh          # dipakai di niri
#   ~/.config/waybar/launch.sh &        # latar belakang
#
# Alasannya: modul workspace milik compositor yang tidak jalan membuat waybar
# segfault, jadi `hyprland/workspaces` dan `niri/workspaces` tidak boleh berada
# di `modules-left` yang sama.
set -euo pipefail

dir=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
	cfg="$dir/config.hyprland.jsonc"
else
	cfg="$dir/config.niri.jsonc"
fi

exec waybar -c "$cfg" "$@"
