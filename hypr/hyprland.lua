-- Orchestrator only. Order matters: appearance before rules, input last
-- because binds call the capabilities above them.

require("config.core")
require("config.layout")
require("config.appearance")
require("config.rule")
require("config.capability")
require("config.input") -- bindings last: they reference the capabilities above
