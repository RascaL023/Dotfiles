-- Desktop shell surfaces owned by other tools: bar toggles, notification
-- center, wallpaper picker, theme picker and the blue-light filter.

local kb  = require("config.input.keybinding.helpers")
local mod = kb.mod
local exec = kb.exec
local script = kb.script
local home = kb.home

local rofi = require("config.integration.rofi")

-- ---------------------------------------------------------------------- bar --
hl.bind(mod .. " + O",        script("waybar-toggle.sh"))
hl.bind(mod .. " + X",        exec("eww open --toggle profile"))
hl.bind(mod .. " + D",        exec("eww open --toggle distro"))
hl.bind(mod .. " + CTRL + X", exec("pkill eww; eww daemon --force-wayland"))

-- ------------------------------------------------------------ notifications --
hl.bind(mod .. " + N", exec("swaync-client -t"))

-- ---------------------------------------------------- wallpaper and theme ---
-- `rofi.pick_wallpaper` arms a layer-animation override before launching.
hl.bind(mod .. " + W", function() rofi.pick_wallpaper() end)
hl.bind(mod .. " + T", exec(home .. "/.myenv/script/theme/theme-picker.sh"))

-- --------------------------------------------------------------- blue light --
hl.bind(mod .. " + SHIFT + N", script("bluelight-toggle.sh"))
