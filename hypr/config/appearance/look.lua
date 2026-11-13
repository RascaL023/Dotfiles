-- Renders the theme's Hyprland option tree. The field -> option mapping and
-- normalization live in `config.appearance.palette`; this module only hands
-- the result to the compositor.

local theme = require("config.appearance.palette")

hl.config(theme.hypr)
