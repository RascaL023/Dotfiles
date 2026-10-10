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

  colors = {
    "{{ colors.surface_container_lowest.default.hex }}",
    "{{ colors.error.default.hex }}",
    "{{ colors.secondary.default.hex }}",
    "{{ colors.tertiary.default.hex }}",
    "{{ colors.primary.default.hex }}",
    "{{ colors.tertiary.default.hex }}",
    "{{ colors.secondary.default.hex }}",
    "{{ colors.on_surface.default.hex }}",

    "{{ colors.outline.default.hex }}",
    "{{ colors.error.default.hex }}",
    "{{ colors.secondary.default.hex }}",
    "{{ colors.tertiary.default.hex }}",
    "{{ colors.primary.default.hex }}",
    "{{ colors.tertiary.default.hex }}",
    "{{ colors.secondary.default.hex }}",
    "{{ colors.on_surface_variant.default.hex }}",
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

    syntax = {
      -- Whisper
      comment = "{{ colors.outline.default.hex }}",
      punctuation = "{{ colors.outline.default.hex }}",
      property = "{{ colors.on_surface_variant.default.hex }}",
      parameter = "{{ colors.on_surface_variant.default.hex }}",

      -- Hero
      keyword = "{{ colors.primary.default.hex }}",
      statement = "{{ colors.primary.default.hex }}",
      ["return"] = "{{ colors.primary.default.hex }}",
      import = "{{ colors.primary.default.hex }}",
      decorator = "{{ colors.primary.default.hex }}",

      -- Cast
      ["function"] = "{{ colors.secondary.default.hex }}",
      method = "{{ colors.secondary.default.hex }}",
      type = "{{ colors.tertiary.default.hex }}",
      class = "{{ colors.tertiary.default.hex }}",
      builtin = "{{ colors.secondary.default.hex }}",

      -- Whisper / data
      string = "{{ colors.on_surface_variant.default.hex }}",
      number = "{{ colors.on_surface_variant.default.hex }}",
      boolean = "{{ colors.tertiary.default.hex }}",
      constant = "{{ colors.tertiary.default.hex }}",
      variable = "{{ colors.on_surface.default.hex }}",
      identifier = "{{ colors.on_surface.default.hex }}",

      -- Special
      operator = "{{ colors.primary.default.hex }}",
      regex = "{{ colors.secondary.default.hex }}",
      builtin_variable = "{{ colors.secondary.default.hex }}",
      special = "{{ colors.tertiary.default.hex }}",

      -- Diagnostics / destructive syntax
      exception = "{{ colors.error.default.hex }}",
      tag = "{{ colors.error.default.hex }}",
      attribute = "{{ colors.tertiary.default.hex }}",
    },

    ui = {
      bg_statusline = "{{ colors.surface_container.default.hex }}",
      gutter = "{{ colors.surface_container_high.default.hex }}",
    },
  },
}
