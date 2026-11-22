# atlanta

One entry point for desktop actions. Atlanta routes each capability to the
native tool that already owns it (Rofi, Waybar, SwayNC, grim, hypridle,
hyprsunset, awww) and keeps only one piece of state itself: the wallpaper index.

It is not a shell, a daemon, or a theme engine. Noctalia and matugen stay where
they are; `atlanta theme` is deliberately unimplemented.

## Usage

```bash
atlanta <capability> <verb> [args...]
atlanta help | status | doctor
```

| Capability | Verbs | Provider |
|---|---|---|
| `launcher` | `apps`, `run`, `window`, `toggle` | `rofi-ctl` |
| `bar` | `show`, `hide`, `toggle`, `restart`, `reload`, `status` | `waybar-ctl` |
| `bar.panel` | `toggle <panel>` | Eww — reserved, not active |
| `notifications` | `toggle`, `dnd`, `clear` | `swaync-client` |
| `screenshot` | `region`, `screen`, `window` | `grim` + `slurp` |
| `session` | `menu`, `lock`, `logout`, `reboot`, `poweroff` | `wlogout`, `hyprlock`, `loginctl` |
| `idle` | `toggle`, `status` | `hypridle` |
| `nightlight` | `toggle`, `status` | `hyprsunset` |
| `wallpaper` | `set`, `next`, `prev`, `random`, `pick`, `status` | `awww` |
| `osd` | `volume`, `mic`, `brightness` | `wpctl`, `brightnessctl`, `notify-send` (report only) |
| `volume` | `up`, `down`, `mute` | `wpctl` + OSD |
| `mic` | `toggle` | `wpctl` + OSD |
| `brightness` | `up`, `down` | `brightnessctl` + OSD |

Examples:

```bash
atlanta launcher apps
atlanta bar toggle
atlanta notifications clear
atlanta screenshot region
atlanta wallpaper next
atlanta session menu
atlanta volume up
atlanta mic toggle
atlanta status
```

`volume`, `mic`, and `brightness` perform the change and then report through
the same SwayNC bubble (`x-canonical-private-synchronous:atlanta-osd`), so
holding a media key replaces one bubble instead of stacking notifications. `osd`
only reports and never mutates. Steps default to `0.05` for volume
(`ATLANTA_VOLUME_STEP`) and `5%` for brightness (`ATLANTA_BRIGHTNESS_STEP`).

Exit codes: `0` ok, `1` failed or not running, `2` usage, `3` unsupported in
this session, `127` a provider is missing.

## Start and stop

`atlanta start` starts the same stack as the Hyprland autostart, in this order:

| Component | Start | Stop |
|---|---|---|
| `awww-daemon` | `awww-daemon` | `awww kill` |
| Eww root (`profile`, `distro`, `depth-clock`) | `eww --config eww daemon --force-wayland` | `eww --config eww kill` |
| SwayNC | `swaync` | D-Bus PID from `org.erikreider.swaync`, verified through `/proc`, then `SIGTERM` |
| Waybar | `waybar-ctl start` | `waybar-ctl stop` |

`atlanta stop` stops them in reverse order and is idempotent. It does not
start or stop `hypridle`, `hyprsunset`, `hyprlock`, `wlogout`, or `rofi`; those
remain on demand (`atlanta idle toggle`, `atlanta nightlight toggle`, and the
session/launcher verbs). The Eww bar in `eww/bar` is not started here; that is
still the one-server work.

For a Hyprland autostart, the equivalent replacement is:

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("$HOME/.dotfile/atlanta/atlanta start")
end)
```

This is documentation only; `hypr/` is not modified by atlanta. `atlanta stop`
is the atlanta side of a future Noctalia/atlanta shell switch. Noctalia itself
is not started or stopped yet; `noctalia -d` starts its daemon, but the handoff
needs a verified stop path.

## Providers

Resolution order:

1. `$ATLANTA_PROVIDER_DIR/<name>` — tests and out-of-tree overrides.
2. This checkout: `rofi/rofi-ctl`, `waybar/waybar-ctl`, `eww/bar/barctl`,
   `matugen/matugen-ctl`, `eww/script/depth-ctl`. Waybar and Eww ctls are not
   necessarily on `PATH`, so the repo path wins.
3. `PATH`.

`atlanta doctor` prints the path each name actually resolved to, plus the
session. `atlanta status --check` exits `1` when a provider is missing.

Session detection: `ATLANTA_SESSION`, then `NIRI_SOCKET`, then
`HYPRLAND_INSTANCE_SIGNATURE`, then `XDG_CURRENT_DESKTOP`.

## Waybar first

`bar` routes to Waybar only. The provider branch is one `case` in
`verbs/bar.sh` plus a slot in `lib/provider.sh`, so adding another bar later
means filling that branch — no reshaping of the dispatcher or the keybinds.

`bar.panel` is reserved for that second provider and exits `3` today. Eww's
depth clock still works through `eww/script/depth-ctl`.

## State

The only state is `$XDG_STATE_HOME/atlanta/wallpaper`, an index into the image
list of `ATLANTA_WALLPAPER_DIR` (default `~/Pictures/Wallpaper`). It is written
by `set`, `next`, `prev`, and `random`, and read by `status`.

`awww` has no `next`/`prev`, which is why atlanta keeps this index.

Processes atlanta starts (hypridle, hyprsunset, wlogout) are tracked by PID file
in `$XDG_RUNTIME_DIR/atlanta-<name>-<uid>.pid` with an ownership and argv check
in `/proc`. No `pgrep`, no `pkill`, no killing by process name.

`idle` and `nightlight` are Hyprland-only; on Niri they exit `3` instead of
launching a tool that cannot work. `session lock` works on both Hyprland and
Niri because `hyprlock` only needs `ext-session-lock-v1` and
`wlr-screencopy`, which both compositors provide.

## Install

```bash
bash atlanta/install.sh --dry-run
bash atlanta/install.sh
bash atlanta/install.sh --remove
```

Links `atlanta` into `~/.local/bin` and the fish completion into
`~/.config/fish/completions`. The full install checklist is in
[`DEPENDENCIES.md`](DEPENDENCIES.md). `BIN_DIR` and `FISH_COMPLETION_DIR` override the
destinations. Atlanta has no config directory, so it is not in `tools.list`.

## Tests

```bash
bash -n atlanta/atlanta atlanta/lib/*.sh atlanta/verbs/*.sh atlanta/install.sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s atlanta/tests -v
```

Tests copy `atlanta/` to a temporary directory and replace every provider with a
recording fake, so they need no compositor, bar, or notification daemon.
