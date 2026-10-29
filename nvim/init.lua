require("core.options")
require("core.bindings")
require("core.theme").setup_base_ui()
-- Dipasang sebelum lazy: bila ada spec plugin yang error, watcher tema tetap
-- hidup sehingga warna bisa pulih tanpa restart.
require("core.theme_watch").start()
require("core.lazy")
require("core.livereload")

vim.g.VM_maps = {
  ["Find Under"]         = "<C-d>",
  ["Find Subword Under"] = "<C-d>",
}
