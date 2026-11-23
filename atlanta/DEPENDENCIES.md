# atlanta dependencies

atlanta is a bash router. It ships no daemon and no runtime of its own: every
capability delegates to a provider resolved by `lib/provider.sh`. This file is
the install checklist.

## Baseline (always required)

| Dependency | Used for | Minimum |
|---|---|---|
| `bash` | every script; arrays, `mapfile`, `[[ ]]`, process substitution | 4.0 (verified 5.2.37) |
| `coreutils` — `readlink`, `dirname`, `date`, `timeout`, `wc`, `mkdir`, `ln`, `rm` | path resolution, screenshot names, bounded `status`, install/remove links | any GNU/coreutils (verified 9.7) |
| `awk` | parsing `wpctl get-volume` | POSIX awk (verified GNU Awk 5.3.2) |
| `jq` | `screenshot screen` and `screenshot window` parse `hyprctl -j` / `niri msg -j` | 1.6+ (verified 1.7.1) |
| `systemd` — `loginctl`, `systemctl`, `busctl` | session power actions and the SwayNC stop path | any systemd |
| `python3` | tests only, never at runtime | 3.8+ (verified 3.12.12) |

## Capability → provider

| Capability | Binaries | Session | Notes |
|---|---|---|---|
| `launcher` | `rofi-ctl` → `rofi` | any Wayland/X11 | `rofi-ctl` resolves from this checkout |
| `bar` | `waybar-ctl` → `waybar` | any | `waybar-ctl` resolves from this checkout |
| `start`/`stop` | `awww-daemon`, `awww`, `eww`, `swaync`, `swaync-client`, `waybar-ctl`, `busctl` | any | mirrors Hyprland autostart; SwayNC is stopped through its D-Bus owner |
| `bar.panel` | `eww` | any | reserved; exits `3` |
| `notifications` | `swaync-client` + running `swaync` | any | daemon must already be running |
| `screenshot region` | `grim`, `slurp` | wlroots screencopy | works on Hyprland and Niri |
| `screenshot screen` | `grim`, `jq` + `hyprctl`/`niri` | any | focused output via compositor |
| `screenshot window` | `grim`, `jq`, `hyprctl` | Hyprland only | exits `3` elsewhere |
| `session menu` | `wlogout` | any | tracked by PID file |
| `session lock` | `hyprlock` | Hyprland, Niri | exits `3` elsewhere |
| `session logout` | `loginctl` | systemd-logind | `terminate-user` |
| `session reboot/poweroff` | `systemctl` | systemd | |
| `idle` | `swayidle` | Hyprland, Niri | exits `3` elsewhere |
| `nightlight` | `wlsunset` | Hyprland, Niri | static `-t`, no coordinates |
| `wallpaper` | `awww` + running daemon | any | `awww init` starts it when missing |
| `wallpaper` depth sync | `depth-ctl` (optional) | any | best-effort, from this checkout |
| `osd`, `volume`, `mic` | `wpctl` (WirePlumber) | any | parses `Volume: 0.65 [MUTED]` |
| `brightness` | `brightnessctl` | any | `get` and `max` |
| OSD feedback | `notify-send` + running notification daemon | any | SwayNC owns the bubble |
| `theme` | none | — | deferred; matugen stays outside |

Providers resolved from this checkout — `rofi-ctl`, `waybar-ctl`, `barctl`,
`matugen-ctl`, `depth-ctl` — do **not** need to be on `PATH`. `install.sh` only
links `atlanta` itself and its fish completion.

## Notification and OSD chain

`notify-send` needs a running implementation of
`org.freedesktop.Notifications`; here that is SwayNC. atlanta never starts it,
so on a machine without SwayNC the OSD is silently skipped (the notify call is
`2>/dev/null || :`). `notifications toggle`, `notifications dnd`, and `notifications clear` also need
`swaync-client`.

## Session support

| Capability | Hyprland | Niri |
|---|---|---|
| launcher, bar, notifications, wallpaper, volume, mic, brightness, osd | yes | yes |
| screenshot region / screen | yes | yes |
| screenshot window | yes | no (`3`) |
| session menu, logout, reboot, poweroff | yes | yes |
| session lock, session dpms | yes | yes |
| idle | yes | yes |
| nightlight | yes | yes |

Session detection: `ATLANTA_SESSION` → `NIRI_SOCKET` → `HYPRLAND_INSTANCE_SIGNATURE`
→ `XDG_CURRENT_DESKTOP`.

## Environment

