-- Orchestrator only: every hl.* option lives in the package that owns it.
-- Note: Order matters!
--
-- core       identity: environment, monitor, autostart
-- layout     window management policy (general, dwindle, master, scrolling, binds)
-- appearance look (hl.config) + motion (curves and animations)
-- rule       window and layer rules
-- capability surface adapters (launcher); their layer rules append here
-- input      device settings, gestures, then the keymap last

require("config.core")
require("config.layout")
require("config.appearance")
require("config.rule")
require("config.capability")
require("config.input") -- bindings last: they reference the capabilities above
