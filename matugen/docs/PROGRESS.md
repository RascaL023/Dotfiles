# Template Coverage

> Index: [`README.md`](README.md) · flows are described in
> [`README.md`](README.md) and [`../../AGENTS.md`](../../AGENTS.md).
>
> [x] = template exists in this repo · [ ] = consumer reads a generated file,
> but the file is produced elsewhere (or the tool is not themed yet).

Last verified against the repo: 2026-11-11.

> Template layout: every color template lives under `core/palette/<source>/`,
> every feel template under `core/feel/template/<consumer>`, with feel
> profiles in `core/feel/blueprint/<profile>.json`. Neither color config has
> a `post_hook`: `matugen/palette.sh <wallpaper|blueprint.json>` renders into
> `~/.myenv/theme/generated/<palette>`, flips `theme/current` once the result
> validates, then reloads the running desktop. Feel has its own entry point,
> `matugen/feel.sh <profile>`.

---

## Flow A — wallpaper (`core/palette/wallpaper-based/template/*`)

Config: `matugen/core/palette/wallpaper-based/config.toml` · output root:
`~/.myenv/theme/generated/wallpaper-based/<tool>/…`

| Tool | Template | Output | Consumer reads it |
|---|---|---|---|
| [x] Kitty | `kitty.conf` | `kitty/theme.conf` | `kitty/kitty.conf` (`include`) |
| [x] Alacritty | `alacritty.toml` | `alacritty/theme.toml` | `alacritty/alacritty.toml` (`import`) |
| [x] Neovim | `nvim.lua` | `nvim/theme.lua` ¹ | `nvim/lua/core/theme.lua` (`require`) |
| [x] Lazygit | `lazygit.yml` | `lazygit/config.yml` | —² |
| [x] Herdr | `herdr.toml` | `herdr/config.toml` | —² |
| [x] GTK / CSS | `source.css` | `css/theme.css` (reload: `matugen/palette.sh`) | `waybar/style.css`, `wlogout/style.css`, `swaync/style.css` |
| [x] SCSS | `source.scss` | `scss/_theme.scss` | `eww/eww.scss` |
| [x] Rofi | `source.rasi` | `rasi/theme.rasi` | `rofi/themes/shared/palette.rasi` (all layouts) |
| [x] Yazi | `yazi-flavor.toml`, `yazi-tmtheme.xml` | `yazi/flavor.toml`, `yazi/tmtheme.xml` | `yazi/theme.toml` (`[flavor] dark = "matugen"`) ³ |
| [x] Foot | `foot.ini` | `foot/theme.ini` | `foot/foot.ini` (`include` via `current`) ⁴ |
| [x] Hyprland | `hypr.lua` | `hypr/theme.lua` (reload lewat `matugen/palette.sh`) | `hypr/config/core/theme.lua` (`require`, `load` modul data) ⁵ |
| [ ] Cava | — | — | not themed |

> **Activation.** Writing into `generated/<palette>/` does not change the running
> session: every reader goes through `current/…`. `matugen/palette.sh` renders
> into `generated/.<palette>.tmp`, validates, moves it to `generated/<palette>`
> and only then flips `current`, so Flow A is one command
> (`matugen/palette.sh <wallpaper>`) and a failed render leaves the old theme
> active.

¹ Flow A writes Neovim into the same theme folder as every other tool
(`nvim/theme.lua` under `generated/wallpaper-based/`), so a wallpaper render never
touches the active theme; the palette reaches Neovim only once `current` points
at `wallpaper-based` (see the activation note above). ² The generated file exists,
but no include line inside this repo points at it yet (reload: `matugen/palette.sh`). ³ Yazi is split in two: the
generated file holds **colors only** (a flavor), while `yazi/theme.toml` keeps
the glyphs and separators, the notify & cmp icons and the `which` columns, and
never gets rewritten. The consumer is
`yazi/flavors/matugen.yazi/flavor.toml`, a symlink to
`~/.myenv/theme/current/yazi/flavor.toml`, so both flows feed the same path.
The code highlighting in the preview pane is a second generated file of the
same flavor: `yazi/flavors/matugen.yazi/tmtheme.xml` (symlink to
`~/.myenv/theme/current/yazi/tmtheme.xml`). While `[flavor]` is set, Yazi always
uses the flavor's own `tmtheme.xml` and ignores `mgr.syntect_theme` (this repo
leaves it empty), so a broken flavor file is easy to miss.

