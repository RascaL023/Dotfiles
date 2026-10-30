#!/usr/bin/env bash

# Compatibility entry point for the existing Hyprland and Niri keybindings.
exec "$HOME/.config/rofi/launch.sh" toggle apps "$@"
