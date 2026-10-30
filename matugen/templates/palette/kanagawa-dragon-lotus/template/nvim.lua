-- ############################
-- ## Generated with Matugen ##
-- ############################
-- ## Manual edit is not recommended,
-- ## Except for testing.

return {
  background = "{{ background }}",
  foreground = "{{ foreground }}",
  cursor = "{{ cursor }}",

  colors = {
<* for c in colors *>    "{{ c }}",
<* endfor *>  },

  extra = {
    accent = {
      primary = "{{ accent.primary }}",
      secondary = "{{ accent.secondary }}",
      tertiary = "{{ accent.tertiary }}",
      on_accent = "{{ accent.on_primary }}",
      on_tertiary = "{{ accent.on_tertiary }}",
    },

    container = {
      primary = "{{ accent.primary_container }}",
      on_primary = "{{ accent.on_primary_container }}",
      secondary = "{{ accent.secondary_container }}",
      on_secondary = "{{ accent.on_secondary_container }}",
      tertiary = "{{ accent.tertiary_container }}",
      on_tertiary = "{{ accent.on_tertiary_container }}",
    },

    text = {
      primary = "{{ text.primary }}",
      secondary = "{{ text.secondary }}",
      muted = "{{ text.muted }}",
      link = "{{ text.link }}",
      visited = "{{ text.visited }}",
    },

    layer = {
      base = "{{ surface.base }}",
      mantle = "{{ surface.lowest }}",
      crust = "{{ surface.low }}",
      surface = "{{ surface.medium }}",
      surface_raised = "{{ surface.high }}",
      surface_overlay = "{{ surface.highest }}",
    },

    border = {
      default = "{{ border.default }}",
      active = "{{ border.active }}",
      medium = "{{ border.medium }}",
    },

    status = {
      success = "{{ status.success }}",
      warning = "{{ status.warning }}",
      error = "{{ status.error }}",
      critical = "{{ status.critical }}",
      info = "{{ status.info }}",
    },

    fg = {
      dim = "{{ text.subtle }}",
      dim_muted = "{{ text.faint }}",
      disabled = "{{ text.disabled }}",
    },

    bg = {
      conflict = "{{ status.warning_container }}",
      disk_usage = "{{ surface.track }}",
    },

    syntax = {
      comment = "{{ syntax.comment }}",
      keyword = "{{ syntax.keyword }}",
      statement = "{{ syntax.statement }}",
      ["function"] = "{{ syntax.function }}",
      method = "{{ syntax.method }}",
      string = "{{ syntax.string }}",
      constant = "{{ syntax.constant }}",
      number = "{{ syntax.number }}",
      boolean = "{{ syntax.boolean }}",
      type = "{{ syntax.type }}",
      class = "{{ syntax.class }}",
      variable = "{{ syntax.variable }}",
      parameter = "{{ syntax.parameter }}",
      property = "{{ syntax.property }}",
      identifier = "{{ syntax.identifier }}",
      operator = "{{ syntax.operator }}",
      regex = "{{ syntax.regex }}",
      builtin = "{{ syntax.builtin }}",
      builtin_variable = "{{ syntax.builtin_variable }}",
      punctuation = "{{ syntax.punctuation }}",
      special = "{{ syntax.special }}",
      exception = "{{ syntax.exception }}",
      ["return"] = "{{ syntax.return }}",
      import = "{{ syntax.import }}",
      decorator = "{{ syntax.decorator }}",
      tag = "{{ syntax.tag }}",
      attribute = "{{ syntax.attribute }}",
    },

    ui = {
      bg_statusline = "{{ surface.high }}",
      gutter = "{{ surface.highest }}",
    },
  },
}
