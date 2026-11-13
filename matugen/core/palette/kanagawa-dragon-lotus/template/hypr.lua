-- ############################
-- ## Generated with Matugen ##
-- ############################
-- ## Manual edit is not recomended,
-- ## Except for testing.


return {
    shape = {
        border_active   = "rgba({{ accent.primary | to_color | format: hex_stripped }}ee)",
        border_active2  = "rgba({{ accent.secondary | to_color | format: hex_stripped }}ee)",
        border_inactive = "rgba({{ surface.lowest | to_color | format: hex_stripped }}ee)",
    },

    material = {
        shadow = {
            color = "rgba({{ effect.shadow | to_color | format: hex_stripped }}ee)",
        },
    },

    chrome = {
        nogroup_border = "rgba({{ border.medium | to_color | format: hex_stripped }}99)",

        groupbar = {
            text_color = "rgba({{ accent.on_primary | to_color | format: hex_stripped }}ee)",
        },
    },
}
