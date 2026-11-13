-- Composition root for the appearance package: look (hl.config) and motion
-- (curves + animations) are applied here, not in hyprland.lua.
--
-- Consumers that only need theme data must require the data module directly
-- (`config.appearance.palette`); that path does not load this file.

require("config.appearance.look")
require("config.appearance.motion")
