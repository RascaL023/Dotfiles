local M = {}

-- ============================================================================
-- GENERIC CONFIG
-- ============================================================================

M.icons = {
  lualine_left = "",
  lualine_right = "",
  cursor_head = "󰢘",
  cursor_body1 = "",
  cursor_body2 = "",
  cursor_body3 = "•",
  cursor_tail = "-",
}

function M.setup_base_ui()
  vim.opt.fillchars = { eob = " " }

  if vim.fn.has("nvim-0.11") == 1 then
    vim.o.winborder = "rounded"
  else
    vim.lsp.handlers["textDocument/hover"] =
      vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })

    vim.lsp.handlers["textDocument/signatureHelp"] =
      vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })
  end
end

function M.snacks_opts()
  return {
    notifier = {
      enabled = true,
      timeout = 3000,
      style = "fancy",
      width = { min = 36, max = 0.4 },
      margin = { top = 1, right = 1, bottom = 0 },
      padding = true,
      icons = {
        error = " ",
        warn = " ",
        info = " ",
        debug = " ",
        trace = " ",
      },
    },

    input = {
      enabled = true,
    },

    picker = {
      enabled = true,
      ui_select = true,
    },

    styles = {
      notification = {
        border = "rounded",
        backdrop = 60,
        wo = { winblend = 5 },
      },

      input = {
        border = "rounded",
        width = 52,
        row = 2,
      },
    },
  }
end

-- ============================================================================
-- LOAD GENERATED THEME
-- ============================================================================

local matugen_path = vim.fn.expand(
  "~/.myenv/theme/current/nvim/?.lua"
)

package.path = matugen_path .. ";" .. package.path

local ok, palette = pcall(require, "theme")

if not ok then
  M.fallback = true

  vim.notify(
    "[theme] Generated theme unavailable; using TokyoNight fallback.",
    vim.log.levels.WARN
  )

  -- Jangan jalankan kode palette-dependent setelah ini.
  function M.tokyonight_opts()
    return {
      style = "night",
      transparent = true,
    }
  end

  return M
end

-- ============================================================================
-- GENERATED THEME BERHASIL
-- ============================================================================

M.fallback = false
M.palettes = palette

--- Indeks 0-based seperti urutan warna ANSI
--- ansi(0) = black, ansi(15) = bright white.
local function ansi(i)
  return palette.colors[i + 1]
end

-- ============================================================================
-- MAPPING KE KUNCI TOKYONIGHT
-- ============================================================================

local BLUE0_ALPHA = 0.35
local BLUE7_ALPHA = 0.22

--- Bobot `text.muted` saat membuat warna "redup tapi terbaca" (`fg_faint`).
--- 0.0 = sepekat komentar, 1.0 = seterang teks muted.
local FAINT_ALPHA = 0.45

--- Campur `fg` ke `bg` dengan bobot `alpha` untuk `fg`.
--- alpha = 0 -> bg
--- alpha = 1 -> fg
--- @return string hex `#rrggbb`
local function blend(fg, bg, alpha)
  local function channels(hex)
    hex = hex:gsub("#", "")

    return tonumber(hex:sub(1, 2), 16),
      tonumber(hex:sub(3, 4), 16),
      tonumber(hex:sub(5, 6), 16)
  end

  local fr, fgc, fb = channels(fg)
  local br, bgc, bb = channels(bg)

  local function mix(f, b)
    return math.floor(
      math.min(
        math.max(0, alpha * f + (1 - alpha) * b),
        255
      ) + 0.5
    )
  end

  return string.format(
    "#%02x%02x%02x",
    mix(fr, br),
    mix(fgc, bgc),
    mix(fb, bb)
  )
end

--- Role container (selection/search) dari palet.
--- Palet dari pipeline wallpaper versi lama dan palet legacy belum punya
--- `extra.container`, jadi di situ dipakai perilaku lama: accent untuk
--- seleksi, background untuk teks di atasnya.
--- @param d table palet tergenerate
--- @return table
local function container_roles(d)
  local accent = d.extra.accent

  return d.extra.container or {
    primary = accent.primary,
    on_primary = d.background,
    secondary = accent.secondary,
    on_secondary = d.background,
    tertiary = accent.tertiary or accent.secondary,
    on_tertiary = d.background,
  }
