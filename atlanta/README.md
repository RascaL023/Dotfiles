# atlanta

One entry point for desktop actions. It is not a shell or a daemon.
Atlanta routes each capability to the native tool that already owns it 
and keeps only two pieces of state: the wallpaper index and the selected bar provider.

## Usage

```bash
atlanta <capability> <verb> [args...]
atlanta help | status | doctor
```

| Capability | Verbs | Provider |
|---|---|---|
| `launcher` | `apps`, `run`, `window`, `toggle` | `rofi-ctl` |
| `bar` | `show`, `hide`, `toggle`, `restart`, `reload`, `status`, `use`, `switch` | selected provider: `waybar` (default) or `eww` |
| `bar.panel` | `toggle <panel>` | `eww-ctl` → `eww` |
| `notifications` | `toggle`, `dnd`, `clear` | `swaync-client` |
| `screenshot` | `region`, `screen`, `window` | `grim` + `slurp` |
| `session` | `menu`, `lock`, `dpms off`, `dpms on`, `logout`, `reboot`, `poweroff` | `wlogout`, `hyprlock`, `hyprctl`/`niri`, `loginctl` |
| `idle` | `toggle`, `status` | `swayidle` |
| `nightlight` | `toggle`, `status` | `wlsunset` |
| `wallpaper` | `set`, `next`, `prev`, `random`, `pick`, `status` | `awww` |
| `osd` | `volume`, `mic`, `brightness` | `wpctl`, `brightnessctl`, `notify-send` (report only) |
| `volume` | `up`, `down`, `mute` | `wpctl` + OSD |
| `mic` | `toggle` | `wpctl` + OSD |
| `brightness` | `up`, `down` | `brightnessctl` + OSD |

Examples:

