#!/usr/bin/env bash

if pgrep waybar > /dev/null; then
    pkill waybar
else
    # launch.sh memilih config.hyprland.jsonc (dengan hyprland/workspaces)
    # saat HYPRLAND_INSTANCE_SIGNATURE ada, dan config.niri.jsonc kalau tidak.
    ~/.config/waybar/launch.sh &
fi
