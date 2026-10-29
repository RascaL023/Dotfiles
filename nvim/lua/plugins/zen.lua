local colors = require("core.theme").colors

return {
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    opts = {
      window = {
        width = 0.7,
        height = 0.8,
        backdrop = 0,
        options = {
          signcolumn = "no",
          number = false,
          relativenumber = false,
          cursorcolumn = false,
          foldcolumn = "0",
          winhighlight = "Normal:ZenNormal",
        },
      },
      plugins = {
        options = {
          enabled = true,
          ruler = false,
          showcmd = false,
          laststatus = 0,
        },
        twilight = { enabled = true },
        gitsigns = { enabled = false },
      },
      on_open = function()
        vim.cmd("PencilSoft")
        vim.b.miniindentscope_disable = true
      end,
      on_close = function()
        vim.cmd("PencilOff")
        vim.b.miniindentscope_disable = false
      end,
    },
  },
  {
    "folke/twilight.nvim",
    opts = {
      dimming = {
        alpha = 0.2,
        -- Tanpa hex: twilight mengambil fg dari grup `Normal` saat dipakai,
        -- jadi tidak ada warna basi setelah tema di-reload.
        color = { "Normal" },
        term_bg = colors.bg_dark,
      },
      context = 20,
      treesitter = true,
    },
  },
  {
    "preservim/vim-pencil",
    cmd = { "Pencil", "PencilSoft", "PencilOff" },
  },
}
