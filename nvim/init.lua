require("core.options")
require("core.bindings")
require("core.theme").setup_base_ui()
require("core.lazy")
require("core.livereload")
require("core.theme_watch").start()

vim.g.VM_maps = {
  ["Find Under"]         = "<C-d>",
  ["Find Subword Under"] = "<C-d>",
}

