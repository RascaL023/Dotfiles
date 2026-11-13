-- Composition root for the appearance package: look (hl.config) and motion
-- (curves + animations) are applied here, not in hyprland.lua.
--
-- Data modules are separate and load on demand:
--   palette.lua  colours, from the palette store
--   feel.lua     numbers/booleans, from the feel store
-- Requiring either one does not load this file or apply anything.

require("config.appearance.look")
require("config.appearance.motion")
