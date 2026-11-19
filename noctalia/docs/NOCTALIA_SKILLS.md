---
name: noctalia-templates
description: Render Noctalia 5.x palette tokens into app config files. Covers `noctalia theme` palette generation, template syntax and filters, `[templates.*]` render configs, and the engine limits verified on this machine (no nested expressions, no template variables, literal-only filter arguments). Use whenever the user wants Noctalia to colour a desktop tool.
---

# Noctalia Template Skill (noctalia 5.4.1)

> Repo rules: [`../../AGENTS.md`](../../AGENTS.md).

You are writing templates that Noctalia renders from a palette. Noctalia owns
colours only: no geometry, no look/feel values, no arithmetic. Palette
generation and template rendering are two separate calls.

Facts marked **[V]** were verified on this machine with noctalia 5.4.1.
Facts marked **[?]** come from the docs and are untested here.

## 1. Two stages, one command

| Stage | Command | Result |
|---|---|---|
| palette | `noctalia theme <image> --both -o palette.json` | token map per mode |
| render | `noctalia theme --theme-json <palette.json> -c <config.toml>` | files |
| one file | `noctalia theme --theme-json <palette.json> -r in.txt:out.txt` | a single file |

Both work headless — no running shell is required **[V]**. The renderer never
extracts colours itself, so a render always needs a palette JSON.

Useful flags: `--scheme <name>`, `--dark`/`--light`/`--both`, `--pure-black`,
`--default-mode <dark|light>`, `--list-templates`, `--builtin-config`.

## 2. Palette sources

`[theme].source` in `~/.config/noctalia/config.toml` decides what the shell
renders; the CLI always needs an explicit palette JSON.

| `source` | Where colours come from | For the CLI |
|---|---|---|
| `builtin` | palettes compiled into the binary | not dumpable |
| `wallpaper` | Material You palette derived from the current wallpaper; `wallpaper_scheme` picks the generator | `noctalia theme <image> --both -o p.json` |
| `community` | `api.noctalia.dev/palette/<name>`, cached | `~/.local/state/noctalia/community-palettes/<Nama>.json` |
| `custom` | `~/.config/noctalia/palettes/<custom_palette>.json` | that file, directly |

Other keys: `mode` (`dark`/`light`/`auto`), `shell_mode`, `pure_black_dark`,
`sync_color_scheme`, `builtin`, `community_palette`, `custom_palette`,
`wallpaper_scheme`.

`wallpaper_scheme` values: `m3-tonal-spot`, `m3-content`, `m3-fruit-salad`,
`m3-rainbow`, `m3-monochrome`, `vibrant`, `faithful`, `dysfunctional`, `muted`.

**Palette file format.** `palettes/` is the v5 location (v4 used
`colorschemes/<Nama>/<Nama>.json`). Two formats are accepted by `--theme-json`
**[V]**:

- Format 1 (no `version`): `mPrimary`, `mOnPrimary`, … plus a `terminal`
  object. 16 roles only.
- Format 2 (`"version": 2`): snake_case role keys (`primary`, `on_primary`,
  `surface_container`, `outline_variant`, …) plus `terminal`.

A palette sets 16 roles; containers, `on_*_container` and the rest of the
surface ramp are derived by the engine **[V]**. Derived values need not follow
M3 ordering — on some palettes `surface_container_lowest` is lighter than
`surface` **[V]** — so pick a role by looking at the render, not by name.

## 3. Template context

Token path: `colors.<token>.<mode>.<format>`.

- `<mode>`: `default` (mode being rendered), `dark`, `light`. All three are
  available in one render **[V]**.
- `<token>`: the 48 Material roles (`primary`, `on_primary`,
  `primary_container`, `surface`, `surface_container_{lowest,low,high,highest}`,
  `outline`, `outline_variant`, `shadow`, `scrim`, `background`, `error`, …),
  `hover`/`on_hover`, `source_color`, `surface_tint`, and 22 terminal tokens
  (`terminal_{foreground,background,cursor,cursor_text,selection_fg,selection_bg}`,
  `terminal_{normal,bright}_{black,red,green,yellow,blue,magenta,cyan,white}`).
- Scalars: `mode`, `image`, `closest_color`, `config_dir`, `config_file`.

**Formats** **[V]**

| Format | Output |
|---|---|
| `hex` | `#88d1ec` |
| `hex_stripped` | `0f1416` (no `#`; not composable with filters) |
| `rgb` / `rgba` | `rgb(r, g, b)` / `rgba(136, 209, 236, 1)` |
| `rgb_csv` | `136,209,236` |
| `hsl` / `hsla` | `hsl(196, 72%, 72%)` / `hsla(196, 72%, 72%, 1)` |
| `red`/`green`/`blue`, `alpha`, `hue`/`saturation`/`lightness` | integers |

**Filters**: `lighten`, `darken`, `set_lightness`, `saturate`, `desaturate`,
`set_saturation`, `set_hue`, `rotate_hue`, `grayscale`, `invert`, `set_alpha`,
`auto_lightness`, `blend`, `harmonize`, `to_color`, plus string helpers
(`replace`, `lower_case`, `snake_case`, …). Both `filter arg` and
`filter: arg` parse **[V]**; `lighten: -10` darkens.

**Blocks**: `<* for x in … *>`, `<* if {{ scalar }} *>`, `<* else *>`,
`<* endif *>`, `<* endfor *>`, with `loop.index/first/last`. A block tag alone
on its line takes the line with it.

