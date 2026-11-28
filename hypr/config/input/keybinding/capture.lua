-- Screen capture: fullscreen/region screenshot and colour picking. Capture is
-- constellia's (grim on atlanta, the Noctalia tool otherwise).

local kb  = require("config.input.keybinding.helpers")
local mod = kb.mod
local exec = kb.exec

hl.bind(mod .. " + ALT + PRINT", kb.constellia("screenshot", "screen"))
hl.bind(mod .. " + PRINT",       kb.constellia("screenshot", "region"))
hl.bind(mod .. " + CTRL + P",  exec([[hyprpicker -a | wl-copy && notify-send "Color picked!" "$(wl-paste)"]]))
