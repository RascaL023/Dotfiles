-- ############################
-- ## Generated with Matugen ##
-- ############################
-- ## Manual edit is not recommended,
-- ## Except for testing.

return {
  source = "{{ colors.source_color.default.hex }}",

  background = "{{ colors.background.default.hex }}",
  foreground = "{{ colors.on_surface.default.hex }}",
  cursor = "{{ colors.primary.default.hex }}",

  -- ANSI 0..15. Normal slots are the MD3 accents, bright slots lift the
  -- same jobs onto the `*_fixed`/container tones (like the other general
  -- templates) so a normal color is never identical to its bright pair.
  colors = {
    "{{ colors.surface_container_lowest.default.hex }}",
    "{{ colors.error.default.hex }}",
    "{{ colors.tertiary.default.hex }}",
    "{{ colors.secondary.default.hex }}",
    "{{ colors.primary.default.hex }}",
    "{{ colors.tertiary.default.hex | lighten: -10 }}",
    "{{ colors.secondary.default.hex | lighten: -10 }}",
    "{{ colors.on_surface.default.hex }}",

    "{{ colors.outline.default.hex }}",
    "{{ colors.error_container.default.hex | blend: {{ colors.primary.default.hex }}, 0.6 | lighten: 40 }}",
    "{{ colors.tertiary_container.default.hex }}",
    "{{ colors.secondary_container.default.hex }}",
    "{{ colors.primary_container.default.hex }}",
    "{{ colors.tertiary_fixed.default.hex }}",
    "{{ colors.secondary.default.hex | lighten: -8 }}",
    "{{ colors.on_surface.default.hex | lighten: 10 }}",
  },

  extra = {
    accent = {
      primary = "{{ colors.primary.default.hex }}",
      secondary = "{{ colors.secondary.default.hex }}",
      tertiary = "{{ colors.tertiary.default.hex }}",
      on_accent = "{{ colors.on_primary.default.hex }}",
      on_tertiary = "{{ colors.on_tertiary.default.hex }}",
    },

    container = {
      primary = "{{ colors.primary_container.default.hex }}",
      on_primary = "{{ colors.on_primary_container.default.hex }}",
      secondary = "{{ colors.secondary_container.default.hex }}",
      on_secondary = "{{ colors.on_secondary_container.default.hex }}",
      tertiary = "{{ colors.tertiary_container.default.hex }}",
      on_tertiary = "{{ colors.on_tertiary_container.default.hex }}",
    },

    text = {
      primary = "{{ colors.on_surface.default.hex }}",
      secondary = "{{ colors.on_surface_variant.default.hex }}",
      muted = "{{ colors.outline.default.hex }}",
      link = "{{ colors.primary.default.hex }}",
      visited = "{{ colors.secondary.default.hex }}",
    },

    layer = {
      base = "{{ colors.background.default.hex }}",
      mantle = "{{ colors.surface_container_lowest.default.hex }}",
      crust = "{{ colors.surface_container_low.default.hex }}",
      surface = "{{ colors.surface.default.hex }}",
      surface_raised = "{{ colors.surface_container_high.default.hex }}",
      surface_overlay = "{{ colors.surface_container_highest.default.hex }}",
    },

    border = {
      default = "{{ colors.outline_variant.default.hex }}",
      active = "{{ colors.primary.default.hex }}",
      medium = "{{ colors.outline.default.hex }}",
    },

    status = {
      success = "#86A361",
      warning = "#C6A664",
      error = "{{ colors.error.default.hex }}",
      critical = "#D16D6D",
      info = "{{ colors.primary.default.hex }}",
    },

    fg = {
      dim = "{{ colors.outline_variant.default.hex }}",
      dim_muted = "{{ colors.outline.default.hex }}",
      disabled = "{{ colors.outline.default.hex }}",
    },

    bg = {
      conflict = "{{ colors.error_container.default.hex }}",
      disk_usage = "{{ colors.secondary_container.default.hex }}",
    },

    -- Setiap peran tetap berasal dari warna matugen. Keluarga aksen
    -- (primary = violet, tertiary = rose) dibagi lagi lewat `lighten` negatif
    -- yang menaikkan saturasi, sehingga token yang berkerabat punya nada
    -- berbeda tanpa keluar dari aksen wallpaper. `blend` dipakai untuk
    -- menggeser hue token "whisper" agar menyatu dengan aksen (blend di sini
    -- menjaga terang/saturasi, jadi cuma menggeser hue).
    syntax = {
      -- Whisper: tetap redup, tapi dihangatkan ke hue aksen
      comment = "{{ colors.outline.default.hex | blend: {{ colors.tertiary.default.hex }}, 0.5 }}",
      punctuation = "{{ colors.outline.default.hex }}",
      property = "{{ colors.on_surface.default.hex | lighten: -1 }}",
      parameter = "{{ colors.on_surface.default.hex | lighten: -5 }}",

      -- Hero: struktur kalimat (tiga nada violet)
      keyword = "{{ colors.primary.default.hex }}",
      statement = "{{ colors.tertiary.default.hex }}",
      ["return"] = "{{ colors.primary.default.hex }}",
      import = "{{ colors.primary.default.hex | lighten: -10 }}",
      decorator = "{{ colors.primary.default.hex | lighten: -6 }}",

      -- Cast: yang dipanggil vs tipe
      ["function"] = "{{ colors.primary.default.hex | lighten: -10 }}",
      method = "{{ colors.primary.default.hex | lighten: -9 }}",
      type = "{{ colors.primary.default.hex | lighten: -5 }}",
      class = "{{ colors.primary.default.hex | lighten: -13 }}",
      builtin = "{{ colors.primary.default.hex | lighten: -15 }}",

      -- Data: rose untuk string, lavender untuk angka/konstanta
      string = "{{ colors.tertiary.default.hex | lighten: -14 }}",
      number = "{{ colors.secondary.default.hex | lighten: -14 }}",
      boolean = "{{ colors.tertiary.default.hex | lighten: -8 }}",
      constant = "{{ colors.secondary.default.hex | lighten: -20 }}",
      variable = "{{ colors.on_surface.default.hex }}",
      identifier = "{{ colors.on_surface.default.hex }}",

      -- Special
      operator = "{{ colors.secondary.default.hex | lighten: -4 }}",
      regex = "{{ colors.tertiary.default.hex | lighten: -26 }}",
      builtin_variable = "{{ colors.secondary.default.hex | lighten: -8 }}",
      special = "{{ colors.tertiary.default.hex | blend: {{ colors.secondary.default.hex }}, 0.5 | lighten: -10 }}",

      -- Diagnostics / destructive syntax
      exception = "{{ colors.error.default.hex }}",
      tag = "{{ colors.error.default.hex }}",
      attribute = "{{ colors.primary.default.hex | lighten: -17 }}",
    },

    ui = {
      bg_statusline = "{{ colors.surface_container.default.hex }}",
      gutter = "{{ colors.surface_container_high.default.hex }}",
    },
  },
}
