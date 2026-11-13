-- Per-namespace layer animation override.
--
-- Hyprland layer rules can only set the animation *style*, and that single
-- style is used for both layersIn and layersOut; rules cannot target the
-- sub-leaves separately (hyprwm/Hyprland#9894). So the override has to stay
-- enabled while the layer closes: disabling it on `layer.closed` hands the
-- exit animation back to the namespace's base rule (for rofi: slide down).
--
-- This helper keeps the style for a hold window after `layer.closed`, then
-- releases the namespace. Other tools only need `anim.layer{...}` plus
-- `handle.launch(...)`.

local anim = {}

-- The theme's `layers` animation runs at 4 ds (400 ms at motion.layers_speed
-- 1.0). The margin also covers slower presets and costs nothing unless a
-- layer is actually closing.
local DEFAULT_HOLD_MS = 700

-- opts = {
--   namespace = "rofi",          -- layer namespace to override (required)
--   animation = "fade",          -- style used for open AND close
--   name      = "anim-rofi",     -- rule name, unique per override
--   hold_ms   = 700,             -- how long the style survives the close
-- }
function anim.layer(opts)
    local namespace = type(opts) == "table" and opts.namespace or nil
    if type(namespace) ~= "string" or namespace == "" then
        error("anim.layer: namespace wajib berupa string", 2)
    end

    local style   = opts.animation or "fade"
    local hold_ms = opts.hold_ms or DEFAULT_HOLD_MS

    -- The newest matching layer rule wins, so this must be created after the
    -- namespace's base rule (rofi: hyprland.lua).
    local rule = hl.layer_rule({
        name      = opts.name or ("anim-" .. namespace),
        match     = { namespace = namespace },
        animation = style,
    })
    rule:set_enabled(false)

    -- Generations stop a close hold from disabling a newer launch.
    local generation = 0

    local handle = {
        rule      = rule,
        namespace = namespace,
        animation = style,
        hold_ms   = hold_ms,
    }

    -- Arm before launching: the rule must already be in place when the layer
    -- is mapped, otherwise the opening animation uses the base rule.
    function handle.arm()
        generation = generation + 1
        rule:set_enabled(true)
        return generation
    end

    -- Release early, without waiting for a close.
    function handle.disarm()
        generation = generation + 1
        rule:set_enabled(false)
    end

    function handle.launch(command)
        handle.arm()
        hl.exec_cmd(command)
    end

    hl.on("layer.closed", function(layer)
        if layer == nil or layer.namespace ~= namespace then
            return
        end

        local mine = generation
        if mine == 0 then
            return
        end

        hl.timer(function()
            -- A newer launch owns the rule now; leave it enabled.
            if generation == mine then
                rule:set_enabled(false)
            end
        end, { timeout = hold_ms, type = "oneshot" })
    end)

    return handle
end

return anim
