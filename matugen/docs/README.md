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
| [`NVIM_MAPPING.md`](NVIM_MAPPING.md) | ID | Key palet → highlight group Neovim. |
| [`../templates/kanagawa-dragon-lotus/blueprint/README.md`](../templates/kanagawa-dragon-lotus/blueprint/README.md) | ID | Referensi setiap key JSON blueprint (alur palet tetap). |

---

## Peta cepat: alur mana yang sedang dibahas?

Repo ini punya **dua alur theming yang terpisah**. Pastikan dokumen yang dibaca
memang untuk alur itu:

| | A — wallpaper | B — palet tetap |
|---|---|---|
| Config | `matugen/config.toml` | `matugen/templates/kanagawa-dragon-lotus/config.toml` |
| Sumber warna | gambar | JSON tulis tangan di `blueprint/` |
| Perintah | `matugen image …` | `matugen json …` |
| Kosakata template | `{{ colors.<role>.<scheme>.<format> }}` | `{{ accent.primary }}`, `{{ syntax.keyword }}`, … |
| Dokumen rujukan | `CHEATSHEETS.md`, `VOCABULARY.md`, bagian §1–11 `MATUGEN_SKILLS.md` | `blueprint/README.md`, `NVIM_MAPPING.md` |
| Output | `~/.myenv/theme/generated/live.bak/<tool>/…` | `~/.myenv/theme/generated/<theme>/<tool>/…` |

Aturan singkat: **jangan pernah mencampur keduanya dalam satu config matugen.**
Template alur B akan gagal di `matugen image` (tidak ada `accent.*`), dan
`colors.*` tidak ada di `matugen json`.

Untuk gambaran menyeluruh repo (sync config, tabel tool, setup), lihat
[`../../README.md`](../../README.md) dan [`../../AGENTS.md`](../../AGENTS.md).
