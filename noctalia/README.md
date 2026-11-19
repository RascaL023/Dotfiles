# Noctalia

Palette generation for [Noctalia](https://noctalia.dev) 5.x: derive a token map
from a wallpaper (or take an existing one), render the templates in
`core/palette/wallpaper-based/`, activate the result, and reload its consumers.

The `noctalia-ctl` entry point covers the palette workflow only; the shell's own
`config.toml` in this folder is not rendered by it.

## Usage

```bash
noctalia-ctl palette ~/Pictures/wall.png      # derive colours, render, activate
noctalia-ctl palette ~/.config/noctalia/palettes/solarized.json  # token map
noctalia-ctl palette                          # reload consumers only
noctalia-ctl palette --list                   # known consumers
```

| Option | Effect |
|---|---|
| `-n`, `--dry-run` | print the commands, change nothing |
| `-N`, `--no-reload` | render without reloading consumers |
| `-s`, `--scheme <name>` | wallpaper generator (default: `[theme].wallpaper_scheme`, else `m3-tonal-spot`) |
| `-b`, `--pure-black` | force the OLED surface ramp |
| `-l`, `--list` | print known consumers |
| `-h`, `--help` | usage |

Palette sources:

- an image (`png`, `jpg`, `jpeg`, `webp`, `gif`, `bmp`) becomes
  `noctalia theme <image> --both -o palette.json`
- an existing token map (`.json`): a community palette from
  `~/.local/state/noctalia/community-palettes/`, a file in `palettes/`, or a
  previous dump

## Store

```text
~/.myenv/theme/palette/generated/noctalia/wallpaper-based/   rendered files
~/.myenv/theme/palette/current -> generated/noctalia/wallpaper-based
```

Each producer owns its engine folder — `generated/matugen/` for matugen,
`generated/noctalia/` here — so both can ship a `wallpaper-based` palette and
`current` still names the engine that is live.

A render is staged in `generated/noctalia/.wallpaper-based.tmp`, validated
(non-empty files, no leftover `{{ }}` or `<* *>`), then moved into place;
`current` is flipped only after validation. `THEME_ROOT` overrides the store.

Noctalia has no `-p <store>` flag and resolves `output_path` against the render
config's directory, so the config is copied into the staging directory.

Reload is delegated to `matugen/script/palette.sh`: consumers read `current`, so
they do not care which palette produced it.

## Layout

```text
noctalia-ctl                       entry point (`palette …`)
script/palette.sh                  palette workflow
core/palette/wallpaper-based/
  config.toml                      one [templates.*] per consumer
  template/                        templates
docs/NOCTALIA_SKILLS.md            template syntax, engine limits, testing
```

Template authoring rules and verified engine limits live in
[`docs/NOCTALIA_SKILLS.md`](docs/NOCTALIA_SKILLS.md).
