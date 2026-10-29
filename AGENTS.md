# AGENTS.md

**Purpose:** keep config sync and theming in this repo mistake-free. Two jobs
live here: (1) moving configs between `~/.dotfile` and `~/.config` via
`.synchronizer/.sync.sh`, and (2) painting tools from one color source via
`matugen/`.

Nothing here is Hyprland-specific. The repo ships a `hypr/` config, but the sync
script and the theming pipeline work with any compositor.

---

## Ground rules (read first)

- **Edit configs only inside `~/.dotfile`.** `~/.config/<tool>` is a symlink to
  the same file — editing "the copy" edits the repo.
- **Do not run `.synchronizer/.sync.sh`** unless the user asks. `link`/`restore`
  **move** real configs on disk.
- **Do not commit or push** unless the user asks.
- **Never hand-edit generated artifacts.** Change the template or palette, then
  re-render:

  | Artifact | Produced by | Ignored? |
  |---|---|---|
  | `~/.myenv/theme/generated/**` | `matugen` (outside the repo) | n/a |
  | `matugen/generated.bak/` | `matugen image` test runs | yes (`**.bak`) |
  | `matugen/templates/test.conf` | scratch test template | yes |

- **`.private/`** directories (e.g. `matugen/.private/`) are git-ignored scratch
  and session notes — never a source of truth.
- **`*.bak`, `*.tmp`** files are git-ignored; do not rely on them as data.

---

## Where things live

```text
~/.dotfile
├── .synchronizer/{.sync.sh,state.tmp}
├── tools.list                    # tools the synchronizer manages
├── matugen/
│   ├── config.toml               # Flow A (wallpaper → Material You)
│   ├── templates/general/*               # Flow A templates
│   ├── templates/kanagawa-dragon-lotus/
│   │   ├── blueprint/*.json              # Flow B palette (one file per variant)
│   │   ├── template/*                    # Flow B templates
│   │   ├── config.toml                   # Flow B render config
│   │   └── blueprint/README.md           # key-by-key reference
│   └── docs/                     # start at docs/README.md
├── nvim/ kitty/ foot/ …          # one directory per tool, symlinked to ~/.config
└── README.md                     # user-facing overview
```

Entry points:

- Config sync: `.synchronizer/.sync.sh`
- Theming: `matugen/config.toml` (Flow A), `matugen/templates/<theme>/config.toml` (Flow B)
- Agent docs: this file + `matugen/docs/`

---

## Commands

### Sync — `.synchronizer/.sync.sh` (pure bash)

```bash
# interactive (asks password "atmin123", 3 tries, then a menu)
bash ~/.dotfile/.synchronizer/.sync.sh

# non-interactive (no password prompt)
~/.dotfile/.synchronizer/.sync.sh link    [tool ...]
~/.dotfile/.synchronizer/.sync.sh restore [tool ...]
~/.dotfile/.synchronizer/.sync.sh status  [tool ...]
```

- `link` — move the config into the repo, then symlink it back into place
- `restore` — undo: move the config from the repo back to its original path
- `status` — dry-run report, changes nothing
- Omit the tool argument to act on **all** tools from `tools.list`

### Theming — matugen 4.x

```bash
# Flow A: wallpaper-derived
matugen image <wallpaper> --source-color-index 0 -c ~/.config/matugen/config.toml

# Flow B: fixed palette (pick the variant with the file you pass)
matugen json ~/.dotfile/matugen/templates/kanagawa-dragon-lotus/blueprint/kanagawa-dark.json \
  -c ~/.dotfile/matugen/templates/kanagawa-dragon-lotus/config.toml
```

Always pass `--source-color-index 0` (or `--prefer …`) on `matugen image`, or
matugen may open an interactive color picker and hang.

Test a template into `/tmp` before rendering over a live path — recipe in
`matugen/docs/MATUGEN_SKILLS.md`, section 0.

---

## Theming: two flows, keep them apart