end

local function build_colors(d)
  local layer = d.extra.layer
  local text = d.extra.text
  local border = d.extra.border
  local status = d.extra.status
  local fg = d.extra.fg
  local syntax = d.extra.syntax
  local accent = d.extra.accent
  local containers = container_roles(d)
  local ui = d.extra.ui

  local base = layer.base

  local blue = syntax["function"]
  local blue0 = blend(blue, base, BLUE0_ALPHA)
  local blue7 = blend(blue, base, BLUE7_ALPHA)

  local green = syntax.string
  local teal = ansi(14)
  local yellow = syntax.constant
  local orange = syntax.import
  local magenta = syntax.statement
  local purple = syntax.keyword
  local red = status.critical
  local dark5 = fg.dim_muted

  -- Warna teks "redup tapi terbaca".
  -- Dipakai untuk grup yang TokyoNight warnai dengan `terminal_black` sebagai
  -- *foreground*: `terminal_black` kita adalah LATAR chip kode inline (gelap,
  -- ~1.1:1 terhadap bg), jadi teks di atasnya menyatu dengan latar. Yang
  -- kena: `DiagnosticUnnecessary` (kode mati/tak terpakai dari LSP, mis.
  -- `dead_code` Rust) dan ghost text saran (cmp/Copilot/Blink).
  local fg_faint = blend(text.muted, syntax.comment, FAINT_ALPHA)

  return {
    -- Palet dasar (peran ditentukan oleh pemakaian di source TokyoNight).
    bg = layer.base,
    bg_dark = layer.mantle,
    bg_dark1 = layer.crust,
    bg_highlight = layer.surface_raised,
    fg = d.foreground,
    fg_dark = text.muted,
    fg_gutter = ui.gutter,

    comment = syntax.comment,

    dark3 = fg.dim,
    dark5 = dark5,

    -- Latar halus (chip inline code `...`, backdrop).
    -- Di TokyoNight `terminal_black` adalah permukaan GELAP; memakai `border`
    -- (abu terang) membuat teks di atas chip nyaris tak terbaca.
    -- CATATAN: kunci ini hanya boleh dipakai sebagai *latar*. TokyoNight juga
    -- memakainya sebagai fg (ghost text, `DiagnosticUnnecessary`) — pemakaian
    -- itu ditimpa di `on_highlights` memakai `fg_faint`, karena nilai ini
    -- terlalu dekat ke bg untuk dibaca sebagai teks.
    terminal_black = blend(accent.primary, layer.crust, 0.12),

    red = red,
    red1 = status.error,

    green = green,
    green1 = syntax.property,
    green2 = status.success,

    yellow = yellow,
    orange = orange,

    blue = blue,
    blue1 = syntax.type,
    blue2 = status.info,
    blue5 = syntax.operator,
    blue6 = syntax.regex,

    cyan = ansi(6),
    teal = teal,

    purple = purple,
    magenta = magenta,
    magenta2 = syntax.special,

    blue0 = blue0,
    blue7 = blue7,

    git = {
      add = status.success,
      change = accent.primary,
      delete = status.error,
      ignore = fg.dim,
    },

    -- Kunci turunan.
    -- Wajib di-set eksplisit karena TokyoNight menghitung beberapa nilai
    -- sebelum `on_colors` dipanggil.
    black = layer.crust,
    border = border.medium,
    border_highlight = border.active,

    bg_popup = layer.mantle,
    bg_float = layer.mantle,
    bg_sidebar = layer.mantle,
    bg_statusline = ui.bg_statusline,

    bg_visual = containers.primary,
    bg_search = containers.secondary,

    fg_sidebar = text.muted,
    fg_float = d.foreground,
    fg_faint = fg_faint,

    error = status.error,
    warning = status.warning,
    info = status.info,
    hint = accent.tertiary or teal,
    todo = blue,

    diff = {
      add = blend(status.success, base, 0.25),
      delete = blend(status.error, base, 0.25),
      change = blend(blue, base, 0.15),
      text = blue7,
    },

    rainbow = {
      blue,
      yellow,
      green,
      teal,
      magenta,
      purple,
      orange,
      red,
    },

    terminal = {
      black = ansi(0),
      black_bright = ansi(8),

      red = ansi(1),
      red_bright = ansi(9),

      green = ansi(2),
      green_bright = ansi(10),

      yellow = ansi(3),
      yellow_bright = ansi(11),

      blue = ansi(4),
      blue_bright = ansi(12),

      magenta = ansi(5),
      magenta_bright = ansi(13),

      cyan = ansi(6),
      cyan_bright = ansi(14),

      white = ansi(7),
      white_bright = ansi(15),
    },

    -- Kunci custom.
    button = blue,
    footer = syntax.comment,

    smooth_body3 = teal,
    smooth_tail = dark5,

    accent = accent.primary,
    accent2 = accent.secondary,

    cursor = d.cursor,
  }