⁴ Foot exists in both flows under the same name; both are reached through
`~/.myenv/theme/current/foot/theme.ini`, so whichever theme `current` points at
wins. Flow A adds no reload hook for foot — foot has no config-reload signal.

⁵ Hyprland 0.55+ memakai config Lua, jadi tidak ada `source = …` yang bisa
menunjuk berkas tema. Template mengeluarkan **modul data Lua** (`return { … }`)
ke `~/.myenv/theme/current/hypr/theme.lua`, dan `hypr/config/core/theme.lua`
memuatnya dengan `load(…, "t", {})` (env kosong: berkas hanya boleh
mengembalikan tabel) lalu menimpa nilai default, dengan clamp untuk nilai di
luar rentang aman. Nama field tidak boleh diubah; kalau berkas hilang atau gagal
dimuat, nilai default dipakai dan alasannya ditulis ke stderr. Validasi tanpa
reload: `luac -p ~/.myenv/theme/current/hypr/theme.lua` (`matugen/palette.sh`
menjalankan pemeriksaan ini sebelum reload).

Bagian "rasa" (radius, opacity, blur, motion) berasal dari objek `feel` di
blueprint (Flow B). Rancangan untuk memisahkannya menjadi sumbu rasa sendiri
(warna tetap milik `theme/current`) ada di [`FEEL.md`](FEEL.md); belum diterapkan. Pada Flow A template hanya menulis warna, sehingga default
di `hypr/config/core/theme.lua` yang berlaku — satu template, satu berkas tema,
sama seperti `nvim`. `hypr/config/core/theme.lua` juga yang memetakan nilai ke
payload `hl.config`/`hl.curve`/`hl.animation`; `hypr/hyprland.lua` hanya
menerapkannya.

---

## Flow B — fixed palette (`core/palette/kanagawa-dragon-lotus/template/*`)

Config: `core/palette/kanagawa-dragon-lotus/config.toml` · blueprints:
`blueprint/<variant>.json` (`dark.json`, `light.json`) · output root:
`~/.myenv/theme/generated/kanagawa-dragon-lotus/<tool>/…`

| Tool | Template | Output |
|---|---|---|
| [x] Neovim | `nvim.lua` | `nvim/theme.lua` |
| [x] Kitty | `kitty.conf` | `kitty/theme.conf` |
| [x] Alacritty | `alacritty.toml` | `alacritty/theme.toml` |
| [x] Rofi | `source.rasi` | `rasi/theme.rasi` |
| [x] Lazygit | `lazygit.yml` | `lazygit/config.yml` |
| [x] Herdr | `herdr.toml` | `herdr/config.toml` |
| [x] GTK-3 | `gtk3.css` | `css/theme.css` (reload: `matugen/palette.sh`) |
| [x] SCSS | `source.scss` | `scss/_theme.scss` |
| [x] Yazi | `yazi-flavor.toml`, `yazi-tmtheme.xml` | `yazi/flavor.toml`, `yazi/tmtheme.xml` (colors only; see ³) |
| [x] Foot | `foot.ini` | `foot/theme.ini` |
| [x] Hyprland | `hypr.lua` | `hypr/theme.lua` (reload: `matugen/palette.sh`; lihat ⁵) |

