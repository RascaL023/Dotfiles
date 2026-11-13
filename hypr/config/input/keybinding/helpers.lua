-- The modifier, script path and command dispatchers are defined once here so
-- every binding module speaks the same vocabulary. Layout-aware chords go
-- through `layout_switch`: the scrolling layout is per-workspace, so a dwindle
-- workspace gets the plain dispatcher instead.

local home = os.getenv("HOME") or ""

local helpers = {}

helpers.mod  = "SUPER"
helpers.home = home

function helpers.exec(cmd) return hl.dsp.exec_cmd(cmd) end
function helpers.layout(msg) return hl.dsp.layout(msg) end

function helpers.script(name)
    return hl.dsp.exec_cmd(home .. "/.config/hypr/sources/scripts/" .. name)
end

local function tiled_layout()
    local ws = hl.get_active_workspace()
    return ws and ws.tiled_layout or "dwindle"
end

function helpers.layout_switch(in_scrolling, otherwise)
    return function()
        hl.dispatch(tiled_layout() == "scrolling" and in_scrolling() or otherwise())
    end
end

return helpers
