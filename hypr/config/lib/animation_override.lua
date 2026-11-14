-- Hyprland uses one layer animation style for open and close, so the override
-- has to outlive layer.closed and is released afterwards.

local anim = {}

local DEFAULT_HOLD_MS = 700

-- opts = { namespace, animation, name, hold_ms }
function anim.layer(opts)
    local namespace = type(opts) == "table" and opts.namespace or nil
    if type(namespace) ~= "string" or namespace == "" then
        error("anim.layer: namespace wajib berupa string", 2)
    end

    local style = opts.animation or "fade"
    local hold_ms = opts.hold_ms or DEFAULT_HOLD_MS

    local rule = hl.layer_rule({
        name      = opts.name or ("anim-" .. namespace),
        match     = { namespace = namespace },
        animation = style,
    })
    rule:set_enabled(false)

    local generation = 0

    local handle = {
        rule      = rule,
        namespace = namespace,
        animation = style,
        hold_ms   = hold_ms,
    }

    -- Must be enabled before the layer maps.
    function handle.arm()
        generation = generation + 1
        rule:set_enabled(true)
        return generation
    end

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
            -- A newer launch keeps the rule enabled.
            if generation == mine then
                rule:set_enabled(false)
            end
        end, { timeout = hold_ms, type = "oneshot" })
    end)

    return handle
end

return anim