end

M.colors = build_colors(palette)

--- Token semantik -> hex.
M.syntax = palette.extra.syntax

-- ============================================================================
-- OVERRIDE TOKYONIGHT
-- ============================================================================

local warned_missing_keys = false

--- Ubah hanya `fg` bila grup sudah bertabel.
--- Kalau string/link/nil, ganti menjadi `{ fg = color }`.
local function set_fg(hl, group, color)
  local current = hl[group]

  if type(current) == "table" then
    current.fg = color
  else
    hl[group] = { fg = color }
  end
end

local function apply_syntax_highlights(hl)
  local s = palette.extra.syntax

  local map = {
    { s.constant, "Constant", "@constant", "@constant.builtin" },
    { s.number, "Number", "Float", "@number", "@number.float" },
    { s.boolean, "Boolean", "@boolean" },
    { s.string, "String", "Character", "@string" },
    { s.special, "@string.escape" },
    { s.regex, "@string.regexp" },
    { s.identifier, "Identifier" },
    { s.variable, "@variable" },
    { s.builtin_variable, "@variable.builtin" },
    { s.parameter, "@variable.parameter" },
    { s.property, "@variable.member", "@property" },
    { s["function"], "Function", "@function", "@function.call" },
    { s.method, "@function.method", "@function.method.call" },
    { s.builtin, "@function.builtin" },
    { s.statement, "Statement", "Conditional", "Repeat", "Label" },
    { s.keyword, "Keyword", "@keyword", "@keyword.function" },
    { s["return"], "@keyword.return" },
    { s.exception, "@keyword.exception", "Exception" },

    {
      s.import,
      "PreProc",
      "Include",
      "Define",
      "Macro",
      "@keyword.import",
    },
    {
      s.operator,
      "@keyword.operator",
      "Operator",
      "@operator",
    },
    {
      s.type,
      "Type",
      "StorageClass",
      "Structure",
      "@type",
      "@type.builtin",
    },

    { s.class, "@constructor" },
    { s.special, "Special" },

    {
      s.punctuation,
      "Delimiter",
      "@punctuation.delimiter",
      "@punctuation.bracket",
      "@punctuation.special",
      "@tag.delimiter",
    },

    {
      s.decorator,
      "@attribute",
      "@attribute.builtin",
    },

    { s.tag, "@tag" },
    { s.attribute, "@tag.attribute" },
  }

  for _, entry in ipairs(map) do
    for i = 2, #entry do
      set_fg(hl, entry[i], entry[1])
    end
  end
end

