---
name: matugen-templates
description: Build, register, test and reload Matugen 4.x templates for Linux ricing targets such as kitty, Waybar, rofi, GTK, mako, alacritty, ghostty, btop, neovim, and (on request) compositors like Hyprland or niri. Covers both wallpaper-derived Material You theming and this repo's fixed palettes (hand-authored blueprint/kanagawa-*.json rendered with `matugen json`, theme `kanagawa-dragon-lotus`). Use this whenever the user wants an app themed with matugen.
---

# Matugen Template Skill (matugen 4.1.0)

> Index of the theming docs: [`README.md`](README.md) · repo-level rules:
> [`../../AGENTS.md`](../../AGENTS.md).

You are helping a Linux user "rice" their desktop. Your job is to write **matugen templates** that turn a Material You color scheme into config files for desktop tools, register them in matugen's `config.toml`, and verify that they render correctly.

Read this whole file before writing any template. Follow it as the source of truth. Where this file says **VERIFY**, do not assume: run the suggested command and check.

---

## 0. THIS REPO'S CONTEXT (read this before sections 1–11)

Sections 1–11 are a generic wallpaper-theming skill. **This repo also does something the generic skill does not cover**, so read this first.

Repo: `~/.dotfile` (branch `dev`), with each tool symlinked into `~/.config/<tool>`. `~/.config/matugen` → `~/.dotfile/matugen`.

Repo rules (from `AGENTS.md`):
- Edit files **only inside `~/.dotfile`**; never edit the symlinked `~/.config` copies directly.
- Never run `~/.dotfile/.synchronizer/.sync.sh`.
- Do **not** commit or push unless explicitly asked.
- Generated outputs are not meant to be hand-edited (`**/*.bak` is git-ignored).

### Two different theming flows — pick the right one

**A. Wallpaper-derived ("general") theme** — sections 1–11 below
- Command: `matugen image <wallpaper> --source-color-index 0 -c ~/.config/matugen/config.toml`
- Config: `matugen/config.toml` (`alacritty`, `kitty`, `lazygit`, `scss`, `rasi`, …)
- Templates: `matugen/templates/general/*`, using Material roles `{{ colors.<role>.default.hex }}`.
- Outputs: `~/.myenv/theme/generated/live.bak/<tool>/…`
- Only run `matugen image` when the user asks for wallpaper theming. Always pass `--source-color-index 0`.

**B. Fixed palette (named theme: `kanagawa-dragon-lotus`)** — the usual task in this repo
- Source of truth: `matugen/templates/<theme>/blueprint/<variant>.json` — **one file per variant** (`kanagawa-dark.json`, `kanagawa-light.json`). Hand-authored, **not** matugen-generated. Keys: `meta`, `background`, `foreground`, `cursor`, `colors` (16-entry array, ANSI order, index 0 = black), `color0`…`color15`, and the groups `accent`, `text`, `surface`, `border`, `status`, `effect`, `syntax`. Full reference: `templates/kanagawa-dragon-lotus/blueprint/README.md`.
  - `syntax` uses **universal semantic names** (`comment`, `keyword`, `function`, `string`, `type`, …) so every tool template maps from the same vocabulary.
- Templates: `matugen/templates/<theme>/template/*`.
- Command: `matugen json <blueprint.json> -c <theme-config.toml>`. The JSON is exposed **at the template root**, so templates read root-level keys (`{{ accent.primary }}`, `{{ syntax.keyword }}`) — never `colors.*`, and there is no `dark.*`/`light.*` wrapper: the variant you pass is the variant you get.
- Config: use a **separate config per theme** (`templates/kanagawa-dragon-lotus/config.toml`). Do NOT add fixed-theme templates to `matugen/config.toml`, otherwise every `matugen image` run fails because `accent.*` / `syntax.*` only exist in `json` mode.
- Outputs: `~/.myenv/theme/generated/<theme>/<tool>/…` (here: `generated/kanagawa-dragon-lotus/nvim/`).

### Engine facts verified on this machine (matugen 4.1.0)
- `matugen json <file> -c <cfg>` needs no source color. `-m dark|light` is irrelevant here: the variant comes from which blueprint file you pass.
- `--import-json <file>` adds the same JSON as render data for `matugen image` / `matugen color` runs.
- Dotted access works even for keyword-like keys: `{{ syntax.function }}`, `.return`, `.class`, `.import` are all valid.
- **Arrays cannot be indexed.** `colors[0]` and `colors.0` are parse errors. Loop instead:
  `<* for c in colors *>{{ c }}<* endfor *>`. The two-variable form (`for i, c in arr`) does **not** bind `(index, value)` — use the one-variable form for arrays. That is why the blueprint also duplicates the array as `color0`…`color15`.
- A matugen config file must begin with `[config]`.
- `--dry-run` renders nothing. To test, point `output_path` at a temp directory and run for real.
- Escape `\{{` only when the target language itself contains a literal `{{`. For Lua tables keep one key per line (never `= {{`), and quote Lua keyword keys: `["function"]`, `["return"]`.

### Neovim target (already wired)
- Templates: `matugen/templates/general/nvim.lua` (flow A) and
  `matugen/templates/kanagawa-dragon-lotus/template/nvim.lua` (flow B, omits `source`).
- Output: `~/.myenv/theme/generated/<theme>/nvim/theme.lua` — flow A writes
  straight to `~/.myenv/theme/current/nvim/theme.lua`.
- The generated file is a **palette module only** and is consumed by
  `nvim/lua/core/theme.lua`, which adds `~/.myenv/theme/current/nvim/?.lua` to
  `package.path` and calls `require("theme")` (with a TokyoNight fallback when
  that fails). All tokyonight key mapping, `blend()` math and plugin highlights
  stay in `theme.lua` (the template engine cannot do colour arithmetic).
- Both templates emit **the same key set**, so one mapping serves both flows;
  the mapping table lives in `NVIM_MAPPING.md`.
- When adding a new tool/theme, mirror the comment header used in `matugen/templates/general/*`.

