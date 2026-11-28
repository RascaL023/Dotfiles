-- Media keys: sink/source volume, backlight, and the MPD transport. Volume and
-- mic feedback is constellia's OSD, which maps onto whichever shell owns it.

local kb  = require("config.input.keybinding.helpers")
local mod = kb.mod
local exec = kb.exec

local function brightness(step)
    return exec("brightnessctl -q set " .. step .. " && " ..
        "notify-send -h string:x-canonical-private-synchronous:brightness " ..
        "\"Brightness: $((100 * $(brightnessctl g) / $(brightnessctl m)))%\" -t 800")
end

-- -------------------------------------------------------------------- audio --
hl.bind("XF86AudioRaiseVolume",  kb.constellia("volume", "up"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  kb.constellia("volume", "down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",         kb.constellia("volume", "mute"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      kb.constellia("mic", "toggle"),  { locked = true, repeating = true })

-- ---------------------------------------------------------------- backlight --
hl.bind("XF86MonBrightnessUp",   brightness("+5%"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", brightness("5%-"), { locked = true, repeating = true })

-- -------------------------------------------------------------------- music --
hl.bind(mod .. " + SHIFT + M", exec("mpc toggle"))
hl.bind(mod .. " + ALT + P",   exec("pkill mpd"))
