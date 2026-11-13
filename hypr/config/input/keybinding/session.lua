-- Session lifecycle: lock the screen, open the logout dialog, toggle idle
-- inhibition. Scripts own the dialogs; these bindings only trigger them.

local kb  = require("config.input.keybinding.helpers")
local mod = kb.mod

hl.bind(mod .. " + CTRL + L",  kb.exec("hyprlock"))
hl.bind(mod .. " + ESCAPE",    kb.script("wlogout-toggle.sh"))
hl.bind(mod .. " + I",         kb.script("idle-toggle.sh"))
