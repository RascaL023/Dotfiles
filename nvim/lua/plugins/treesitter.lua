return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    dependencies = { "OXY2DEV/markview.nvim" },
    event = { "BufReadPost", "BufNewFile" },

    config = function()
      require("nvim-treesitter.configs").setup({
        -- Setiap bahasa yang dipakai harus ada di sini. Tanpa parser terpasang,
        -- nvim-treesitter mematikan SEMUA modulnya untuk bahasa itu
        -- (highlight, indent, incremental_selection) karena `is_enabled()`
        -- digerbangi `parsers.has_parser(lang)`. Akibatnya <CR> (blok lalu
        -- meluas), indentasi, dan pewarnaan jatuh ke mesin lama (regex syntax
        -- + indent/<bahasa>.vim berbasis cindent) — terasa beda dari bahasa lain.
        ensure_installed = {
          "lua",
          "java",
          "javascript",
          "typescript",
          "html",
          "css",
          "json",
          "rust",
          "sql",
          "bash",
          "yaml",
          "go", "gomod", "gosum", "gowork",
          "svelte",
          "markdown",
          "markdown_inline",
          "yuck",
        },

        highlight = { enable = true },
        indent = {
          enable = true,
          -- HTML pakai HtmlIndent() bawaan Vim agar konsisten 2 spasi (treesitter buggy di html)
          disable = { "html" },
        },

        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<CR>",
            node_incremental = "<CR>",
            node_decremental = "<BS>",
          },
        },
      })
    end,
  }
