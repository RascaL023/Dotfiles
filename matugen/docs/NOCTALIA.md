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
  bebas (angka/string) maupun aritmetika. Karena itu `~/.myenv/theme/feel/current/*`
  tetap dirender `matugen/json` dari profil kita. Noctalia hanya bisa mengatur
  rasa untuk dirinya sendiri lewat config TOML-nya.

## 2. Fakta Noctalia v5

- **Config:** semua `*.toml` di `~/.config/noctalia/` dibaca urut alfabet lalu
  digabung. `[include] files = [...]` menerima file atau direktori,
  `autoload = false` untuk memilih profil. File yang meng-include menang atas
  isi include.
- **Load order:** `*.toml` di `~/.config/noctalia/` dimuat dulu, lalu
  `~/.local/state/noctalia/settings.toml` (tulisan GUI) yang menang saat key-nya
  sama. Di mesin ini layer itu sengaja dikosongkan (`config_version = 14` saja),
  jadi `config.toml` yang menentukan.
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

- `noctalia/config.toml` adalah **satu-satunya sumber kebenaran**: isinya hasil
  `noctalia config export` dari state lama, dan state itu sudah dikosongkan
  (`config_version = 14`) supaya tidak ada key yang menimpa. Backup state lama:
  `~/.local/state/noctalia/settings.toml.bak-20261111` (di luar repo).
- JSON v4 (`settings.json`, `plugins.json`) dan direktori kosong sisa v4 sudah
  dibuang — v5 hanya membaca TOML dan tidak memigrasikan JSON lama.
- Kalau suatu saat ada yang diubah lewat GUI Settings, override akan muncul lagi
  di `settings.toml` dan menang; ekspor ulang ke `config.toml` lalu kosongkan
  state lagi kalau ingin tetap deklaratif.
- `noctalia/palettes/*.json` tetap format 1 (`dark`/`light` + `mPrimary`…); v5
  masih menerimanya lewat `[theme] source = "custom"` +
  `custom_palette = "<nama file tanpa .json>"`.
- `niri/config.kdl` menjalankan `noctalia` saat startup; niri belum memakai tema
  matugen sama sekali.
- `matugen/script/palette.sh` sudah melewati gtk/swaync/waybar selama proses
  Noctalia hidup.

## 4. Wajib dicek saat integrasi

1. Apakah `[include]` benar-benar ada di versi terpasang (bukan hanya di docs)?
2. Apakah template compositor Noctalia menambah include sendiri ke
   `niri/config.kdl` / `hypr/*.lua`; kalau ya, matikan include warna kita untuk
   WM itu.
3. Apakah template bawaan menulis ke `~/.config/kitty`, `foot`, `alacritty`,
   dsb. — bisa dobel dengan `include` kita ke `theme/palette/current/`.
4. `noctalia config validate` harus exit 0 sebelum file hasil render dipakai.
