-- Launcher capability: callers ask for a surface, the adapter owns the program.
-- Bindings never spell out `rofi-ctl <subcommand>`; swapping the launcher means
-- changing the adapter require below (and adding the adapter file).
--
-- Subcommands that print a selection and leave the action to the caller
-- (`wallpaper`, `menu`, `password`) stay in the shell scripts: they need stdout,
-- which a fire-and-forget dispatcher cannot give them.

local adapter = require("config.adapter.rofi")

local launcher = {}

local function dispatch(...)
    return hl.dsp.exec_cmd(adapter.command(...))
end

-- style: "apps" (default) or "orbit".
function launcher.apps(style)    return dispatch("apps", style) end
function launcher.run(style)     return dispatch("run", style) end

function launcher.window()       return dispatch("window") end
function launcher.toggle(style)  return dispatch("toggle", style) end

-- The picker is a launcher surface too, but it needs its layer animation armed
-- before launch; the adapter keeps that detail internal.
function launcher.pick_wallpaper()
    adapter.pick_wallpaper()
end

return launcher
