# Template Coverage

> Index: [`README.md`](README.md) · flows are described in
> [`README.md`](README.md) and [`../../AGENTS.md`](../../AGENTS.md).
>
> [x] = template exists in this repo · [ ] = consumer reads a generated file,
> but the file is produced elsewhere (or the tool is not themed yet).

Last verified against the repo: 2026-10-11.

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
| [x] GTK / CSS | `source.css` | `css/theme.css` | `waybar/style.css`, `wlogout/source.css` |
| [x] SCSS | `source.scss` | `scss/_theme.scss` | `eww/eww.scss` |
| [x] Rofi | `source.rasi` | `rasi/theme.rasi` | `rofi/themes/*.rasi` |
| [ ] Foot | — | — | pinned to the Flow B path (see below) |
| [ ] Cava | — | — | not themed |
| [ ] Yazi | — | — | not themed |

¹ Flow A is the only flow whose Neovim output is written straight to
`~/.myenv/theme/current/nvim/theme.lua`, i.e. it does not wait for a theme
switch. ² The generated file exists and a `post_hook` reloads the tool, but no
include line inside this repo points at it yet.

---

## Flow B — fixed palette (`templates/kanagawa-dragon-lotus/template/*`)

Config: `templates/kanagawa-dragon-lotus/config.toml` · blueprints:
`blueprint/kanagawa-{dark,light}.json` · output root:
`~/.myenv/theme/generated/kanagawa-dragon-lotus/<tool>/…`

| Tool | Template | Output |
|---|---|---|
| [x] Neovim | `nvim.lua` | `nvim/theme.lua` |
| [x] Alacritty | `alacritty.toml` | `alacritty/theme.toml` |
| [x] Lazygit | `lazygit.yml` | `lazygit/config.yml` |
| [x] Herdr | `herdr.toml` | `herdr/config.toml` |
| [x] GTK-3 | `gtk3.css` | `css/theme.css` (+ `dconf` post_hook) |
| [x] SCSS | `source.scss` | `scss/_theme.scss` |
| [ ] Kitty | — | — |
| [ ] Rofi | — | — |

Key reference for the JSON these templates read:
[`blueprint/README.md`](../templates/kanagawa-dragon-lotus/blueprint/README.md).

---

## Outside this repo

`~/.myenv` is a separate theme store/engine with its own legacy templates
(`~/.myenv/assets/templates/**`) and a switcher
(`~/.myenv/script/theme/theme-switcher.sh`, which repoints
`~/.myenv/theme/current`). Its generated tree contains more tools than the two
flows above produce (e.g. `foot/theme.ini`, `kitty/theme.conf`,
`yazi/theme.toml` for a Kanagawa theme) — those files are **not** managed from
`~/.dotfile`. Do not add a template to `matugen/config.toml` here to "fix" a
mismatch; check which side owns the path first.

`foot/foot.ini` is the one consumer in this repo that points at such a file:

```ini
include=/home/rascal/.myenv/theme/generated/kanagawa-dragon-lotus/foot/theme.ini
```