### Testing a fixed-palette template (verified recipe)
```sh
mkdir -p /tmp/mtest/out
cat > /tmp/mtest/config.toml <<'EOF'
[config]

[templates.t]
input_path  = "<abs>/matugen/templates/kanagawa-dragon-lotus/template/nvim.lua"
output_path = "/tmp/mtest/out/out.lua"
EOF
matugen json "<abs>/matugen/templates/kanagawa-dragon-lotus/blueprint/kanagawa-dark.json" -c /tmp/mtest/config.toml
grep -nE '\{\{|\}\}|<\*|\*>' /tmp/mtest/out/out.lua   # must print nothing
luac -p /tmp/mtest/out/out.lua                            # Lua targets must parse
```
Then diff the generated values against the blueprint you rendered — every key
must match 1:1. Repeat with `kanagawa-light.json`.

---

## 0.5 Environment facts

- Target version: **matugen 4.1.0** (check with `matugen --version`).
- Config file (Linux): `~/.config/matugen/config.toml` (override with `-c <FILE>`).
- Recommended template directory: `~/.config/matugen/templates/` (one file per app).
- Subcommands: `image <path>`, `color <hex|rgb|hsl> <value>`, `json <file>`.
- Useful flags (all confirmed from `matugen --help` on the user's machine):

| Flag | Meaning |
|---|---|
| `-m, --mode <light\|dark>` | Mode for the scheme. Default `dark`. |
| `-t, --type <TYPE>` | Scheme type. Default `scheme-tonal-spot`. Others: `scheme-content`, `scheme-expressive`, `scheme-fidelity`, `scheme-fruit-salad`, `scheme-monochrome`, `scheme-neutral`, `scheme-rainbow`, `scheme-vibrant`. |
| `--source-color-index <0-4>` | Picks the source color from an image **without the interactive prompt**. 0 = most dominant. |
| `--contrast <-1..1>` | Contrast adjustment. 0 is standard. |
| `--prefer <...>` | Non-interactive source color preference (`darkness`, `lightness`, `saturation`, `less-saturation`, `value`, `closest-to-fallback`). |
| `--fallback-color <STRING>` | Source color if none is found in the image. |
| `--dry-run` | Do **not** render templates, reload apps, set wallpaper or run commands. |
| `--show-colors` | Print the color table (light and dark columns). |
| `-j, --json <hex\|rgb\|rgba\|hsl\|hsla\|strip>` | Dump colors as JSON. Use this to discover available keys. |
| `--import-json <FILE>`, `--import-json-string <STR>` | Add extra render data. |
| `-b, --base16-backend wal` | Base16 generation backend. |
| `--continue-on-error`, `-q`, `-v`, `-d` | Error tolerance and verbosity. |
| `--old-json-output` | JSON shape from before 4.0.0. Do not use unless asked. |

**Agent rule:** when you run `matugen image ...` yourself, **always pass `--source-color-index 0`** (or `--prefer ...`). Without it matugen may open an interactive selection prompt and your command will hang.

---

## 1. Golden rules

1. **Never hardcode colors** in a template. Every color comes from `{{ colors.<role>.<scheme>.<format> }}`.
2. **Never overwrite the user's hand-written app config.** Render matugen output into a **separate file** (for example `~/.config/kitty/colors-matugen.conf`) and make the main config load it via the app's include/source/import mechanism. Only render a full config file if the app has no include mechanism **and** the user agrees. Back up before replacing anything (`cp -a file file.bak.$(date +%s)`).
3. **Merge into `config.toml`, do not replace it.** Read the existing file first. Keep the user's wallpaper settings, hooks and existing templates.
4. **Use only real color roles** from section 3. Do not invent keys. If unsure, dump the keys (section 8).
5. **Always pair `X` with `on_X`** for text on a colored background (for example `primary` + `on_primary`). This guarantees contrast.
6. **Use the correct color format per app** (section 6). Some apps reject `#`, some need `rgb()`/`rgba()`, some want quotes.
7. **Test before declaring success** (section 8). Render to a temporary location, check for leftover `{{`/`<*`, validate with the app's own checker when it has one.
8. **Be idempotent.** Running matugen twice must give the same result and must not duplicate content.
9. **Keep hooks minimal and safe.** No `sudo`. Append `|| true` to reload commands so a missing process does not break the run.
10. **Report what you did**: files created, lines the user must add to their app config, reload command, and anything you could not verify.

---

## 2. Template syntax (matugen 3.x/4.x engine)

Matugen has its own templating engine. The old `@{primary}` prefix syntax is **legacy (pre-1.0 / pre-3.0)**. Do **not** use it.

### 2.1 Expressions and blocks

| Type | Syntax | Purpose |
|---|---|---|
| Expression | `{{ expression }}` | Evaluate and print a value. |
| Block | `<* ... *>` | Loops, conditionals, includes. |
| Escape | `\{{ ... }}` | Print literal `{{ ... }}` without evaluating. |

Dot notation reaches nested values: `{{ colors.primary.default.hex }}`, `{{ mode }}`, `{{ image }}`, `{{ custom.font1 }}`.

### 2.2 Color path

```
{{ colors.<role>.<scheme>.<format> }}
```

- `<role>`: a name from section 3 (for example `primary`, `surface_container`, `on_surface`).
- `<scheme>`: `light`, `dark`, or `default`.
  - `default` = the mode currently being rendered (`-m`, default `dark`). **Prefer `default`** so one template follows the user's mode.
  - Use explicit `dark` or `light` only when you intentionally need both in one run (for example generating a `colors-light.css` and `colors-dark.css` pair).
  - `amoled` existed in older versions. In 4.1.0 `--mode` only accepts `light` and `dark`, so do not use `amoled`.
- `<format>`:

| Format | Example output | Typical use |
|---|---|---|
| `hex` | `#8F4B39` | kitty, CSS, GTK, TOML, KDL |
| `hex_stripped` | `8F4B39` | Hyprland `rgb()`, foot, fuzzel, anywhere `#` is rejected |
| `rgb` | `rgb(143, 75, 57)` | CSS |
| `rgba` | `rgba(143, 75, 57, 255)` | Alpha math with filters (see warning below) |
| `hsl` / `hsla` | `hsl(...)` | CSS |
| `red` `green` `blue` `alpha` `hue` `saturation` `lightness` | numbers | Scripts, custom formats |

> **Warning on `rgba`:** the raw `rgba` output uses a 0-255 alpha, which is **not valid CSS**. For transparency, either use `{{ colors.x.default.rgba | set_alpha: 0.5 }}` and **VERIFY** the printed result, or append literal alpha hex digits to a `hex`/`hex_stripped` value (for example `{{ colors.surface.default.hex }}cc`), which works in apps that accept `#RRGGBBAA`.

### 2.3 Other keywords

- `{{ mode }}` prints the active mode.
- `{{ image }}` prints the wallpaper path (only when `matugen image` was used).
- `{{ custom.<key> }}` prints a value from `[config.custom_keywords]`.
- `{{ colors.source_color.default.hex }}` is the source color.
- Palettes (tonal palettes) are available as `{{ palettes.<name>.<tone>.hex }}` where tone is `0`-`100`, with a leading underscore for tones that would start with a digit in some contexts (the docs show `palettes.error._99.hex`). **VERIFY** the exact accessor with the JSON dump before using palettes.

### 2.4 Control flow

```
<* if {{ is_dark_mode }} *>
  dark-only content
<* else *>
  light-only content
<* endif *>
```

```
<* for name, value in colors *>
@define-color {{ name }} {{ value.default.hex }};
<* endfor *>
```

```
<* for i in 0..10 *>
  {{ i }}
<* endfor *>
```

Arithmetic and nested expressions are allowed: `{{ {{ i }} * 10 }}`.

Includes pull in another registered template by its **template name** (the key under `[templates.<name>]`):

```
<* include "shared-palette" *>
```

A template used only for inclusion may omit `output_path`.

### 2.5 Filters

Chain with `|`. Arguments use a **colon**: `| filter: arg`.

| Filter | Example | Notes |
|---|---|---|
| `set_alpha` | `{{ colors.primary.default.rgba \| set_alpha: 0.5 }}` | RGBA/HSLA input. |
| `set_hue` | `{{ colors.primary.default.hsla \| set_hue: 90.0 }}` | HSLA input. |
| `set_lightness` | `{{ colors.primary.default.hex \| set_lightness: 10.0 }}` | Raises or lowers lightness; keeps input format. |
| `auto_lightness` | `{{ colors.primary.default.hex \| auto_lightness: 10.0 }}` | Direction depends on mode. **VERIFY** output. |
| `lighten` | `{{ colors.red.default.hex \| lighten: 20.0 }}` | Shown in the official templates page. |
| `grayscale`, `invert` | `{{ colors.primary.default.hex \| invert }}` | |
| `blend` | `{{ colors.x.default.hex \| blend: "#ff0000", 0.5 }}` | Color-argument filter. |
| `harmonize` | `{{ colors.x.default.hex \| harmonize: "#00ff88" }}` | Shifts hue toward the argument. |
| `camel_case` | `{{ name \| camel_case }}` | `surface_dim` -> `surfaceDim`. |
| `replace` | `{{ name \| replace: "_", "-" }}` | `surface_dim` -> `surface-dim`. |
| `to_lower`, `to_upper` | `{{ "ab" \| to_upper }}` | |

The filter set has changed between versions. If a filter errors out, check `matugen -v` output, simplify, and fall back to plain `hex`.

### 2.6 Syntax collisions (very common bug)

Matugen only evaluates `{{ ... }}` and `<* ... *>`. Single braces are safe (CSS, JSON, KDL, rasi, TOML inline tables).

You **must escape** `\{{` when the target language itself contains a literal `{{`, for example:
- Lua nested tables: `\{{ ... }}`
- Go templates, Jinja, Handlebars inside the target file
- JSON written as `{{`-adjacent minified text (prefer formatting JSON with newlines so no `{{` appears)

Also watch for `<*` / `*>` sequences in the target file (rare, but possible in some DSLs or comments).

---

## 3. Available color roles (from the user's own `--show-colors` output)

Material You roles (each has a light and a dark value):

```
primary on_primary primary_container on_primary_container inverse_primary
primary_fixed primary_fixed_dim on_primary_fixed on_primary_fixed_variant
secondary on_secondary secondary_container on_secondary_container
secondary_fixed secondary_fixed_dim on_secondary_fixed on_secondary_fixed_variant
tertiary on_tertiary tertiary_container on_tertiary_container
tertiary_fixed tertiary_fixed_dim on_tertiary_fixed on_tertiary_fixed_variant
error on_error error_container on_error_container
surface_dim surface surface_tint surface_bright
surface_container_lowest surface_container_low surface_container
surface_container_high surface_container_highest
on_surface on_surface_variant outline outline_variant
inverse_surface inverse_on_surface surface_variant
background on_background shadow scrim source_color
```

Base16 roles (matugen 4.x also emits these): `base00` ... `base0f`.

> **Observed caveat:** on the user's sample (a warm, reddish wallpaper, source `#976355`), `base08`-`base0e` came out as nearly the **same brownish-red hue**. Do **not** use base16 colors for terminal ANSI colors (red/green/yellow/blue/magenta/cyan) because they will not be distinguishable. See section 5 for the recommended approach. `base00`-`base07` (the neutral ramp) are fine for neutral grays if needed.

---

## 4. Semantic mapping (use the same role for the same UI job in every app)

Apply this table consistently so the whole desktop feels like one theme.

| UI job | Role |
|---|---|
| Main window / editor background | `surface` (or `background`) |
| Bars (Waybar, panels) | `surface_container_low` (slightly separated from the window) or `surface` |
| Popups, menus, notifications, launchers | `surface_container` (use `surface_container_high` for extra elevation) |
| Input fields, search boxes | `surface_container_high` |
| Deepest layer, overview backdrop | `surface_container_lowest` |
| Primary text | `on_surface` |
| Secondary / dim text, placeholders | `on_surface_variant` |
| Disabled / subtle text | `outline` |
| Active border, focus ring, cursor, accent | `primary` |
| Text on an accent | `on_primary` |
| Inactive border, dividers | `outline_variant` (stronger: `outline`) |
| Selection / highlighted row background | `primary_container` (text: `on_primary_container`) |
| Hover / secondary highlight | `secondary_container` (text: `on_secondary_container`) |
| Links / URLs | `tertiary` |
| Urgent, critical, errors | `error` (text on it: `on_error`) |
| Tooltips | `inverse_surface` (text: `inverse_on_surface`) |
| Shadows | `shadow` with alpha |
| Dim overlays | `scrim` with alpha |

Design principles:
- **Layering:** build depth with the surface ladder (`lowest` < `low` < `container` < `high` < `highest`), not with random grays.
- **Accent restraint:** `primary` marks "active/focused/selected". Do not paint everything with it.
- **Hierarchy:** `on_surface` for important text, `on_surface_variant` for secondary text.
- **Light/dark safe:** always use `default` unless there is a reason not to.

---

## 5. Terminal ANSI palette (kitty, alacritty, ghostty, foot, wezterm)

Terminals need 16 distinguishable hues. Material roles alone do not provide red/green/yellow/blue/magenta/cyan, so **define custom colors** in `config.toml`. Matugen can blend them toward the source color so they feel harmonized:

```toml
[config.custom_colors]
red     = { color = "#E5484D", blend = true }
green   = { color = "#46A758", blend = true }
yellow  = { color = "#E5B800", blend = true }
blue    = { color = "#3E63DD", blend = true }
magenta = { color = "#AB4ABA", blend = true }
cyan    = { color = "#12A594", blend = true }
```

- They are then available as `{{ colors.red.default.hex }}`, etc.
- Matugen typically also generates companion roles such as `on_red`, `red_container`, `on_red_container`. **VERIFY** with the JSON dump (section 8) before using them.
- `blend = true` harmonizes the hue toward the wallpaper (cohesive, but on warm wallpapers green can drift brownish). `blend = false` keeps true hues. If the user dislikes the result, flip it.

Recommended ANSI mapping:

| ANSI | Role |
|---|---|
| 0 black | `surface_container_high` (must be visible against the background) |
| 1 red / 2 green / 3 yellow / 4 blue / 5 magenta / 6 cyan | `colors.red/green/yellow/blue/magenta/cyan` |
| 7 white | `on_surface_variant` |
| 8 bright black | `outline` |
| 9-14 bright colors | same custom color with `\| auto_lightness: 10.0` (**VERIFY** each bright variant is different and legible in both modes) |
| 15 bright white | `on_surface` |

Terminal UI colors:

| Terminal element | Role |
|---|---|
| foreground / background | `on_surface` / `surface` |
| selection fg / bg | `on_primary_container` / `primary_container` |
| cursor / cursor text | `primary` / `on_primary` |
| url | `tertiary` |
| active / inactive border | `primary` / `outline_variant` |
| active tab fg / bg | `on_primary` / `primary` |
| inactive tab fg / bg | `on_surface_variant` / `surface_container` |

---

## 6. Per-app recipes

For each app: output file, how it is loaded, color format, template, reload. Adapt, do not copy blindly. **Always check the app version and the user's existing config first.**

> These are **generic recipes for target apps**, applied only when the user asks
> to theme that app. This repo does not ship every template listed here — its own
> coverage is in [`PROGRESS.md`](PROGRESS.md). In particular, the Hyprland (§6.2)
> and niri (§6.3) recipes are examples, not a statement about the user's setup.
> The repo itself is compositor-agnostic.

### 6.1 kitty

- Output: `~/.config/kitty/colors-matugen.conf`
- Load: add `include colors-matugen.conf` to `kitty.conf`.
- Format: `#RRGGBB` (`hex`).
- Reload: `pkill -USR1 kitty || true` (SIGUSR1 reloads kitty's config).
- Validate: `kitty --debug-config`.

Template `kitty-colors.conf`:

```conf
# Generated by matugen. Do not edit.
foreground              {{ colors.on_surface.default.hex }}
background              {{ colors.surface.default.hex }}
selection_foreground    {{ colors.on_primary_container.default.hex }}
selection_background    {{ colors.primary_container.default.hex }}
cursor                  {{ colors.primary.default.hex }}
cursor_text_color       {{ colors.on_primary.default.hex }}
url_color               {{ colors.tertiary.default.hex }}

active_border_color     {{ colors.primary.default.hex }}
inactive_border_color   {{ colors.outline_variant.default.hex }}
bell_border_color       {{ colors.error.default.hex }}

tab_bar_background      {{ colors.surface_container_low.default.hex }}
active_tab_foreground   {{ colors.on_primary.default.hex }}
active_tab_background   {{ colors.primary.default.hex }}
inactive_tab_foreground {{ colors.on_surface_variant.default.hex }}
inactive_tab_background {{ colors.surface_container.default.hex }}

color0  {{ colors.surface_container_high.default.hex }}
color1  {{ colors.red.default.hex }}
color2  {{ colors.green.default.hex }}
color3  {{ colors.yellow.default.hex }}
color4  {{ colors.blue.default.hex }}
color5  {{ colors.magenta.default.hex }}
color6  {{ colors.cyan.default.hex }}
color7  {{ colors.on_surface_variant.default.hex }}
color8  {{ colors.outline.default.hex }}
color9  {{ colors.red.default.hex | auto_lightness: 10.0 }}
color10 {{ colors.green.default.hex | auto_lightness: 10.0 }}
color11 {{ colors.yellow.default.hex | auto_lightness: 10.0 }}
color12 {{ colors.blue.default.hex | auto_lightness: 10.0 }}
color13 {{ colors.magenta.default.hex | auto_lightness: 10.0 }}
color14 {{ colors.cyan.default.hex | auto_lightness: 10.0 }}
color15 {{ colors.on_surface.default.hex }}
```

### 6.2 Hyprland

- **VERIFY first** which config format the user runs (`hyprctl version`, look at `~/.config/hypr/`). The recipe below is for the classic hyprlang `.conf`. If the user is on a newer config format, adapt accordingly.
- Output: `~/.config/hypr/matugen-colors.conf`
- Load: add `source = ~/.config/hypr/matugen-colors.conf` **at the end** of `hyprland.conf` (later assignments override earlier ones).
- Format: `rgb(RRGGBB)` or `rgba(RRGGBBAA)` using **`hex_stripped`**. No `#`.
- Reload: Hyprland auto-reloads on file change by default. Optional hook: `hyprctl reload || true`.
- Validate: `hyprctl configerrors`.

Template `hyprland-colors.conf`:

```conf
# Generated by matugen. Do not edit.

# Variables: every role becomes $role (usable anywhere, also in hyprlock)
<* for name, value in colors *>
${{ name }} = rgb({{ value.default.hex_stripped }})
<* endfor *>

# Theming (override earlier values because this file is sourced last)
general {
    col.active_border   = rgba({{ colors.primary.default.hex_stripped }}ff) rgba({{ colors.tertiary.default.hex_stripped }}ff) 45deg
    col.inactive_border = rgba({{ colors.outline_variant.default.hex_stripped }}aa)
}

group {
    col.border_active   = rgba({{ colors.primary.default.hex_stripped }}ff)
    col.border_inactive = rgba({{ colors.outline_variant.default.hex_stripped }}aa)
}

decoration {
    shadow {
        color = rgba({{ colors.shadow.default.hex_stripped }}99)
    }
}
```

Notes:
- Ask or check whether the user wants the theming block at all. If they only want variables, ship only the variables section.
- Do not add `col.*` lines for features the user's Hyprland version does not have.

### 6.3 niri

- **VERIFY** `niri --version`. Config includes (`include "file.kdl"`) are only available in recent niri releases. If the user's version lacks `include`, tell them and offer a fallback (render the entire `config.kdl` from a template, with explicit user consent and a backup).
- Output: `~/.config/niri/matugen.kdl`
- Load: add `include "matugen.kdl"` near the **end** of `config.kdl` so it overrides earlier values. **VERIFY** merge/override behavior on the user's version.
- Format: quoted CSS-style strings: `"#RRGGBB"` or `"#RRGGBBAA"`.
- Reload: niri watches its config and reloads automatically.
- Validate: `niri validate` (and read its output).

Template `niri-colors.kdl`:

```kdl
// Generated by matugen. Do not edit.
layout {
    focus-ring {
        active-color   "{{ colors.primary.default.hex }}"
        inactive-color "{{ colors.outline_variant.default.hex }}"
        urgent-color   "{{ colors.error.default.hex }}"
    }

    border {
        active-color   "{{ colors.primary.default.hex }}"
        inactive-color "{{ colors.outline_variant.default.hex }}"
        urgent-color   "{{ colors.error.default.hex }}"
    }

    shadow {
        color "{{ colors.shadow.default.hex }}70"
    }

    tab-indicator {
        active-color   "{{ colors.primary.default.hex }}"
        inactive-color "{{ colors.outline_variant.default.hex }}"
        urgent-color   "{{ colors.error.default.hex }}"
    }

    insert-hint {
        color "{{ colors.primary.default.hex }}80"
    }
}

overview {
    backdrop-color "{{ colors.surface_container_lowest.default.hex }}"
}
```

Notes:
- `focus-ring` and `border` are alternatives in niri (the user usually enables one). Defining colors for both is harmless.
- Only emit sections the user's niri version supports. If `niri validate` rejects a node, remove it.
- Do not emit `on`/`off`, widths or radius here. Those are user preferences, not colors.

### 6.4 Waybar / GTK CSS style apps (waybar, swaync, wlogout, GTK3)

- Output: `~/.config/waybar/colors.css`
- Load: `@import "colors.css";` at the top of `style.css`, then use `@surface`, `@on_surface`, etc.
- Format: `hex` via `@define-color`.
- Reload: `pkill -SIGUSR2 waybar || true` (reloads the style).
- GTK CSS supports `alpha(@surface, 0.8)` for transparency. Prefer it to hand-written rgba.

Template `waybar-colors.css`:

```css
/* Generated by matugen. Do not edit. */
<* for name, value in colors *>
@define-color {{ name }} {{ value.default.hex }};
<* endfor *>
```

Usage hint to give the user:

```css
window#waybar { background: alpha(@surface_container_low, 0.85); color: @on_surface; }
#workspaces button.active { background: @primary; color: @on_primary; }
#battery.critical { background: @error; color: @on_error; }
```

### 6.5 GTK 3 / GTK 4 / libadwaita

- Output: `~/.config/gtk-3.0/gtk.css` and `~/.config/gtk-4.0/gtk.css`. These files are often user-owned, so **VERIFY** and back up first, or use a separate colors file imported from the user's `gtk.css`.
- Format: `@define-color` with `hex`.
- Reload: applications must be restarted. Optional hook toggling the color scheme:  `gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true` (use `prefer-light` for light mode).

Template `gtk-colors.css` (libadwaita named colors):

```css
/* Generated by matugen. Do not edit. */
@define-color accent_color {{ colors.primary.default.hex }};
@define-color accent_bg_color {{ colors.primary.default.hex }};
@define-color accent_fg_color {{ colors.on_primary.default.hex }};
@define-color destructive_color {{ colors.error.default.hex }};
@define-color destructive_bg_color {{ colors.error.default.hex }};
@define-color destructive_fg_color {{ colors.on_error.default.hex }};
@define-color error_color {{ colors.error.default.hex }};
@define-color error_bg_color {{ colors.error.default.hex }};
@define-color error_fg_color {{ colors.on_error.default.hex }};

@define-color window_bg_color {{ colors.surface.default.hex }};
@define-color window_fg_color {{ colors.on_surface.default.hex }};
@define-color view_bg_color {{ colors.surface.default.hex }};
@define-color view_fg_color {{ colors.on_surface.default.hex }};
@define-color headerbar_bg_color {{ colors.surface_container.default.hex }};
@define-color headerbar_fg_color {{ colors.on_surface.default.hex }};
@define-color headerbar_border_color {{ colors.outline_variant.default.hex }};
@define-color card_bg_color {{ colors.surface_container.default.hex }};
@define-color card_fg_color {{ colors.on_surface.default.hex }};
@define-color popover_bg_color {{ colors.surface_container_high.default.hex }};
@define-color popover_fg_color {{ colors.on_surface.default.hex }};
@define-color dialog_bg_color {{ colors.surface_container_high.default.hex }};
@define-color dialog_fg_color {{ colors.on_surface.default.hex }};
@define-color sidebar_bg_color {{ colors.surface_container_low.default.hex }};
@define-color sidebar_fg_color {{ colors.on_surface.default.hex }};
```

### 6.6 rofi

- Output: `~/.config/rofi/colors.rasi`
- Load: `@import "colors.rasi"` at the top of the user's theme, then reference `@surface`, `@primary`, etc.
- Format: `hex`. Use hyphenated names for safety.
- Reload: none needed (rofi reads the theme on launch).

Template `rofi-colors.rasi`:

```rasi
/* Generated by matugen. Do not edit. */
* {
<* for name, value in colors *>
    {{ name | replace: "_", "-" }}: {{ value.default.hex }};
<* endfor *>
}
```

Usage hint: `window { background-color: @surface-container; }`, `element selected { background-color: @primary-container; text-color: @on-primary-container; }`.

### 6.7 fuzzel

- Output: `~/.config/fuzzel/colors.ini`
- Load: `include=~/.config/fuzzel/colors.ini` in `fuzzel.ini` (**VERIFY** that the installed fuzzel supports `include`).
- Format: `RRGGBBAA`, no `#` (`hex_stripped` + alpha digits).

```ini
# Generated by matugen. Do not edit.
[colors]
background={{ colors.surface_container.default.hex_stripped }}f2
text={{ colors.on_surface.default.hex_stripped }}ff
prompt={{ colors.on_surface_variant.default.hex_stripped }}ff
placeholder={{ colors.outline.default.hex_stripped }}ff
input={{ colors.on_surface.default.hex_stripped }}ff
match={{ colors.primary.default.hex_stripped }}ff
selection={{ colors.primary_container.default.hex_stripped }}ff
selection-text={{ colors.on_primary_container.default.hex_stripped }}ff
selection-match={{ colors.primary.default.hex_stripped }}ff
counter={{ colors.on_surface_variant.default.hex_stripped }}ff
border={{ colors.primary.default.hex_stripped }}ff
```

### 6.8 mako (notifications)

- Output: `~/.config/mako/colors` (colors-only file).
- Load: `include=~/.config/mako/colors` in the mako config (**VERIFY** support in the installed version; otherwise render the user's whole config with consent).
- Format: `#RRGGBB` or `#RRGGBBAA`.
- Reload: `makoctl reload || true`.

```ini
# Generated by matugen. Do not edit.
background-color={{ colors.surface_container.default.hex }}f2
text-color={{ colors.on_surface.default.hex }}
border-color={{ colors.primary.default.hex }}
progress-color=over {{ colors.primary_container.default.hex }}

[urgency=high]
background-color={{ colors.error_container.default.hex }}
text-color={{ colors.on_error_container.default.hex }}
border-color={{ colors.error.default.hex }}
```

### 6.9 hyprlock

- Reuse the variables from `hyprland-colors.conf`. Add `source = ~/.config/hypr/matugen-colors.conf` at the top of `hyprlock.conf`, then use `$surface`, `$on_surface`, `$primary` in widgets.
- hyprlock also needs `rgba(...)` for alpha. Build it with the stripped hex plus alpha digits, as in the Hyprland recipe.

### 6.10 alacritty

- Output: `~/.config/alacritty/colors.toml`
- Load: in `alacritty.toml`: `[general]` `import = ["~/.config/alacritty/colors.toml"]` (requires an alacritty version with `general.import`; **VERIFY**).
- Format: `"#RRGGBB"` quoted.
- Reload: alacritty live-reloads changed config and imports.

```toml
# Generated by matugen. Do not edit.
[colors.primary]
background = "{{ colors.surface.default.hex }}"
foreground = "{{ colors.on_surface.default.hex }}"

[colors.cursor]
text   = "{{ colors.on_primary.default.hex }}"
cursor = "{{ colors.primary.default.hex }}"

[colors.selection]
text       = "{{ colors.on_primary_container.default.hex }}"
background = "{{ colors.primary_container.default.hex }}"

[colors.normal]
black   = "{{ colors.surface_container_high.default.hex }}"
red     = "{{ colors.red.default.hex }}"
green   = "{{ colors.green.default.hex }}"
yellow  = "{{ colors.yellow.default.hex }}"
blue    = "{{ colors.blue.default.hex }}"
magenta = "{{ colors.magenta.default.hex }}"
cyan    = "{{ colors.cyan.default.hex }}"
white   = "{{ colors.on_surface_variant.default.hex }}"

[colors.bright]
black   = "{{ colors.outline.default.hex }}"
red     = "{{ colors.red.default.hex | auto_lightness: 10.0 }}"
green   = "{{ colors.green.default.hex | auto_lightness: 10.0 }}"
yellow  = "{{ colors.yellow.default.hex | auto_lightness: 10.0 }}"
blue    = "{{ colors.blue.default.hex | auto_lightness: 10.0 }}"
magenta = "{{ colors.magenta.default.hex | auto_lightness: 10.0 }}"
cyan    = "{{ colors.cyan.default.hex | auto_lightness: 10.0 }}"
white   = "{{ colors.on_surface.default.hex }}"
```

### 6.11 ghostty

- Output: `~/.config/ghostty/colors-matugen`
- Load: `config-file = colors-matugen` in the ghostty config (path is relative to the config file).
- Format: hex (with or without `#`).
- Reload: ghostty's reload-config keybind (default `ctrl+shift+,`). Do not promise automatic reload.

```conf
# Generated by matugen. Do not edit.
background = {{ colors.surface.default.hex }}
foreground = {{ colors.on_surface.default.hex }}
cursor-color = {{ colors.primary.default.hex }}
cursor-text = {{ colors.on_primary.default.hex }}
selection-background = {{ colors.primary_container.default.hex }}
selection-foreground = {{ colors.on_primary_container.default.hex }}

palette = 0={{ colors.surface_container_high.default.hex }}
palette = 1={{ colors.red.default.hex }}
palette = 2={{ colors.green.default.hex }}
palette = 3={{ colors.yellow.default.hex }}
palette = 4={{ colors.blue.default.hex }}
palette = 5={{ colors.magenta.default.hex }}
palette = 6={{ colors.cyan.default.hex }}
palette = 7={{ colors.on_surface_variant.default.hex }}
palette = 8={{ colors.outline.default.hex }}
palette = 9={{ colors.red.default.hex | auto_lightness: 10.0 }}
palette = 10={{ colors.green.default.hex | auto_lightness: 10.0 }}
palette = 11={{ colors.yellow.default.hex | auto_lightness: 10.0 }}
palette = 12={{ colors.blue.default.hex | auto_lightness: 10.0 }}
palette = 13={{ colors.magenta.default.hex | auto_lightness: 10.0 }}
palette = 14={{ colors.cyan.default.hex | auto_lightness: 10.0 }}
palette = 15={{ colors.on_surface.default.hex }}
```

### 6.12 foot

- Output: `~/.config/foot/colors.ini`, loaded with `include=~/.config/foot/colors.ini`.
- Format: `RRGGBB` (`hex_stripped`), **no `#`**.
- **VERIFY** the section name for the installed foot version (`[colors]` versus newer `[colors-dark]`/`[colors-light]`), and adapt.
- Keys: `foreground`, `background`, `selection-foreground`, `selection-background`, `urls`, `regular0`-`regular7`, `bright0`-`bright7`.

### 6.13 btop

- Output: `~/.config/btop/themes/matugen.theme`; the user sets `color_theme = "matugen"` in `btop.conf`.
- Format: `theme[key]="#RRGGBB"`.
- Reload: `pkill -SIGUSR2 btop || true` (**VERIFY**).

```conf
# Generated by matugen. Do not edit.
theme[main_bg]="{{ colors.surface.default.hex }}"
theme[main_fg]="{{ colors.on_surface.default.hex }}"
theme[title]="{{ colors.on_surface.default.hex }}"
theme[hi_fg]="{{ colors.primary.default.hex }}"
theme[selected_bg]="{{ colors.primary_container.default.hex }}"
theme[selected_fg]="{{ colors.on_primary_container.default.hex }}"
theme[inactive_fg]="{{ colors.outline.default.hex }}"
theme[graph_text]="{{ colors.on_surface_variant.default.hex }}"
theme[meter_bg]="{{ colors.surface_container_high.default.hex }}"
theme[proc_misc]="{{ colors.tertiary.default.hex }}"
theme[cpu_box]="{{ colors.outline_variant.default.hex }}"
theme[mem_box]="{{ colors.outline_variant.default.hex }}"
theme[net_box]="{{ colors.outline_variant.default.hex }}"
theme[proc_box]="{{ colors.outline_variant.default.hex }}"
theme[div_line]="{{ colors.outline_variant.default.hex }}"
theme[temp_start]="{{ colors.green.default.hex }}"
theme[temp_mid]="{{ colors.yellow.default.hex }}"
theme[temp_end]="{{ colors.red.default.hex }}"
theme[cpu_start]="{{ colors.primary.default.hex }}"
theme[cpu_mid]="{{ colors.secondary.default.hex }}"
theme[cpu_end]="{{ colors.tertiary.default.hex }}"
```

(Add `free_*`, `cached_*`, `available_*`, `used_*`, `download_*`, `upload_*`, `process_*` gradient keys the same way if the user wants a complete theme.)

### 6.14 Neovim / Lua targets

- Generate a **palette module**, not a full colorscheme. In this repo the generated modules are `~/.myenv/theme/current/nvim/theme.lua` (flow A) and `~/.myenv/theme/generated/kanagawa-dragon-lotus/nvim/theme.lua` (flow B), both loaded by `nvim/lua/core/theme.lua` through `require("theme")` (see section 0).
- Beware the Lua `{{` collision: do not write nested table constructors that put two `{` together. Keep one key per line, and quote Lua keyword keys (`["function"]`, `["return"]`).

```lua
-- Generated by matugen. Do not edit.
return {
  background = "{{ colors.surface.default.hex }}",
  foreground = "{{ colors.on_surface.default.hex }}",
  primary = "{{ colors.primary.default.hex }}",
  on_primary = "{{ colors.on_primary.default.hex }}",
  selection = "{{ colors.primary_container.default.hex }}",
  comment = "{{ colors.outline.default.hex }}",
  error = "{{ colors.error.default.hex }}",
  red = "{{ colors.red.default.hex }}",
  green = "{{ colors.green.default.hex }}",
  yellow = "{{ colors.yellow.default.hex }}",
  blue = "{{ colors.blue.default.hex }}",
  magenta = "{{ colors.magenta.default.hex }}",
  cyan = "{{ colors.cyan.default.hex }}",
}
```

### 6.15 Everything else (swaync, wlogout, zathura, yazi, spicetify, vesktop, quickshell, ags, eww, starship, cava...)

Use this procedure for any app not listed:

1. Find out how the app loads colors: include/source/import, a separate theme file, or CSS.
2. Find the **exact color syntax** the app accepts (with or without `#`, `rgb()`, quotes, alpha order).
3. Pick roles from section 4, never random ones.
4. Prefer **explicit keys** over loops for formats that forbid trailing commas (JSON). Use loops only for flat, comma-free formats (CSS variables, `@define-color`, INI-like lines).
5. Register, test, reload as in section 7 and 8.
6. If the app has no include mechanism and the config mixes colors with other settings, ask the user before templating the whole file.

---

## 7. Registering templates in `config.toml`

Read the existing `~/.config/matugen/config.toml` first, then **add** entries. Do not remove existing ones.

> **In this repo:** `matugen/config.toml` is only for the wallpaper-derived (`general`) theme. The fixed palette (`kanagawa-dragon-lotus`) has its **own config** at `matugen/templates/kanagawa-dragon-lotus/config.toml` and is rendered with `matugen json <blueprint.json>` — never add those templates here (section 0B).

```toml
[config]

# Optional, only if the user wants matugen to set the wallpaper.
# Use whichever tool the user already uses. Do not invent one.
# [config.wallpaper]
# command = "<their wallpaper tool>"
# arguments = ["<args>"]   # the last argument becomes the image path
# set = true

[config.custom_colors]
red     = { color = "#E5484D", blend = true }
green   = { color = "#46A758", blend = true }
yellow  = { color = "#E5B800", blend = true }
blue    = { color = "#3E63DD", blend = true }
magenta = { color = "#AB4ABA", blend = true }
cyan    = { color = "#12A594", blend = true }

# Optional reusable values
# [config.custom_keywords]
# font_mono = "JetBrainsMono Nerd Font"

[templates.kitty]
input_path  = "~/.config/matugen/templates/kitty-colors.conf"
output_path = "~/.config/kitty/colors-matugen.conf"
post_hook   = "pkill -USR1 kitty || true"

[templates.hyprland]
input_path  = "~/.config/matugen/templates/hyprland-colors.conf"
output_path = "~/.config/hypr/matugen-colors.conf"
post_hook   = "hyprctl reload || true"

[templates.niri]
input_path  = "~/.config/matugen/templates/niri-colors.kdl"
output_path = "~/.config/niri/matugen.kdl"

[templates.waybar]
input_path  = "~/.config/matugen/templates/waybar-colors.css"
output_path = "~/.config/waybar/colors.css"
post_hook   = "pkill -SIGUSR2 waybar || true"
```

Notes:
- Template keys: `input_path`, `output_path`, optional `pre_hook`, optional `post_hook`.
- The per-template `mode` option was **removed** in the 3.x+ docs. Do not use it. Use `.dark` / `.light` color schemes inside the template when you need a fixed mode.
- A template used only via `<* include "name" *>` can omit `output_path`.
- Matugen's `-p, --prefix <PATH>` adds a prefix before paths. Do not rely on it for testing. Use a temporary config (section 8).
- Create parent directories of every `output_path` if they do not exist.

---

## 8. Testing procedure (always do this)

### 8.1 Discover available keys and verify syntax assumptions

```sh
matugen color hex "#976355" --dry-run -j hex | head -n 80
# or, if jq exists:
matugen color hex "#976355" --dry-run -j hex | jq 'keys'
```

Use this to confirm that custom colors (`red`, `on_red`, ...), base16 keys, and palettes exist under the names you plan to use.

### 8.2 Render into a sandbox first

1. Create a temporary config `/tmp/matugen-test/config.toml` that points every `output_path` at `/tmp/matugen-test/out/...` (use absolute paths, no hooks).
2. Run it non-interactively:

```sh
matugen color hex "#976355" -c /tmp/matugen-test/config.toml -m dark
matugen color hex "#976355" -c /tmp/matugen-test/config.toml -m light
# with an image (never forget the index):
matugen image "<wallpaper>" --source-color-index 0 -c /tmp/matugen-test/config.toml
```

3. Inspect the output files.

### 8.3 Checks on the rendered output

- No leftover `{{`, `}}`, `<*` or `*>` (`grep -nE '\{\{|\}\}|<\*|\*>' <file>`).
- No empty values (for example `color = ""`, a dangling `$name =`).
- Every color has the format the app expects (`#` or not, `rgb()`, quotes).
- Light and dark renders both look sane (text vs. background contrast, bright ANSI colors different from normal ones).
- Re-running produces an identical file (idempotent).

### 8.4 Validate with the app itself when possible

| App | Command |
|---|---|
| kitty | `kitty --debug-config` |
| niri | `niri validate` |
| Hyprland | `hyprctl configerrors` (after reload) |
| rofi | `rofi -dump-theme` (parses the theme) |
| waybar | run `waybar -l debug` briefly and read CSS errors |
| others | the app's own "check config" option, or a dry launch with logs |

### 8.5 Real run

Only after the sandbox passes:

```sh
matugen image "<wallpaper>" --source-color-index 0 -m dark
```

Confirm the real output files exist and the app picked up the colors. If a reload hook is slow or the process is missing, that is fine because hooks end with `|| true`.

---

## 9. Troubleshooting

| Symptom | Likely cause and fix |
|---|---|
| Matugen hangs | Interactive source-color prompt. Add `--source-color-index 0` or `--prefer ...`. |
| Template error mentioning an unknown key | Misspelled role or a custom color not defined in `[config.custom_colors]`. Dump keys (8.1). |
| Output still contains `{{ ... }}` | The target language had `\{{` collision that you did not escape, or the syntax is `@{...}` legacy. Use the 3.x+ syntax. |
| Colors look wrong in the app | Wrong format for that app (`#` vs no `#`, `rgb()` wrapper, alpha order). Revisit section 6. |
| Terminal ANSI colors all look the same | You used base16 on a monochrome-ish wallpaper. Use custom colors (section 5). |
| Light mode unreadable | You hardcoded `dark` somewhere or the `black`/`white` ANSI mapping is too close to bg/fg. Use `default` and re-check contrast. |
| App ignores the generated file | The include/source line is missing or placed before the user's own values (it must come last in apps where later wins). |
| Transparency looks broken | `rgba` alpha is 0-255, not CSS. Use `set_alpha` and verify, or append alpha hex digits to `hex`. |
| `auto_lightness` / `lighten` fails | Filter differs by version. Fall back to plain `hex` or `set_lightness`. |

---

## 10. Output checklist (what to tell the user at the end)

1. Files created (templates and rendered outputs) with full paths.
2. The exact lines to add to the app's own config (include/source/import), and where to place them.
3. The `config.toml` snippet you added or changed.
4. How reload works for that app (hook or manual).
5. Which commands you ran to test, and the results.
6. Anything marked **VERIFY** that you could not verify, with the exact command for the user to run.

If the request is ambiguous, ask **one** short question (for example which wallpaper tool they use or whether they prefer light or dark). Otherwise proceed with sensible defaults from this file.

---

## 11. References

- Matugen repository: https://github.com/InioX/matugen
- Matugen docs (moved from the wiki): https://iniox.github.io/#matugen/
- Wiki pages (may be outdated, kept for reference): `Templates`, `Configuration`, `Filters`, `Hooks`
- Always prefer the **installed** version's behavior (`matugen --help`, `-j` dumps, sandbox renders) over any documentation, including this file.