| Variable | Default | Purpose |
|---|---|---|
| `ATLANTA_SESSION` | auto | force `hyprland` / `niri` |
| `ATLANTA_PROVIDER_DIR` | unset | extra provider directory checked first (tests) |
| `ATLANTA_WALLPAPER_DIR` | `~/Pictures/Wallpaper` | image list for `wallpaper` |
| `ATLANTA_SCREENSHOT_DIR` | `~/Pictures/Screenshots` | screenshot output |
| `ATLANTA_VOLUME_STEP` | `0.05` | volume step |
| `ATLANTA_BRIGHTNESS_STEP` | `5%` | backlight step |
| `ATLANTA_NIGHTLIGHT_TEMP` | `4000` | `wlsunset -t` (static low temperature) |
| `XDG_RUNTIME_DIR` | — | PID files for tracked processes |
| `XDG_STATE_HOME` | `~/.local/state` | wallpaper index |

## NixOS install

```nix
environment.systemPackages = with pkgs; [
  bash coreutils gawk jq
  wireplumber brightnessctl libnotify
  grim slurp
  rofi waybar swaynotificationcenter wlogout
  hyprland hyprlock
  niri awww
  swayidle wlsunset
  # optional
  eww matugen
  python3  # tests only
];
```

`hyprctl` ships with `hyprland`, `wpctl` with `wireplumber`, and `notify-send`
with `libnotify`.

Other distributions: the same names are packaged as `bash`, `coreutils`,
`gawk`, `jq`, `wireplumber`, `brightnessctl`, `libnotify`, `grim`, `slurp`,
`rofi`, `waybar`, `swaync`, `wlogout`, `hyprland`, `hyprlock`, `swayidle`,
`wlsunset`, `niri`, `awww`; `eww` and `matugen` are optional.

## Verified on this machine

| Binary | Path | Version |
|---|---|---|
| `bash` | `/run/current-system/sw/bin/bash` | 5.2.37 |
| `jq` | `/run/current-system/sw/bin/jq` | 1.7.1 |
| `awk` | `/run/current-system/sw/bin/awk` | GNU Awk 5.3.2 |
| `timeout` | `/run/current-system/sw/bin/timeout` | coreutils 9.7 |
| `wpctl` | `/run/current-system/sw/bin/wpctl` | (no `--version`) |
| `brightnessctl` | `/run/current-system/sw/bin/brightnessctl` | 0.5 |
| `notify-send` | `/run/current-system/sw/bin/notify-send` | 0.8.6 |
| `grim` / `slurp` | `/run/current-system/sw/bin/…` | (no `--version`) |
| `swaync-client` | `/run/current-system/sw/bin/swaync-client` | 0.12.6 |
| `wlogout` | `/run/current-system/sw/bin/wlogout` | installed |
| `hyprctl` | `/run/current-system/sw/bin/hyprctl` | installed |
| `hyprlock` | `/run/current-system/sw/bin/hyprlock` | 0.9.7 |
| `swayidle` / `wlsunset` | `/home/rascal/.nix-profile/bin/…` | 1.9.1 / 0.4.0 |
| `niri` | `/run/current-system/sw/bin/niri` | 26.04 |
| `awww` | `/home/rascal/.nix-profile/bin/awww` | 0.12.1 |
| `rofi` / `waybar` | `/run/current-system/sw/bin/…` | installed |
| `eww` | `/run/current-system/sw/bin/eww` | 0.6.0 |
| `matugen` | `/run/current-system/sw/bin/matugen` | 4.2.0 |

All currently used dependencies are present on this machine; nothing is missing
for the implemented verbs.

## Deliberately not dependencies

- **Noctalia** — never called. atlanta is its own shell.
- **hyprpicker** — installed (0.4.7) but no `picker` verb exists yet.
- **matugen** — `atlanta theme` is deferred; theming stays outside.
- **eww** — only `bar.panel` (reserved) and the optional depth-clock sync use it.
- **light**, **swaylock**, **wl-copy** — not used.
- **hypridle**, **hyprsunset** — replaced by `swayidle` and `wlsunset`; the old
  Hyprland autostart scripts outside atlanta are not managed here.

## Checks

```bash
atlanta doctor                 # path of every provider + session
atlanta status --check         # exit 1 if a required provider is missing
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s atlanta/tests
```

`doctor` and `status` verify presence, not format. The parsers assume:

- `wpctl get-volume` prints `Volume: 0.65` or `Volume: 0.65 [MUTED]`
- `brightnessctl get` / `max` print integers
- `waybar-ctl status` prints `running <pid> <session>` or nothing
- `awww` accepts `query`, `init`, and `img` with `--transition-*` flags
