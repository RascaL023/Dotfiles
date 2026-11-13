------------------------------------------ AUTOSTART ----
hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("eww daemon --force-wayland")
    hl.exec_cmd("swaync")
    hl.exec_cmd("$HOME/.config/waybar/waybar-ctl start")
end)
