-- ############################
-- ## Generated with Matugen ##
-- ############################
-- ## Manual edit is not recomended,
-- ## Except for testing.

-- Dibaca oleh hypr/config/core/theme/palette.lua lewat
-- ~/.myenv/theme/palette/current/hypr/theme.lua. Berkas ini murni data: hanya boleh
-- `return { ... }`, tanpa panggilan fungsi.
--
-- Berkas ini hanya berisi WARNA. Angka "rasa" (shape, surface, material,
-- motion, chrome) dimiliki profil feel per WM:
-- ~/.myenv/theme/feel/current/hypr/feel.lua, dirender dari
-- core/feel/profiles/<profil>/hypr.json. Jangan menyalin angka ke sini.

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
