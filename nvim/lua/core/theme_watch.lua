-- Hot reload tema.
--
-- Dua hal dipantau:
--
--   1. ROOT (~/.myenv/theme): untuk mendeteksi symlink `current` dipindah.
--   2. "Inner": folder nyata tempat theme.lua berada SAAT INI.
--
-- Kenapa tidak cukup memantau ~/.myenv/theme/current/nvim saja?
-- inotify menempel pada inode folder yang sudah di-resolve, bukan pada
-- string path. Begitu `current` dipindah ke tema lain, watcher masih
-- menempel di folder lama yang tidak pernah ditulis lagi, dan penulisan
-- matugen ke folder tema baru tidak terdengar sama sekali.
-- Solusinya: pantau symlink-nya dari folder induk, lalu pasang ulang
-- watcher "inner" ke tujuan baru setiap kali ada perubahan.
local uv = vim.uv or vim.loop

local M = {}

local ROOT = vim.fn.expand("~/.myenv/theme")
local LINK = "current"
local SUBDIR = "nvim"
local FILE = "theme.lua"
local DEBOUNCE_MS = 300

local root_handle, inner_handle, timer
local inner_dir, inner_name

local function close(h)
  if h and not h:is_closing() then
    h:close()
  end
end

local debounced

-- Tentukan apa yang harus dipantau sekarang.
--   current/nvim ada      -> pantau folder itu untuk theme.lua
--   hanya current ada     -> pantau current untuk munculnya "nvim"
--                            (tema yang baru pertama kali dirender)
--   tidak ada             -> tidak ada yang bisa dipantau
local function resolve_inner()
  local nvim_dir = uv.fs_realpath(ROOT .. "/" .. LINK .. "/" .. SUBDIR)
  if nvim_dir then
    return nvim_dir, FILE
  end

  local link_dir = uv.fs_realpath(ROOT .. "/" .. LINK)
  if link_dir then
    return link_dir, SUBDIR
  end

  return nil, nil
end

local function arm_inner()
  local dir, name = resolve_inner()

  if dir == inner_dir and name == inner_name then
    return
  end

  close(inner_handle)
  inner_handle = nil
  inner_dir, inner_name = dir, name

  if not dir then
    return
  end

  inner_handle = uv.new_fs_event()
  inner_handle:start(dir, {}, function(err, fname)
    if err or (fname and fname ~= inner_name) then
      return
    end
    debounced()
  end)
end

-- Jalan di main loop setelah event berhenti DEBOUNCE_MS.
-- Urutan penting: pasang watcher DULU, baru reload. Tulisan yang masuk
-- sebelum watcher terpasang ikut terbaca oleh reload; tulisan sesudahnya
-- memicu event baru.
local function fire()
  arm_inner()

  local real_nvim = uv.fs_realpath(ROOT .. "/" .. LINK .. "/" .. SUBDIR)
  if not (real_nvim and uv.fs_stat(real_nvim .. "/" .. FILE)) then
    return -- theme.lua belum ada (mis. matugen belum selesai menulis)
  end

  local theme = require("core.theme")
  if theme.reload then
    theme.reload()
  end
end

debounced = function()
  timer:stop()
  timer:start(DEBOUNCE_MS, 0, vim.schedule_wrap(fire))
end

function M.start()
  if root_handle then
    return
  end

  if not uv.fs_stat(ROOT) then
    return
  end

  timer = uv.new_timer()

  root_handle = uv.new_fs_event()
  root_handle:start(ROOT, {}, function(err, fname)
    if err or (fname and fname ~= LINK) then
      return
    end
    debounced()
  end)

  arm_inner()

  vim.api.nvim_create_autocmd("VimLeavePre", {
    once = true,
    callback = function()
      close(root_handle)
      close(inner_handle)
      close(timer)
    end,
  })
end

return M