| | Flow A — wallpaper | Flow B — fixed palette |
|---|---|---|
| Config | `matugen/config.toml` | `matugen/templates/<theme>/config.toml` |
| Palette source | the image | `blueprint/<variant>.json` (hand-written) |
| Command | `matugen image …` | `matugen json <blueprint>.json …` |
| Template vocabulary | `{{ colors.<role>.<scheme>.<format> }}` | root-level keys: `{{ accent.primary }}`, `{{ syntax.keyword }}` |
| Themes here | `general` | `kanagawa-dragon-lotus` |
| Output | `~/.myenv/theme/generated/live.bak/<tool>/…` | `~/.myenv/theme/generated/<theme>/<tool>/…` |

Rules:

- **Separate config per flow.** Adding a Flow B template to `matugen/config.toml`
  breaks every `matugen image` run (no `accent.*` in a Material You palette).
- **One blueprint file = one variant.** `kanagawa-dark.json` and
  `kanagawa-light.json` are independent; nothing syncs them automatically.
- **Placeholder names are not shared** between flows — the same tool needs its
  own template per flow. Never assume a value exists; grep the template.
- `~/.myenv` is the theme store **outside** this repo: this repo only renders
  into it. `~/.myenv/theme/current` is a symlink to the active theme directory
  and is flipped outside this repo by `theme-switcher.sh` (in
  `~/.myenv/script/`, parked under `theme.bak/` in this checkout); the legacy
  engine's own `assets/templates/**` is not managed from here.

---

## Neovim theming

- `nvim/lua/core/theme.lua` is the single source of truth for Neovim colors. It
  loads the generated palette via
  `package.path += "~/.myenv/theme/current/nvim/?.lua"` → `require("theme")`,
  maps it onto TokyoNight's keys, and owns all plugin highlight groups.
- If that `require` fails — or the palette loads but is incomplete — the module
  enters fallback mode: `M.fallback = true` and `M.colors` holds `FALLBACK_COLORS`
  (`fg`, `bg`, `bg_dark`, `bg_highlight`, `magenta`, identical to TokyoNight
  `style = "night"`). `M.colors` and `M.syntax` are **always** tables, so
  consumers such as `zen.lua` and `smear_cursor.lua` never index nil; the
  internal overrides (`on_highlights`, `apply_plugin_highlights`,
  `apply_syntax_highlights`) return early while `M.fallback` is set. Never assume
  the real palette loaded — check `M.fallback`. Fallback only covers keys read at
  startup (outside `on_highlights`/`build_colors`); add new ones to
  `FALLBACK_COLORS`.
- `M.reload()` always exists and validates with `pcall(build_colors, fresh)`
  before attaching, so a broken, empty or half-written `theme.lua` never changes
  what is on screen — and a palette that appears later moves Neovim out of
  fallback without a restart. `nvim/init.lua` starts `core.theme_watch` **before**
  `core.lazy` so the watcher survives a failing plugin spec.
- Templates that produce it:
  - Flow A: `matugen/templates/general/nvim.lua` → `~/.myenv/theme/generated/live.bak/nvim/theme.lua`
  - Flow B: `matugen/templates/kanagawa-dragon-lotus/template/nvim.lua` → `~/.myenv/theme/generated/kanagawa-dragon-lotus/nvim/theme.lua`
- **Both flows write into their own theme folder, never into `current`.** The
  loader still reads `current/nvim/theme.lua`, so a palette only goes live after
  `current` points at that folder; activating Flow A is still manual (nothing in
  this repo flips it yet).
- **Both templates emit exactly the same key set** (verified: `background`,
  `foreground`, `cursor`, `colors[16]`, `extra.{accent,container,text,layer,
  border,status,fg,bg,syntax,ui}`; Flow B just omits `source`). So one mapping
  logic serves both — document new keys in `matugen/docs/NVIM_MAPPING.md`.
- Keep **data** (generated palette) separate from **mapping** (theme.lua): the
  template engine cannot do color arithmetic; `blend()` and every derived shade
  belong in `theme.lua`.

---

## State & metadata

- **Sync state:** `.synchronizer/state.tmp`, tab-separated `tool<TAB>original path`.
  Local, machine-specific, git-ignored. This is what makes `restore` exact.
