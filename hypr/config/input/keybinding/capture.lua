-- Screen capture: fullscreen/region screenshot and colour picking. Both write
-- to the Wayland clipboard or Pictures directory, never to the compositor.

local kb  = require("config.input.keybinding.helpers")
local mod = kb.mod
local exec = kb.exec

hl.bind(mod .. " + ALT + PRINT", exec([[grim -o LVDS-1 "$HOME/Pictures/Screenshots/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png" && notify-send -t 2000 "Screenshot" "Successfully took fullscreen screenshot!"]]))
hl.bind(mod .. " + PRINT",       exec([[grim -g "$(slurp)" "$HOME/Pictures/Screenshots/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png" && notify-send -t 2000 "Screenshot" "Successfully took partial screenshot!"]]))
hl.bind(mod .. " + CTRL + P",  exec([[hyprpicker -a | wl-copy && notify-send "Color picked!" "$(wl-paste)"]]))
