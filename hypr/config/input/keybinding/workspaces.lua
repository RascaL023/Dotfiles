-- Workspace-identity bindings: jumping to a workspace, sending a window to
-- one, and stepping through them with keys or the mouse wheel.

local kb  = require("config.input.keybinding.helpers")
local mod = kb.mod

-- ------------------------------------------------------ numbered workspaces --
for i = 1, 6 do
    hl.bind(mod .. " + " .. i,          hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i,  hl.dsp.window.move({ workspace = i, follow = false }))
    hl.bind("ALT + SHIFT + " .. i,      hl.dsp.window.move({ workspace = i, follow = true }))
end

-- Letter aliases for the same six workspaces.
local workspace_keys = { J = 1, K = 2, L = 3, U = 4, I = 5, O = 6 }

for key, workspace in pairs(workspace_keys) do
    hl.bind(mod .. " + ALT + " .. key,   hl.dsp.focus({ workspace = workspace }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace, follow = false }))
    hl.bind("ALT + SHIFT + " .. key,     hl.dsp.window.move({ workspace = workspace, follow = true }))
end

-- ------------------------------------------------------------- step relative --
hl.bind("CTRL + ALT + RIGHT", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("CTRL + ALT + LEFT",  hl.dsp.focus({ workspace = "e-1" }))
hl.bind("CTRL + ALT + L",     hl.dsp.focus({ workspace = "e+1" }))
hl.bind("CTRL + ALT + H",     hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mod .. " + mouse_up",           hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + mouse_down",         hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + CTRL + mouse_up",    hl.dsp.window.move({ workspace = "e-1", follow = true }))
hl.bind(mod .. " + CTRL + mouse_down",  hl.dsp.window.move({ workspace = "e+1", follow = true }))
