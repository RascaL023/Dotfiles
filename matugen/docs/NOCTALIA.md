# Noctalia × matugen

> Indeks: [`README.md`](../README.md) · terkait: [`WM_FEEL_MATRIX.md`](WM_FEEL_MATRIX.md)

**Status: catatan fakta, bukan rancangan.** Isi diambil dari docs resmi Noctalia
v5 (configuration & template reference) dan dari file repo yang disebut. Saat
integrasi benar-benar dikerjakan, verifikasi ulang §4 — jangan menganggap
dokumen ini tetap benar untuk versi Noctalia yang terpasang.

---

## 1. Pembagian yang sudah berlaku

- **Warna punya satu pemilik per WM.** Saat Noctalia hidup, `palette.sh`
  melewati gtk/swaync/waybar (`if running noctalia; then skip …`). Kalau suatu
  saat template compositor Noctalia dipakai, include warna kita untuk WM itu
  harus dimatikan — jangan dua include aktif bersamaan. Keputusan pemilik
  diambil sekali saat integrasi, bukan dideteksi otomatis.
- **Rasa selalu milik flow kita.** Template Noctalia membawa token warna,
  `mode`, `image`, `closest_color`; tidak ada jalur terdokumentasi untuk skalar
  bebas (angka/string) maupun aritmetika. Karena itu `~/.myenv/feel/current/*`
  tetap dirender `matugen/json` dari profil kita. Noctalia hanya bisa mengatur
  rasa untuk dirinya sendiri lewat config TOML-nya.

## 2. Fakta Noctalia v5

- **Config:** semua `*.toml` di `~/.config/noctalia/` dibaca urut alfabet lalu
  digabung. `[include] files = [...]` menerima file atau direktori,
  `autoload = false` untuk memilih profil. File yang meng-include menang atas
  isi include.
- **State menang:** `~/.local/state/noctalia/settings.toml` (tulisan GUI)
  dimuat terakhir dan menimpa config tangan.
- **Hot reload:** kedua layer di-watch, perubahan berlaku ~150 ms setelah
  disimpan.
- **Validasi/inspeksi:** `noctalia config validate` (exit 1 hanya untuk error;
  warning key usang tidak menggagalkan) dan `noctalia config export` /
  `export full`.
- **Template:** context = 48 role Material + `hover`/`on_hover` + token
  terminal + `palettes.*`, plus `mode`, `image`, `closest_color`. Mendukung blok
  `<* *>`, filter warna/string, loop/conditional, `[config.custom_colors]`
  (menambah **role warna**, bukan variabel), hook, dan `output_path_dynamic`.
  Template tidak menulis ulang file yang isinya tidak berubah.
- **Template compositor bawaan:** Niri → `niri/noctalia.kdl` (plus include ke
  `niri/config.kdl`); Hyprland Lua → `hypr/noctalia.lua` (plus
  `dofile(...).apply_theme()`).
- **Batasnya:** karena context hanya token warna + tiga kunci di atas, rasa
  (radius, gap, blur, motion) tidak bisa dirender lewat template Noctalia.

## 3. Di repo ini

- `noctalia/` berisi `settings.json`, `plugins.json`, dan `palettes/*.json` —
  format JSON, sedangkan docs v5 memakai TOML. **Apakah v5 masih membaca JSON
  itu belum diverifikasi.**
- `niri/config.kdl` menjalankan `noctalia` saat startup; niri belum memakai tema
  matugen sama sekali.
- `matugen/script/palette.sh` sudah melewati gtk/swaync/waybar selama proses
  Noctalia hidup.

## 4. Wajib dicek saat integrasi

1. Format config: apakah `noctalia/*.json` masih dibaca v5, atau harus migrasi
   ke TOML?
2. Apakah `[include]` benar-benar ada di versi terpasang (bukan hanya di docs)?
3. Apakah `settings.toml` GUI menimpa file include kita — dan nilai mana yang
   menang saat keduanya menyentuh key yang sama?
4. Apakah template compositor Noctalia menambah include sendiri ke
   `niri/config.kdl` / `hypr/*.lua`; kalau ya, matikan include warna kita untuk
   WM itu.
5. Apakah template bawaan menulis ke `~/.config/kitty`, `foot`, `alacritty`,
   dsb. — bisa dobel dengan `include` kita ke `theme/current/`.
6. `noctalia config validate` harus exit 0 sebelum file hasil render dipakai.
