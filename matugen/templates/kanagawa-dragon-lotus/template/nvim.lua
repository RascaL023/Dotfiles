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
      on_accent = "{{ accent.on_primary }}",
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
      dim = "{{ text.dim }}",
      dim_muted = "{{ text.dim_muted }}",
      disabled = "{{ text.disabled }}",
    },

    bg = {
      conflict = "{{ bg.conflict }}",
      disk_usage = "{{ bg.disk_usage }}",
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
      bg_statusline = "{{ ui.bg_statusline }}",
      gutter = "{{ ui.gutter }}",
    },
  },
}
