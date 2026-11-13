-- Media keys: sink/source volume, backlight, and the MPD transport. Feedback
-- goes through swaync with the synchronous hint, so holding a key updates one
-- bubble instead of stacking a notification per repeat.

local kb  = require("config.input.keybinding.helpers")
local mod = kb.mod
local exec = kb.exec

local function volume(step)
    return exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ " .. step .. " -l 1.0 && " ..
        "notify-send -h string:x-canonical-private-synchronous:volume " ..
        "\"Volume: $(pamixer --get-volume)%\" -t 800")
end

local function brightness(step)
    return exec("brightnessctl -q set " .. step .. " && " ..
        "notify-send -h string:x-canonical-private-synchronous:brightness " ..
        "\"Brightness: $((100 * $(brightnessctl g) / $(brightnessctl m)))%\" -t 800")
end

local function mute(source, label)
    return exec("wpctl set-mute " .. source .. " toggle && notify-send \"" .. label .. "\" -t 1000")
end

-- -------------------------------------------------------------------- audio --
hl.bind("XF86AudioRaiseVolume",  volume("0.05+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  volume("0.05-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",         mute("@DEFAULT_AUDIO_SINK@",   "Volume toggled"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      mute("@DEFAULT_AUDIO_SOURCE@", "Mic toggled"),    { locked = true, repeating = true })

-- ---------------------------------------------------------------- backlight --
hl.bind("XF86MonBrightnessUp",   brightness("+5%"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", brightness("5%-"), { locked = true, repeating = true })

-- -------------------------------------------------------------------- music --
hl.bind(mod .. " + SHIFT + M", exec("mpc toggle"))
hl.bind(mod .. " + ALT + P",   exec("pkill mpd"))