```bash
atlanta launcher apps
atlanta bar toggle
atlanta bar use eww
atlanta bar switch waybar
atlanta bar toggle --provider eww
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
| Eww daemon | `eww-ctl daemon start` | `eww-ctl daemon stop` |
| SwayNC | `swaync` | D-Bus PID from `org.erikreider.swaync`, verified through `/proc`, then `SIGTERM` |
| Selected bar | `waybar-ctl start` or `eww-ctl bar island start` | selected provider; Eww's daemon stop also closes the island |

`atlanta stop` stops them in reverse order and is idempotent. It does not
start or stop `swayidle`, `wlsunset`, `hyprlock`, `wlogout`, or `rofi`; those
remain on demand (`atlanta idle toggle`, `atlanta nightlight toggle`, and the
session/launcher verbs). `atlanta start` starts only the selected bar: Waybar by default, or the Eww
island when `bar use eww` is set. The Eww daemon still starts either way because
`bar.panel` and depth-clock use it. `eww-ctl daemon stop` also closes every Eww
window and stops the island collector, so `atlanta stop` leaves no Eww window
behind without a separate island stop. The daemon state comes from `eww-ctl
daemon status`; a timeout or an unreadable answer is `unknown`, so the stop is
still attempted, and `depth-clock` is closed explicitly afterwards in case a
window outlived a failed stop.

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
2. This checkout: `rofi/rofi-ctl`, `waybar/waybar-ctl`, `eww/eww-ctl`,
   `eww/script/depth-ctl`. Waybar and Eww ctls are not necessarily on `PATH`,
   so the repo path wins.
3. `PATH`.

`atlanta doctor` prints the path each name actually resolved to, plus the
session. `atlanta status --check` exits `1` when a provider is missing.

Session detection: `ATLANTA_SESSION`, then `NIRI_SOCKET`, then
`HYPRLAND_INSTANCE_SIGNATURE`, then `XDG_CURRENT_DESKTOP`.

## Choosing the bar

`bar` means the selected status bar, not a provider name. The choice lives in
`$XDG_STATE_HOME/atlanta/bar`; with no state file atlanta uses Waybar.

The two selection verbs do different amounts of work:

- `bar use <waybar|eww>` changes the preference only. It starts and stops
  nothing, so a bar that is already running keeps running.
- `bar switch <provider>` stops the provider recorded in the state file if it
  differs from the new one, saves the choice, then starts the new provider. It
  does not look for any other running bar.

**There is no exclusivity.** `show`, `hide`, `toggle`, `reload`, `restart`, and
`status` also act only on the selected provider. If the choice and the running
bars drift apart, two bars can stay visible: `bar use waybar` while the Eww
island is running leaves the island alone, and a later `bar toggle` adds Waybar.
`atlanta start` and `stop` follow the same rule — they reconcile the selected
bar and the Eww daemon, not a second running bar. `atlanta status` reports only
the selected bar, so check the other provider directly:

```bash
eww-ctl bar island status      # islands, or stopped
waybar-ctl status              # running <pid> <session>, or stopped
```

To move between bars, prefer `bar switch`, which stops the recorded provider
before starting the new one. After drift, stop the unwanted bar explicitly
(`eww-ctl bar island stop` or `waybar-ctl stop`); `bar switch` will not find it
if the state file points at the other provider.

Both providers answer the same verbs through `lib/bar.sh`: `show`, `hide`,
`toggle`, `reload`, `status`, and `restart`. Waybar restarts its process; Eww
reloads the island in place because the island lives on the shared daemon.
`bar show` for Eww starts the daemon when needed and opens the `islands`
window; `bar hide` closes only the island and leaves the daemon and `bar.panel`
windows alone. An unmanaged Eww daemon is never adopted silently: `bar show`
exits `3` with the `eww-ctl daemon restart` hint.

`--provider waybar|eww` overrides the selection for one call without saving it.
`bar.panel` stays independent of the selected bar and still toggles exactly one
Eww window: `profile`, `distro`, `calendar-popup`, or `music-popup`. Any other
name is a usage error (`2`). `islands` is rejected on purpose — the island needs
its collector, so it belongs to `bar show|hide|toggle`. `depth-clock` is
rejected too: its geometry is measured by `depth-ctl` and synced with the
wallpaper.

## State

Atlanta keeps two files under `$XDG_STATE_HOME/atlanta`. `wallpaper` is an index
into the image list of `ATLANTA_WALLPAPER_DIR` (default `~/Pictures/Wallpaper`),
written by `set`, `next`, `prev`, and `random`, and read by `status`. `bar` is
the selected bar provider, written only by `bar use` and `bar switch`. An
unknown value falls back to Waybar with a warning from `status` and `doctor`.

`awww` has no `next`/`prev`, which is why atlanta keeps this index.

Processes atlanta starts (swayidle, wlsunset, wlogout) are tracked by PID file
in `$XDG_RUNTIME_DIR/atlanta-<name>-<uid>.pid` with an ownership and argv check
in `/proc`. No `pgrep`, no `pkill`, no killing by process name.

`idle` and `nightlight` work on both Hyprland and Niri. `idle` runs `swayidle`
with a fixed event list: lock at 5 minutes, display off at 5.5 minutes, suspend
at 10 minutes, and lock before sleep. `nightlight` runs `wlsunset -t 4000`;
without coordinates it resolves to polar night and holds that static
temperature, which matches the old `hyprsunset -t` filter.

Both toggles post one short state bubble (`Idle`, `Night light`) under their
own sync id, so repeated presses replace that capability's message instead of
stacking new ones. `idle resumed` posts the wake message through the same
helper. `notify-send` stays optional: without a notification daemon the toggles
still change state.

DPMS is the only compositor-specific action in that list, so the events call
`atlanta session dpms off|on`; that verb maps to
`hyprctl dispatch 'hl.dsp.dpms({ action = … })'` on Hyprland 0.57+ and
`niri msg action power-off-monitors` / `power-on-monitors` on Niri.
`session lock` works on both because `hyprlock` only needs
`ext-session-lock-v1` and `wlr-screencopy`, which both compositors provide.

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
