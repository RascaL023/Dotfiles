-- Launching programs and menus. A binding in this module only starts a
-- process; it never inspects or rearranges existing windows.

local kb   = require("config.input.keybinding.helpers")
local mod  = kb.mod
local exec = kb.exec
local script = kb.script

-- ----------------------------------------------------------------- launcher --
-- Still the concrete launcher; the launcher abstraction is a separate step.
hl.bind(mod .. " + SPACE",          exec("rofi-ctl toggle apps"))

-- ----------------------------------------------------------------- browser --
hl.bind(mod .. " + B",              exec("firefox"))

-- ---------------------------------------------------------------- terminals --
hl.bind(mod .. " + RETURN",         exec("kitty"))
hl.bind(mod .. " + SHIFT + RETURN", exec("foot"))
hl.bind(mod .. " + ALT + RETURN",   exec("kitty --class kitty-float"))
hl.bind(mod .. " + CTRL + RETURN",  exec("alacritty"))
hl.bind(mod .. " + CTRL + T",       exec("kitty --class ttyper -e ttyper"))

-- ------------------------------------------------------------------- files --
hl.bind(mod .. " + E",              exec("nemo"))
hl.bind(mod .. " + SHIFT + E",      exec("kitty -e yazi"))

-- ------------------------------------------------------------------ menus ---
-- Interactive script; the menu surface itself lives outside Hyprland.
hl.bind(mod .. " + C",              script("wifi-menu.sh"))