Konsumen yang membaca lewat `~/.myenv/theme/current/…`: `kitty/kitty.conf`
(`include`), `foot/foot.ini` (`include`),
`rofi/themes/shared/palette.rasi` (`@import`, shared by all layouts), `swaync/style.css`
(`@import`, GTK 4 — fiturnya ada, bukan cuma di GTK 3), flavor Yazi
`yazi/flavors/matugen.yazi/{flavor.toml,tmtheme.xml}` (symlink), dan
`hypr/config/core/theme.lua` (`require`, lihat ⁵). Sebelum template
kedua alur ada, berkas-berkas itu diisi mesin lama `~/.myenv`; sekarang kedua alur
yang memilikinya, jadi `current` boleh menunjuk ke folder kanagawa tanpa
kehilangan warna.

Key reference for the JSON these templates read:
[`blueprint/README.md`](../core/palette/kanagawa-dragon-lotus/blueprint/README.md).

---

## Flow C — feel (`core/feel/*`)

Config: `core/feel/config.toml` (satu untuk semua profil) · profil:
`core/feel/blueprint/<profil>.json` · entry point: `matugen/feel.sh <profil>` · output root:
`~/.myenv/feel/generated/<profil>/…` (dibalik ke `feel/current` setelah validasi).

Sumbu yang sudah dipindah keluar palet: **font**, **UI terminal**
(opacity, padding, cursor), dan **chrome rofi** (radius, lebar menu).

| Tool | Template | Output | Consumer reads it |
|---|---|---|---|
| [x] eww (popup/profile/OSD) | `template/source.scss` | `scss/_feel.scss` | `eww/eww.scss` (`@import`, sesudah partial tema) |
| [x] Kitty | `template/kitty.conf` | `kitty/feel.conf` | `kitty/kitty.conf` (`include`) |
| [x] Alacritty | `template/alacritty.toml` | `alacritty/feel.toml` | `alacritty/alacritty.toml` (`import`, sesudah tema) |
| [x] Foot | `template/foot.ini` | `foot/feel.ini` | `foot/foot.ini` (`include`) |
| [x] Rofi | `template/rofi.rasi` | `rasi/feel.rasi` | `rofi/themes/shared/palette.rasi` (`@import`) |
| [x] Waybar | `template/gtk3.css` | `css/waybar-font.css` | `waybar/style.css` (`@import`, aturan `*` siap pakai — GTK 3) |
| [x] Swaync | `template/gtk4.css` | `css/swaync-font.css` | `swaync/style.css` (`@import` + `var(--font-family-ui)`) |
| [ ] wlogout / hyprlock / rofi | — | — | masih hardcoded |
| [ ] eww bar | — | — | `eww/bar/styles/_tokens.scss` masih menyimpan font lokal |
| [ ] Depth clock | — | — | `eww/styles/_depth-clock.scss` masih lokal |

Ukuran UI sengaja **tidak** ada di profil: tiap konsumen punya tuning sendiri
(waybar 9.2px, eww 11px/13px, swaync 12px). Yang dibagi adalah **jenis** font,
bobotnya, dan ukuran terminal (`font.size.normal`).

---

## Outside this repo

`~/.myenv` is a separate theme store/engine with its own legacy templates
(`~/.myenv/assets/templates/**`) and a switcher (`theme-switcher.sh` under
`~/.myenv/script/`, parked in `theme.bak/` in this checkout; it only repoints
`~/.myenv/theme/current` with `ln -sfn`). Its `path.txt` still lists generate targets under
`generated/kanagawa-dragon/`, a tree that no longer exists, so that legacy
engine produces nothing today. The only legacy artifact still sitting inside a
theme folder is `generated/kanagawa-dragon-lotus/yazi/theme.toml` (the old 43 KB
Yazi theme): nothing reads it, because `yazi/theme.toml` in this repo selects the
`matugen` flavor. `foot/theme.ini`, `kitty/theme.conf` and `hypr/theme.lua` in
that folder are produced by the flows above now, not by the legacy engine.
Do not add a template
to `matugen/core/palette/wallpaper-based/config.toml` here to "fix" a mismatch; check which side owns the path
first.

`foot/foot.ini` reaches its palette through the active theme, not a fixed
folder, and its font through the feel store:

```ini
include=/home/rascal/.myenv/theme/current/foot/theme.ini
include=/home/rascal/.myenv/feel/current/foot/feel.ini
```
