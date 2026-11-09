return {
  "mistweaverco/kulala.nvim",
  version = "v5.3.4",
  ft = { "http", "rest" },
  cmd = { "Kulala" },
  config = function()
    require("kulala").setup({
      env_file = ".env",
      split_direction = "vertical",
      formatters = {
        json = { "jq" },
      },
    })

    vim.keymap.set("n", "<leader>kr", function()
      require("kulala").run()
    end, { desc = "Run Kulala API Request" })
  end,
}
