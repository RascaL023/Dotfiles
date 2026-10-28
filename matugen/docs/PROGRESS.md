# Template Coverage

> Index: [`README.md`](README.md) · flows are described in
> [`README.md`](README.md) and [`../../AGENTS.md`](../../AGENTS.md).
>
> [x] = template exists in this repo · [ ] = consumer reads a generated file,
> but the file is produced elsewhere (or the tool is not themed yet).

Last verified against the repo: 2026-10-28.

---

## Flow A — wallpaper (`templates/general/*`)

Config: `matugen/config.toml` · output root:
`~/.myenv/theme/generated/live.bak/<tool>/…`

| Tool | Template | Output | Consumer reads it |
|---|---|---|---|
| [x] Kitty | `kitty.conf` | `kitty/theme.conf` | `kitty/kitty.conf` (`include`) |
| [x] Alacritty | `alacritty.toml` | `alacritty/theme.toml` | `alacritty/alacritty.toml` (`import`) |
| [x] Neovim | `nvim.lua` | `nvim/theme.lua` ¹ | `nvim/lua/core/theme.lua` (`require`) |
| [x] Lazygit | `lazygit.yml` | `lazygit/config.yml` | —² |
| [x] Herdr | `herdr.toml` | `herdr/config.toml` | —² |
| [x] GTK / CSS | `source.css` | `css/theme.css` (+ `dconf` + `swaync-client -rs` post_hooks) | `waybar/style.css`, `wlogout/style.css`, `swaync/style.css` |
| [x] SCSS | `source.scss` | `scss/_theme.scss` | `eww/eww.scss` |
| [x] Rofi | `source.rasi` | `rasi/theme.rasi` | `rofi/themes/*.rasi` |
| [x] Yazi | `yazi-flavor.toml`, `yazi-tmtheme.xml` | `yazi/flavor.toml`, `yazi/tmtheme.xml` | `yazi/theme.toml` (`[flavor] dark = "matugen"`) ³ |
| [x] Foot | `foot.ini` | `foot/theme.ini` | `foot/foot.ini` (`include` via `current`) ⁴ |
| [x] Hyprland | `hypr.lua` | `hypr/theme.lua` (+ `hyprctl reload` post_hook) | `hypr/config/core/theme.lua` (`require`, `load` modul data) ⁵ |
| [ ] Cava | — | — | not themed |

¹ Flow A is the only flow whose Neovim output is written straight to
`~/.myenv/theme/current/nvim/theme.lua`, i.e. it does not wait for a theme
switch. ² The generated file exists and a `post_hook` reloads the tool, but no
include line inside this repo points at it yet. ³ Yazi is split in two: the
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
reload: `luac -p ~/.myenv/theme/current/hypr/theme.lua` (dijalankan juga sebagai
`post_hook`).

Bagian "rasa" (radius, opacity, blur, motion) berasal dari objek `feel` di
blueprint (Flow B). Pada Flow A template hanya menulis warna, sehingga default
di `hypr/config/core/theme.lua` yang berlaku — satu template, satu berkas tema,
sama seperti `nvim`. `hypr/config/core/theme.lua` juga yang memetakan nilai ke
payload `hl.config`/`hl.curve`/`hl.animation`; `hypr/hyprland.lua` hanya
menerapkannya.

---

## Flow B — fixed palette (`templates/kanagawa-dragon-lotus/template/*`)

Config: `templates/kanagawa-dragon-lotus/config.toml` · blueprints:
`blueprint/kanagawa-{dark,light}.json` · output root:
`~/.myenv/theme/generated/kanagawa-dragon-lotus/<tool>/…`

| Tool | Template | Output |
|---|---|---|
| [x] Neovim | `nvim.lua` | `nvim/theme.lua` |
| [x] Kitty | `kitty.conf` | `kitty/theme.conf` (+ `pkill -SIGUSR1` post_hook) |
| [x] Alacritty | `alacritty.toml` | `alacritty/theme.toml` |
| [x] Rofi | `source.rasi` | `rasi/theme.rasi` |
| [x] Lazygit | `lazygit.yml` | `lazygit/config.yml` |
| [x] Herdr | `herdr.toml` | `herdr/config.toml` |
| [x] GTK-3 | `gtk3.css` | `css/theme.css` (+ `dconf` + `swaync-client -rs` post_hooks) |
| [x] SCSS | `source.scss` | `scss/_theme.scss` |
| [x] Yazi | `yazi-flavor.toml`, `yazi-tmtheme.xml` | `yazi/flavor.toml`, `yazi/tmtheme.xml` (colors only; see ³) |
| [x] Foot | `foot.ini` | `foot/theme.ini` |
| [x] Hyprland | `hypr.lua` | `hypr/theme.lua` (+ `hyprctl reload` post_hook; lihat ⁵) |

Konsumen yang membaca lewat `~/.myenv/theme/current/…`: `kitty/kitty.conf`
(`include`), `foot/foot.ini` (`include`),
`rofi/themes/{theme,apps,wallpaper}.rasi` (`@import`), `swaync/style.css`
(`@import`, GTK 4 — fiturnya ada, bukan cuma di GTK 3), flavor Yazi
`yazi/flavors/matugen.yazi/{flavor.toml,tmtheme.xml}` (symlink), dan
`hypr/config/core/theme.lua` (`require`, lihat ⁵). Sebelum template
kedua alur ada, berkas-berkas itu diisi mesin lama `~/.myenv`; sekarang kedua alur
yang memilikinya, jadi `current` boleh menunjuk ke folder kanagawa tanpa
kehilangan warna.

Key reference for the JSON these templates read:
[`blueprint/README.md`](../templates/kanagawa-dragon-lotus/blueprint/README.md).

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
to `matugen/config.toml` here to "fix" a mismatch; check which side owns the path
first.

`foot/foot.ini` reaches its palette through the active theme, not a fixed
folder:

```ini
include=/home/rascal/.myenv/theme/current/foot/theme.ini
```
