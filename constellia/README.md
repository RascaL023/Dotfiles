# constellia

One entry point that answers one question — *which shell is active on this
WM?* — and then routes each capability to the tool that owns it. It is not a
daemon, a bar, or a replacement for `atlanta`, `rofi-ctl`, `eww-ctl`,
`noctalia-ctl`, or `matugen-ctl`.

A **shell** is the set of desktop surfaces that must not be doubled: bar,
notification daemon, OSD, lock screen, wallpaper engine. `atlanta` and
`noctalia` are the two shells. The choice is **per WM**: Hyprland can run
noctalia while niri runs atlanta on the same machine.

Design and contract: `docs/DESIGN.md`.

## Status

Implemented: per-WM shell state, `shell use|select|switch|start|stop|status`, the
capability matrix, `theme palette`/`theme status`/`feel`, `status`, `doctor`,
`--dry-run`, install and completions.

Autostart in both WMs now goes through `constellia shell start`
(`hypr/config/core/autostart.lua`, `niri/conf/core/autostart.kdl`). Still
pending (phase 6): the keybind migration in `hypr/` and `niri/`.
`current-status.json` is no longer written;
`constellia theme status [--json]` reports on demand instead.

## Install

```bash
constellia/install.sh --dry-run   # show the two links
constellia/install.sh             # ~/.local/bin/constellia + fish completion
constellia/install.sh --remove    # remove only links back into this checkout
```

`BIN_DIR` and `FISH_COMPLETION_DIR` move the destinations.

## Usage

```bash
constellia <capability> <verb> [args...]
constellia shell use|select|switch|start|stop|status
constellia status | doctor | help
```

| Capability | Verbs | atlanta | noctalia |
|---|---|---|---|
| `launcher` | `apps`, `run`, `window`, `toggle` | `rofi-ctl` | `panel-toggle launcher`, `window-switcher` |
| `notifications` | `toggle`, `dnd [on\|off]`, `clear` | `swaync-client` | `panel-toggle control-center notifications`, `notification-dnd-*`, `notification-clear-active` |
| `screenshot` | `region`, `screen`, `window`, `annotate` | `atlanta screenshot` | `screenshot-*` |
| `wallpaper` | `set`, `next`, `prev`, `random`, `pick`, `status` | `atlanta wallpaper` | `wallpaper-*`; `pick` opens `panel-toggle wallpaper` |
| `session` | `lock`, `menu`, `logout`, `reboot`, `poweroff`, `dpms off\|on` | `atlanta session` | `session *`, `dpms-*`, `panel-toggle session` |
| `idle` | `toggle`, `status` | `atlanta idle` | unsupported |
| `caffeine` | `toggle`, `status` | unsupported | `caffeine-toggle`; `status` unsupported |
| `nightlight` | `toggle`, `status` | `atlanta nightlight` | `nightlight-force-toggle`; `status` unsupported |
| `volume` | `up`, `down`, `mute` | `atlanta volume` | `volume-*` |
| `mic` | `toggle` | `atlanta mic` | `mic-mute` |
| `brightness` | `up`, `down` | `atlanta brightness` | `brightness-*` |
| `bar` | `show`, `hide`, `toggle`, `status`, `use`, `switch` | `atlanta bar` | `bar-*`, `status`; `use`/`switch` unsupported |
| `bar.panel` | `toggle <panel>` | `atlanta bar.panel` | unsupported |
| `osd` | `volume`, `mic`, `brightness` | `atlanta osd` | unsupported |
| `theme` | `palette [source] [options]`, `status [--json]` | `matugen-ctl palette` | `noctalia-ctl palette` |
| `feel` | `<profile>` | `matugen-ctl feel --wm` | same: feel always belongs to matugen |

Examples:

```bash
constellia notifications toggle
constellia launcher apps
constellia volume up
constellia wallpaper next
constellia theme palette ~/Pictures/Wallpaper/moon.png
constellia theme status --json
constellia feel default
constellia shell switch noctalia
constellia --dry-run screenshot region
constellia status --json
```

### Options

| Option | Effect |
|---|---|
| `--dry-run`, `CONSTELLIA_DRY_RUN=1` | Print `[dry] <argv>` and run nothing |
| `--wm hypr\|niri` | Override WM detection (`CONSTELLIA_WM` / `CONSTELLIA_SESSION` also work) |
| `--json` | JSON output for `status` and `doctor` |
| `-h`, `--help` | Usage |

Options are read until the capability; after it, `-` arguments belong to the
verb (`constellia bar status --provider eww`).

### Exit codes

| Code | Meaning |
|---|---|
| `0` | ok |
| `1` | failed, or the shell is not running |
| `2` | usage |
| `3` | unsupported on the active shell, or WM `unknown` |
| `4` | `shell switch` refused before starting anything (notification bus still owned) |
| `127` | a backend is missing |

## Shell state