- **`tools.list`** — one tool per line:
  - `tool` → auto-locate a file/dir/symlink under the config root
  - `tool:explicit_path` → explicit source path (e.g. `lazygit:~/.config/lazygit`)
  - blank lines and `#` comments are ignored
- **Theme status:** `~/.myenv/theme/current-status.json` (theme name + type) is
  written by the external switcher, not by this repo.

---

## Signals & gotchas

- Each `link` / `restore` **moves** the real config — it is not a copy.
- Existing targets inside the repo are backed up with a `.bak-<timestamp>` suffix.
- Unknown tool → `[ERR] unknown tool: <name> (not in tools.list)`; a config that
  cannot be found or linked → `[ERR]` with the reason.
- Status words: `LINKED`, `STAGED (not linked)`, `NOT LINKED`, `MISSING`.
- The interactive menu accepts one or more space-separated tools; empty = all.
- The password prompt exists **only** in interactive mode.
- **Neovim: one missing tree-sitter parser disables everything for that
  language.** nvim-treesitter gates *all* its modules on
  `parsers.has_parser(lang)` (`configs.lua` → `is_enabled`), so a language that
  is absent from `ensure_installed` in `nvim/lua/plugins/treesitter.lua`
  silently loses highlighting, treesitter indent, and the
  incremental-selection `<CR>` mapping — falling back to regex
  `syntax/<lang>.vim` plus `indent/<lang>.vim`. Check the parser before
  debugging selection, indent, or color for a single language.
- **GTK 4 has `@import`** (verified: GTK 4.22 + swaync 0.12.6 — the imported
  value reached the rendered pixel). `swaync/style.css` therefore carries **no**
  palette literals: it imports
  `/home/rascal/.myenv/theme/current/css/theme.css`, the same file
  `waybar/style.css` and `wlogout/style.css` read. Add colors to the theme,
  never to that stylesheet.
- **`swaync-client -rs` reloads CSS; `-R` only reloads `config.json`.** Both
  flows' `[templates.css]` post_hook already ends with `-rs`.
- **`post_hook` runs through `$SHELL` (fish here), not bash.** Keep hooks
  shell-agnostic: `swaync-client -rs 2>/dev/null || true` is fine, `$?` is a
  fish syntax error and fails the whole hook.
- A missing named color in GTK 4 is **silent** — it falls back to the widget
  default instead of warning. Verify an import by rendering (probe rule +
  pixel), not by grepping logs.

---

## Documentation map

| Document | Read it for |
|---|---|
| `README.md` | user-facing overview: sync usage, tool table, theming summary |
| `matugen/docs/README.md` | index of the theming docs |
| `matugen/docs/MATUGEN_SKILLS.md` | writing/registering/testing matugen templates + verified engine gotchas |
| `matugen/docs/CHEATSHEETS.md` | Material You role vocabulary → UI job mapping |
| `matugen/docs/VOCABULARY.md` | sample `--show-colors` dump; how to read a role table |
| `matugen/docs/PROGRESS.md` | template coverage per tool, per flow |
| `matugen/docs/NVIM_MAPPING.md` | which palette key colors which Neovim highlight group |
| `matugen/templates/kanagawa-dragon-lotus/blueprint/README.md` | every key of the Flow B blueprint JSON |
| `hypr/docs/ROADMAP_V56.md` | unimplemented Hyprland 0.56 features: recipes, verification steps, backlog |
| `eww/bar/README.md` | the Eww bar: `barctl`, settings, adapter, troubleshooting |
| `eww/depth-clock/README.md` | the wallpaper depth clock: `depthctl`, layout knobs, foreground mask |
| `eww/depth-clock/GUIDE.md` | step-by-step build recipe for a new wallpaper |

When behavior changes, update the document that states it — these files are
verified against the repo, so a stale line is a bug.

---

## Setup on a new machine

1. `git clone <repo-url> ~/.dotfile`
2. `bash ~/.dotfile/.synchronizer/.sync.sh link`
3. Ensure `matugen` (4.x) is on `PATH`.
4. Render a theme (Flow A or Flow B) so `~/.myenv/theme/current/…` exists —
   otherwise Neovim and the other consumers run without a generated palette.
