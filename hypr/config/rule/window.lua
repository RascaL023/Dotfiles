------------------------------------ WINDOW RULES --
local feel = require("config.appearance.feel")
hl.window_rule({
    name    = "foot-opacity",
    match   = { class = "^foot$" },
    opacity = tostring(feel.surface.terminal_opacity),
})

hl.window_rule({
    name    = "codium-opacity",
    match   = { class = "^(codium)$" },
    opacity = "0.9",
})

hl.window_rule({
    name  = "ttyper-float",
    match = { class = "^(ttyper)$" },
    float = true,
    size  = { 900, 500 },
    center = true,
})

hl.window_rule({
    name  = "kitty-float",
    match = { class = "^kitty-float$" },
    float = true,
    size  = { 900, 560 },
    center = true,
})