--- Opsi lengkap untuk `require("tokyonight").setup(...)`.
function M.tokyonight_opts()
  return {
    style = "night",
    transparent = true,

    -- Cache TokyoNight tidak memuat Util.bg/Util.fg dengan benar untuk
    -- palette custom kita. Nonaktifkan agar selalu rebuild.
    cache = false,

    on_colors = function(c)
      for key, value in pairs(M.colors) do
        c[key] = type(value) == "table"
          and vim.deepcopy(value)
          or value
      end

      -- TokyoNight menangkap Util.bg/Util.fg sebelum on_colors.
      -- Arahkan ulang agar blend menggunakan palette kita.
      local Util = require("tokyonight.util")

      Util.bg = c.bg
      Util.fg = c.fg

      -- Guard terhadap warna TokyoNight yang masih bocor.
      if not warned_missing_keys then
        local missing = {}

        for key in pairs(require("tokyonight.colors.storm")) do
          if M.colors[key] == nil then
            missing[#missing + 1] = key
          end
        end

        if #missing > 0 then
          table.sort(missing)

          warned_missing_keys = true

          vim.notify(
            "[theme] kunci palet tokyonight tidak ditimpa: "
              .. table.concat(missing, ", "),
            vim.log.levels.WARN
          )
        end
      end
    end,

    on_highlights = function(hl, c)
      -- ================================================================
      -- Selection / search memakai role container (Material)
      -- ================================================================

      local acc = palette.extra.accent
      local box = container_roles(palette)
      -- Palet yang belum punya accent.tertiary memakai secondary + background.
      local tertiary = acc.tertiary or acc.secondary
      local on_tertiary = acc.on_tertiary or palette.background

      hl.Visual = { bg = box.primary, fg = box.on_primary }
      hl.VisualNOS = { bg = box.primary, fg = box.on_primary }

      hl.PmenuSel = { bg = box.primary, fg = box.on_primary }

      hl.Search = { bg = box.secondary, fg = box.on_secondary }
      hl.CurSearch = { bg = tertiary, fg = on_tertiary }
      hl.IncSearch = { bg = tertiary, fg = on_tertiary }

      hl.MatchParen = { bg = box.tertiary, fg = box.on_tertiary, bold = true }

      -- ================================================================
      -- Teks redup (jangan pakai `terminal_black` sebagai fg)
      -- ================================================================

      -- TokyoNight memakai `terminal_black` sebagai fg di grup-grup ini,
      -- padahal nilai kita untuk kunci itu adalah LATAR chip kode inline:
      -- gelap dan hampir sama dengan bg, jadi teksnya tidak terbaca.
      --
      -- Yang paling terasa: `DiagnosticUnnecessary`. Nvim memakai grup itu
      -- untuk meratakan warna teks rentang diagnostik LSP bertag
      -- `unnecessary` — di Rust = kode mati / belum dipanggil, mis.
      -- "function `foo` is never used". Tanpa override ini, nama fungsi,
      -- struct, dan variabel yang belum dipakai tampil nyaris sewarna latar.
      for _, group in ipairs({
        "DiagnosticUnnecessary",
        "ComplHint",
        "CmpGhostText",
        "BlinkCmpGhostText",
        "CopilotSuggestion",
        "CopilotAnnotation",
        "CodeiumSuggestion",
        "SupermavenSuggestion",
      }) do
        set_fg(hl, group, c.fg_faint)
      end

      -- Teks di dalam backtick (kode inline markdown). TokyoNight memberinya
      -- aksen biru di atas latar chip gelap; dua warna itu berdekatan hue dan
      -- kontrasnya cuma ~5:1, jadi sulit dibaca. Pakai warna teks utama.
      hl["@markup.raw.markdown_inline"] = {
        bg = c.terminal_black,
        fg = c.fg,
      }

      -- ================================================================
      -- Transparansi + plugin yang sudah ada
      -- ================================================================

      hl.CmpBorder = {
        fg = c.border,
      }

      hl.CmpDoc = {
        bg = "none",
        fg = c.fg,
      }

      hl.CmpPmenu = {
        bg = "none",
        fg = c.fg,
      }

      -- Transparansi: menulis `{ bg = "none" }` saja akan MENGHAPUS fg/bold
      -- bawaan TokyoNight, karena nvim_set_hl mengganti seluruh definisi group.
      -- Jadi: group yang latarnya sudah tembus dari `transparent = true` cukup
      -- dibiarkan, dan yang perlu dikosongkan manual harus menyertakan fg-nya.
      hl.NvimTreeNormal = {
        fg = c.fg_sidebar,
        bg = "none",
      }

      hl.NvimTreeNormalNC = {
        fg = c.fg_sidebar,
        bg = "none",
      }

      hl.NvimTreeEndOfBuffer = {
        bg = "none",
      }

      hl.NormalFloat = {
        fg = c.fg_float,
        bg = "none",
      }

      hl.FloatBorder = {
        fg = c.border,
      }

      -- ================================================================
      -- Snacks
      -- ================================================================

      hl.SnacksInputBorder = {
        fg = c.border,
      }

      hl.SnacksInputTitle = {
        fg = c.magenta,
      }

      hl.SnacksInputIcon = {
        fg = c.purple,
      }

      hl.SnacksInputNormal = {
        bg = "none",
        fg = c.fg,
      }

      local levels = {
        "Error",
        "Warn",
        "Info",
        "Debug",
        "Trace",
      }

      for _, lvl in ipairs(levels) do
        hl["SnacksNotifierBorder" .. lvl] = {
          fg = c.border,
        }

        hl["SnacksNotifierTitle" .. lvl] = {
          fg = c.purple,
        }

        hl["SnacksNotifierIcon" .. lvl] = {
          fg = c.blue,
        }

        hl["SnacksNotifierFooter" .. lvl] = {
          fg = c.border,
        }

        hl["SnacksNotifier" .. lvl] = {
          fg = c.fg,
        }
      end

      -- ================================================================
      -- Semantic syntax mapping
      -- ================================================================

      apply_syntax_highlights(hl)
    end,
  }
end

-- ============================================================================
-- HIGHLIGHT PLUGIN NON-TOKYONIGHT
-- ============================================================================

-- Markview palette groups derive from Normal.bg.
-- Karena theme transparan (Normal.bg = "none"), beri tahu background tema
-- melalui global.
vim.g.markview_dark_bg = M.colors.bg
vim.g.markview_light_bg = M.colors.bg

function M.apply_plugin_highlights()
  local c = M.colors
  local set = vim.api.nvim_set_hl

  -- Alpha
  set(0, "AlphaHeader", {
    fg = c.magenta,
  })

  set(0, "AlphaBorder", {
    fg = c.border,
  })

  set(0, "AlphaButtons", {
    fg = c.button,
  })

  set(0, "AlphaFooter", {
    fg = c.footer,
  })

  -- Telescope
  local function set_fg_keep_bg(name, fg)
    local current = vim.api.nvim_get_hl(0, {
      name = name,
    })

    set(0, name, {
      fg = fg,
      bg = current.bg,
    })
  end

  set_fg_keep_bg("TelescopeBorder", c.border)
  set_fg_keep_bg("TelescopePromptBorder", c.magenta)
  set_fg_keep_bg("TelescopePromptTitle", c.magenta)
  set_fg_keep_bg("TelescopeResultsTitle", c.purple)
  set_fg_keep_bg("TelescopePreviewTitle", c.magenta)

  -- SmoothCursor
  set(0, "SmoothCursor", {
    fg = c.accent2,
  })

  set(0, "SmoothCursorBody1", {
    fg = c.purple,
  })

  set(0, "SmoothCursorBody2", {
    fg = c.blue,
  })

  set(0, "SmoothCursorBody3", {
    fg = c.smooth_body3,
  })

  set(0, "SmoothCursorTail", {
    fg = c.smooth_tail,
  })

  -- mini.indentscope
  set(0, "MiniIndentscopeSymbol", {
    fg = c.purple,
  })

  set(0, "MiniIndentscopeSymbolOff", {
    fg = c.magenta,
  })

  -- markview inline code (teks di dalam backtick)
  set(0, "MarkviewInlineCode", {
    bg = c.terminal_black,
    fg = c.fg,
  })

  -- zen-mode
  set(0, "ZenNormal", {
    fg = c.fg,
    bg = "none",
  })

  -- cheatsheet badges
  set(0, "CheatModeN", {
    fg = c.blue,
    bold = true,
    default = true,
  })

  set(0, "CheatModeV", {
    fg = c.green,
    bold = true,
    default = true,
  })

  set(0, "CheatModeX", {
    fg = c.teal,
    bold = true,
    default = true,
  })

  set(0, "CheatModeI", {
    fg = c.yellow,
    bold = true,
    default = true,
  })

  set(0, "CheatModeO", {
    fg = c.red,
    bold = true,
    default = true,
  })

  set(0, "CheatModeT", {
    fg = c.accent2,
    bold = true,
    default = true,
  })

  set(0, "CheatModeS", {
    fg = c.purple,
    bold = true,
    default = true,
  })

  -- Grup bawaan Neovim yang tidak didefinisikan TokyoNight
  set(0, "DiagnosticOk", {
    fg = c.green2,
  })

  set(0, "DiagnosticUnderlineOk", {
    sp = c.green2,
    underline = true,
  })

  set(0, "DiagnosticDeprecated", {
    sp = c.dark3,
    strikethrough = true,
  })

  set(0, "Added", {
    fg = c.green2,
  })

  set(0, "Changed", {
    fg = c.blue2,
  })

  set(0, "Removed", {
    fg = c.red1,
  })

  set(0, "FloatShadow", {
    bg = c.bg_dark1,
  })

  set(0, "FloatShadowThrough", {
    bg = c.bg_dark1,
  })

  set(0, "NvimInternalError", {
    fg = c.bg,
    bg = c.red,
  })

  set(0, "RedrawDebugClear", {
    fg = c.bg,
    bg = c.yellow,
  })

  set(0, "RedrawDebugComposed", {
    fg = c.bg,
    bg = c.green2,
  })

  set(0, "RedrawDebugRecompose", {
    fg = c.bg,
    bg = c.red,
  })
end

-- :colorscheme menghapus highlight group, jadi pasang ulang.
-- Autocmd didaftarkan saat theme.lua pertama di-require.
M.apply_plugin_highlights()

local theme_augroup = vim.api.nvim_create_augroup(
  "Theme",
  {
    clear = true,
  }
)

vim.api.nvim_create_autocmd("ColorScheme", {
  group = theme_augroup,

  callback = function()
    M.apply_plugin_highlights()
  end,
})

-- ============================================================================
-- HOT RELOAD
-- ============================================================================

--- Salin isi `src` ke `dst` secara in-place (rekursif).
--- In-place penting: `palette` (upvalue), `M.palettes`, `M.syntax` dan
--- `M.colors` sudah di-capture modul lain (mis. zen.lua), jadi identitas
--- tabelnya tidak boleh berubah.
local function sync_in_place(dst, src)
  for k in pairs(dst) do
    if src[k] == nil then
      dst[k] = nil
    end
  end

  for k, v in pairs(src) do
    if type(v) == "table" then
      if type(dst[k]) ~= "table" then
        dst[k] = {}
      end
      sync_in_place(dst[k], v)
    else
      dst[k] = v
    end
  end
end

--- Baca ulang theme.lua hasil matugen lalu terapkan ke nvim yang sedang
--- berjalan. Aman dipanggil kapan saja: bila file rusak/setengah tertulis,
--- palet lama dipertahankan dan fungsi mengembalikan false.
function M.reload()
  package.loaded["theme"] = nil
  local ok_load, fresh = pcall(require, "theme")

  if not ok_load or type(fresh) ~= "table" or not fresh.extra then
    package.loaded["theme"] = palette
    vim.notify(
      "[theme] reload dibatalkan, palet lama dipakai: " .. tostring(fresh),
      vim.log.levels.WARN
    )
    return false
  end

  sync_in_place(palette, fresh)
  package.loaded["theme"] = palette

  sync_in_place(M.colors, build_colors(palette))
  vim.g.markview_dark_bg = M.colors.bg
  vim.g.markview_light_bg = M.colors.bg

  require("tokyonight").setup(M.tokyonight_opts())
  -- Memicu autocmd ColorScheme: apply_plugin_highlights() dan
  -- re-setup lualine berjalan otomatis.
  vim.cmd.colorscheme("tokyonight")

  -- smear-cursor menerima warna sebagai string hex saat setup(), bukan
  -- highlight group, jadi harus di-set ulang. Hanya bila sudah termuat
  -- (jangan memicu lazy-load dari sini).
  local smear = package.loaded["smear_cursor"]
  if smear then
    smear.cursor_color = M.colors.magenta
    smear.transparent_bg_fallback_color = M.colors.bg_highlight
  end

  return true
end

return M
