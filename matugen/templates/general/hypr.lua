-- ############################
-- ## Generated with Matugen ##
-- ############################
-- ## Manual edit is not recomended,
-- ## Except for testing.

-- Dibaca oleh hypr/config/core/theme.lua lewat
-- ~/.myenv/theme/current/hypr/theme.lua. Berkas ini murni data: hanya boleh
-- `return { ... }`, tanpa panggilan fungsi.
--
-- Flow A (wallpaper) hanya menghasilkan warna. Bagian "rasa" (shape, surface,
-- material, motion, chrome) tidak ditulis di sini karena gambar tidak membawa
-- metadata desain; default di config/core/theme.lua yang berlaku. Tema
-- blueprint (Flow B) menulis bagian itu dari objek `feel` di blueprint-nya.
--
-- Field yang tidak ada di sini tidak perlu ada: theme.lua menggabungkan
-- berkas ini di atas default-nya, jadi yang kosong otomatis memakai default.

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
