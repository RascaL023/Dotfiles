-- ############################
-- ## Generated with Matugen ##
-- ############################
-- ## Manual edit is not recomended,
-- ## Except for testing.


return {
    shape = {
        border_active   = "rgba({{ colors.primary.default.hex_stripped }}ee)",
        border_active2  = "rgba({{ colors.secondary.default.hex_stripped }}ee)",
        border_inactive = "rgba({{ colors.surface_container_lowest.default.hex_stripped }}ee)",
    },

    material = {
        shadow = {
            color = "rgba({{ colors.shadow.default.hex_stripped }}ee)",
        },
    },

    chrome = {
        nogroup_border = "rgba({{ colors.outline_variant.default.hex_stripped }}99)",

        groupbar = {
            text_color = "rgba({{ colors.on_primary.default.hex_stripped }}ee)",
        },
    },
}