## 4. Render config

```toml
[templates.kitty]
input_path  = "~/.config/noctalia/core/palette/wallpaper-based/template/kitty.conf"
output_path = "kitty/theme.conf"
post_hook   = "kitty @ set-colors -a kitty/theme.conf 2>/dev/null || true"
hook_async  = false
```

```bash
noctalia theme --theme-json palette.json -c config.toml
```

Path rules **[V]**:

- `input_path` expands `~`. It does **not** expand `$HOME` or
  `{{ config_dir }}` (both stay literal and the template is skipped).
- `output_path` is resolved against the **directory of the config file**, not
  the working directory. Subdirectories are created.
- There is no `-p <store>` flag; the caller decides where output goes by
  choosing where the config lives.
- `[config]` is optional. `post_hook` runs after the file is written; it is
  asynchronous unless `hook_async = false`.

## 5. Engine limits (all **[V]**)

| Symptom | Cause |
|---|---|
| Whole file fails, message `1 template error(s); output not written`, hook never runs | one unknown token — no partial output, no default |
| `{{ … | format: rgba }}` prints the hex unchanged | unknown filters are ignored **silently** |
| `{{ … .hex | set_alpha 0.5 }}` keeps the same hex | alpha only exists in `rgba` |
| `{{ colors.x.default.hex_stripped | lighten: 40 }}` becomes `#ffffff` | `hex_stripped` cannot be filtered |
| `blend: colors.y.default.hex, 0.6` has no effect | filter colour arguments must be literal hex (`"#8a9a7b"`) |
| `blend: {{ colors.y… }}, 0.6` leaves `, 0.6 }}` in the output | nested `{{ }}` is not parsed inside an expression |
| `<* set c = … *>` prints `{{c}}` | there are no template variables |
| `<* if {{ colors.warning }} *>` fails | conditionals accept scalars only, not colour objects |
| `-c` exits 0 although a template failed | failures are warnings; a count + placeholder check is the only reliable test |
| Output file mtime unchanged | identical content is not rewritten (inotify reloads may not fire) |
| `custom_colors` do not keep their hex | `blend = true` by default harmonises them into the palette |

## 6. Testing

Render to a scratch directory first; never point a test at a live path. This
repo uses `/tmp/Dotfiles/Noctalia/` for scratch work.

```bash
mkdir -p /tmp/Dotfiles/Noctalia/probe && cd /tmp/Dotfiles/Noctalia/probe
printf 'bg {{ colors.surface.default.hex }}\n' > in.txt
noctalia theme --theme-json palette.json -r in.txt:out.txt
```

One expression per file when bisecting: the error message does not name the
failing token, and a failed template writes nothing.

After rendering, check every file:

```bash
grep -nE '\{\{|\}\}|<\*|\*>' out.txt   # must print nothing
```

Then validate with the target tool when it has a checker: `luac -p` for Lua,
TOML/JSON/XML parsers for those formats, the app's own config test otherwise
(`foot -c file -e true` reports colour-format errors even without Wayland).

## 7. This repo

| Path | Content |
|---|---|
| `noctalia/core/palette/wallpaper-based/config.toml` | render config, one `[templates.*]` per consumer |
| `noctalia/core/palette/wallpaper-based/template/` | template files |
| `noctalia/noctalia-ctl` | entry point (`palette …`): render, validate, flip `current`, reload |
| `noctalia/script/palette.sh` | the palette workflow behind that entry point |
| `noctalia/sync.toml` | user template + `post_hook` that sync the GUI palette |
| `noctalia/core/palette/palette-dump.json` | dumps the resolved palette (dark + light) for that hook |
| `noctalia/README.md` | usage, palette sources, and the store layout |

```bash
noctalia-ctl palette "<wallpaper>"      # palette from an image, then render
noctalia-ctl palette <palette>.json     # render an existing palette
noctalia-ctl palette --list | --dry-run | --no-reload | --scheme <s> | --pure-black
```

`noctalia-ctl` exposes the palette workflow only: every call is
`noctalia-ctl palette …`. It renders into
`~/.myenv/theme/palette/generated/noctalia/.wallpaper-based.tmp`
(a copy of the config lives there, so relative outputs land inside it),
validates, moves the folder to `generated/noctalia/wallpaper-based`, then flips
`current`. One folder per engine: matugen writes `generated/matugen/`, so both
producers can ship a `wallpaper-based` palette without collision and flipping
back is a symlink change. `THEME_ROOT` overrides the store. The wallpaper
scheme and `pure_black_dark` are read from `[theme]` in
`~/.local/state/noctalia/settings.toml`, falling back to `noctalia/config.toml`.

GUI changes take the same path: `sync.toml` renders `palette-dump.json` to
`~/.cache/noctalia/palette.json` and its `post_hook` runs
`noctalia-ctl palette --from-shell`, which reads the active mode from IPC and
re-renders the store exactly like a manual run.

Generated output is never edited by hand: change the template, then re-render.

## 8. Unknowns

- Does rofi accept `rgba(r, g, b, a)` as a `*` variable value?
- Do `output_path_dynamic` and `post_action` exist in the CLI as they do in the
  shell's own template config?
- Does `--theme-json` accept a palette with only one mode (`dark` or `light`)?
- Does `~` expand in `output_path` as it does in `input_path`?
