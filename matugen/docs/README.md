# Dokumentasi Theming (`matugen/docs`)

Indeks dokumen seputar `matugen/`. Semua berkas di sini **diverifikasi terhadap
isi repo** — kalau ada baris yang tidak cocok lagi dengan kode, itu bug
dokumentasi, bukan sekadar catatan usang.

| Dokumen | Bahasa | Isinya |
|---|---|---|
| [`MATUGEN_SKILLS.md`](MATUGEN_SKILLS.md) | EN | Cara menulis, mendaftarkan, menguji, dan me-reload template matugen. Berisi fakta engine yang sudah diverifikasi + resep per aplikasi. |
| [`CHEATSHEETS.md`](CHEATSHEETS.md) | ID | Kosakata *role* Material You (alur wallpaper) → pekerjaan UI mana. |
| [`VOCABULARY.md`](VOCABULARY.md) | ID | Contoh keluaran `matugen --show-colors` + cara membacanya. |
| [`PROGRESS.md`](PROGRESS.md) | EN | Cakupan template per tool, per alur. |
| [`FEEL.md`](FEEL.md) | ID | Rancangan pemisahan warna vs rasa (feel): token semantik, pemetaan Hyprland/niri, konsumen non-shell, dan rencana Noctalia. **Status: rancangan, belum diterapkan.** |
| [`WM_FEEL_MATRIX.md`](WM_FEEL_MATRIX.md) | ID | Matriks fitur feel Hyprland 0.56 vs niri 26.04: mana yang sama, beda semantik, hanya di satu WM, dan mana yang harus di app. |
| [`THEME_ENGINE.md`](THEME_ENGINE.md) | ID | Strategi reload per sesi (Hyprland/niri), kontrak `palette.json`/`feel.json`/manifest, dan abstraksi engine matugen vs Noctalia. |
| [`NVIM_MAPPING.md`](NVIM_MAPPING.md) | ID | Key palet → highlight group Neovim. |
| [`../templates/palette/kanagawa-dragon-lotus/blueprint/README.md`](../templates/palette/kanagawa-dragon-lotus/blueprint/README.md) | ID | Referensi setiap key JSON blueprint (alur palet tetap). |

---

## Peta cepat: alur mana yang sedang dibahas?

Repo ini punya **dua alur theming yang terpisah**. Pastikan dokumen yang dibaca
memang untuk alur itu:

| | A — wallpaper | B — palet tetap |
|---|---|---|
| Config | `matugen/config.toml` | `matugen/templates/palette/kanagawa-dragon-lotus/config.toml` |
| Template | `matugen/templates/palette/wallpaper-based/*` | `matugen/templates/palette/kanagawa-dragon-lotus/template/*` |
| Sumber warna | gambar | JSON tulis tangan di `blueprint/` |
| Perintah | `matugen image …` | `matugen json …` |
| Kosakata template | `{{ colors.<role>.<scheme>.<format> }}` | `{{ accent.primary }}`, `{{ syntax.keyword }}`, … |
| Dokumen rujukan | `CHEATSHEETS.md`, `VOCABULARY.md`, bagian §1–11 `MATUGEN_SKILLS.md` | `blueprint/README.md`, `NVIM_MAPPING.md` |
| Output | `~/.myenv/theme/generated/wallpaper-based/<tool>/…` | `~/.myenv/theme/generated/<theme>/<tool>/…` |

Semua template **warna** tinggal di `matugen/templates/palette/<sumber>/` — satu
folder per sumber palet (`wallpaper-based/`, `kanagawa-dragon-lotus/`). Template
**rasa** nantinya di `matugen/templates/feel/`; folder itu belum ada di repo
(lihat [`FEEL.md`](FEEL.md) §7).

Aturan singkat: **jangan pernah mencampur keduanya dalam satu config matugen.**
Template alur B akan gagal di `matugen image` (tidak ada `accent.*`), dan
`colors.*` tidak ada di `matugen json`.

Untuk gambaran menyeluruh repo (sync config, tabel tool, setup), lihat
[`../../README.md`](../../README.md) dan [`../../AGENTS.md`](../../AGENTS.md).