```text
${XDG_STATE_HOME:-$HOME/.local/state}/constellia/
├── shell/
│   ├── hypr      # "noctalia" or "atlanta"
│   └── niri      # independent
└── theme         # variant=dark, updated=<epoch>
```

One word plus newline, written atomically with one rename. A missing file means
`atlanta` (the stack this repo starts without constellia); an unknown value is
also `atlanta`, flagged `state-invalid` by `status` and `doctor`. Nothing is
copied from atlanta: its wallpaper index and bar provider stay its own.

`shell use <shell>` changes the preference for this WM only. `shell switch`
stops the other stack, starts the target, proves it answers, and only then
writes state. `shell start`/`stop` act on the recorded shell, never switch
silently, and never write state.

`shell select` is the interactive front end: it opens `rofi-ctl shell` (the two
Noctalia / Native cards) with the active shell highlighted, waits for rofi to
exit, maps `Noctalia`→`noctalia` and `Atlanta`→`atlanta` (the older `Native`
label is still accepted), then runs the same
`shell switch` path. Cancelling (`Esc`, rofi exit 1) is a success that changes
nothing; selecting the recorded shell prints `already` and does nothing. Rofi
handles presentation only — `rofi-ctl` never learns about shells.

`switch` to noctalia runs, in order: `atlanta stop` → wait for
`org.freedesktop.Notifications` to be free (3 s) → `noctalia -d` → poll
`noctalia msg status` (10 s) → write state. If the bus is still owned the
switch exits `4` with the owner PID. If noctalia is already running (hybrid
session), the leftover atlanta stack is stopped and the daemon is adopted
instead of refusing the switch.

`switch` to atlanta sends `SIGTERM` to `(^|/)noctalia$`, polls 5 s, then
`SIGKILL`, then starts atlanta. The match is argv0-based because the Nix
wrapper's `comm` is `.noctalia-wrapp`, and it accepts both `noctalia` (session
start) and an absolute path (`noctalia -d` daemonizes that way). Liveness and
drift use the same pattern; the atlanta stack is matched by argv0 too, since
its `comm` is `.eww-wrapped`.

Timing knobs, mainly for tests: `CONSTELLIA_BUS_TIMEOUT_MS` (3000),
`CONSTELLIA_NOCTALIA_TIMEOUT_MS` (10000), `CONSTELLIA_STOP_TIMEOUT_MS` (5000).

## Theme and feel

`constellia theme palette <source>` picks the engine from the shell:
`matugen-ctl palette` on atlanta, `noctalia-ctl palette` on noctalia. Both write
the same `theme/palette/current`, so switching shells does not require a
re-render. Options (`--list`, `-n`, `-s`, `--from-shell`, consumer names) pass
through unchanged.

`theme status` derives everything it can instead of storing it:

| Fact | Source |
|---|---|
| engine, palette | `readlink theme/palette/current` → `generated/<engine>/<name>` |
| feel | `readlink theme/feel/current` → `generated/<profile>` |
| variant | `constellia/theme` (`variant=dark`), written only after a successful render with a source |

`theme status --json` prints `{engine, palette, variant, feel, wm, shell}`;
fields are `null` when the store is missing. A blueprint name ending in
`-dark`/`-light` sets the variant; an image defaults to `dark`. A reload
(`theme palette` with no source), `--list`, or `-n` writes nothing.

`constellia feel <profile>` always calls `matugen-ctl feel <profile> --wm <wm>`.
Feel is not mapped onto Noctalia: its own radius/font/shadow settings stay in
Noctalia's `settings.toml`.

## Delegation

The atlanta side delegates to `atlanta` instead of re-implementing it: it owns
the wallpaper index, the tracked `swayidle`/`wlsunset`/`wlogout` processes, and
the SwayNC OSD bubble. `CONSTELLIA_SCREENSHOT_DIR` is forwarded as
`ATLANTA_SCREENSHOT_DIR` for `screenshot`.

The noctalia side calls `noctalia msg …` directly. Those commands need a
running shell; a dead daemon fails with its own message and there is no silent
fallback to atlanta.

Backend lookup: `$CONSTELLIA_BACKEND_DIR/<name>`, then this checkout
(`../atlanta`, `../rofi`, `../noctalia`, `../matugen`), then `PATH`. `noctalia`
is never taken from the checkout.

## Known caveats

Panel ids were verified against Noctalia 5.4.1 on a live niri session:
`control-center notifications`, `launcher` (context `/` starts run mode),
`wallpaper`, and `session`. An unknown id makes `noctalia msg panel-toggle`
fail with the available id list, and constellia forwards that failure instead
of falling back.

## Tests

```bash
python3 -m unittest discover -s constellia/tests -p 'test_*.py'
```

Every backend is a fake in a temporary directory, so no compositor, Noctalia,
atlanta, or D-Bus is required. The suite covers the capability matrix, state
per WM, switch ordering and failure paths, `shell select` (choice, cancel,
unknown label, active shell), idempotency, dry-run, JSON output, theme
derivation and palette routing, and the installer.
