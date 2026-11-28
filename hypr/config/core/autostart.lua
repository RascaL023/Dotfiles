------------------------------------------ AUTOSTART ----
-- One question: which shell is recorded for this WM? constellia starts the
-- atlanta stack (awww, eww, swaync, bar) or noctalia, never both.
local home = os.getenv("HOME") or ""

hl.on("hyprland.start", function()
    hl.exec_cmd(home .. "/.local/bin/constellia shell start")
end)
