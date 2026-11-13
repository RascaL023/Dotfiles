-- Surface capabilities. Loaded explicitly by hyprland.lua after config.rule so
-- adapters append their layer rules after the global ones, and before
-- config.input so bindings always see a fully loaded capability.

require("config.capability.launcher")
