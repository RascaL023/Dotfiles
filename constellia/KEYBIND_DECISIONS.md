# Constellia keybinding decisions

The first pass of the #13 keybinding migration is in place: hypr and niri now
call `constellia` for bar, notifications, session, capture, volume and mic. The
items below were left untouched because they change behaviour, not just the
entry point. Each one lists the options and a recommendation; none of them is
implemented yet.

Branch: `feat/constellia-keybinds`.

## 1. Brightness OSD on Noctalia

`constellia brightness up|down` changes the backlight on both shells. On
atlanta it also shows the OSD; on noctalia it runs `noctalia msg
brightness-up|down`. `constellia osd brightness` stays unsupported because
`noctalia msg brightness-osd` requires a numeric value, unlike `volume-osd` and
`mic-volume-osd`.

- **A. Accept the gap** — migrate the brightness bindings as they are; atlanta
  keeps its OSD, noctalia shows whatever `brightness-up|down` reports (needs a
  live check; it may already draw its own OSD).
- **B. Plumb the value** — add `constellia osd brightness <value>` and have the
  binding compute the percentage with `brightnessctl g/m`. This changes the osd
  contract, which is currently report-only with no arguments.
- **C. Keep the direct binding** — leave `brightnessctl` in the binding until
  noctalia exposes a value-less brightness OSD.

Recommendation: **A** if the live check shows noctalia already draws its own
brightness OSD, otherwise **B**.

## 2. Idle vs caffeine

`constellia idle toggle` is atlanta-only (swayidle/hypridle). Noctalia schedules
idle and lock internally and has no equivalent command; its closest surface is
`caffeine toggle`, which inhibits idle instead of disabling the idle daemon.

- **A. No-op on noctalia** — migrate `Mod+I` to `constellia idle toggle`; it
  exits 3 under noctalia and the chord does nothing there.
- **B. Dispatch to caffeine** — make `constellia idle toggle` map to
  `caffeine toggle` on noctalia. One chord, but "idle disabled" becomes
  "idle inhibited".
- **C. Separate chord** — keep `Mod+I` atlanta-only and add a distinct
  `constellia caffeine toggle` binding for noctalia.

Recommendation: **A** for this PR; choose **C** if a keep-awake chord is wanted
on both shells.

## 3. Wallpaper picker side effects

Today `Mod+W` runs `nextwall.sh` on niri, which also calls `depth-ctl wallpaper`
to sync the Eww depth clock, and `launcher.pick_wallpaper()` on hypr, which arms
a layer-animation override before opening rofi. `constellia wallpaper pick`
opens the atlanta gallery / noctalia wallpaper panel but does neither.

- **A. Keep the scripts** — no migration; the picker stays provider-specific.
- **B. Move the side effects behind atlanta** — put the depth-clock sync in
  atlanta's `wallpaper pick`, keep the hypr animation override in the hypr
  adapter, then migrate the binding to `constellia wallpaper pick`.
- **C. Migrate as-is** — one entry point, depth clock and animation override
  are lost.

Recommendation: **B** if the depth clock matters, otherwise **C**.

## 4. Theme picker

`Mod+T` calls `~/.myenv/script/theme/theme-picker.sh`, a legacy stub in the
external theme store, not managed by this repo. Constellia has
`theme palette`/`theme status` but no picker.

- **A. Remove the binding** — it points at a stub.
- **B. Keep it** — leave the chord reserved until a picker exists.
- **C. Add `constellia theme pick`** — rofi list of palettes/engines, then
  `theme palette` and `feel` through constellia.

Recommendation: **C** later, **B** for now.

## 5. Eww daemon restart

`Mod+Ctrl+X` runs `eww-ctl daemon restart` directly. Constellia's `bar restart`
reloads the island in place, not the daemon, so there is no exact capability.

- **A. Leave it atlanta-only** — the chord only makes sense when eww owns the
  bar.
- **B. Add `bar daemon restart`** — a new atlanta/constellia capability.
- **C. Map to `bar restart`** — closest existing verb, but does not restart the
  daemon.

Recommendation: **A**; revisit only if the daemon needs restarting from a
binding.

## 6. Nightlight backend

`Mod+Shift+N` runs a local script that toggles `hyprsunset`. Atlanta's
`nightlight` capability uses `wlsunset`; noctalia uses
`nightlight-force-toggle`. Migrating the chord would switch the atlanta path
from `hyprsunset` to `wlsunset`.

- **A. Keep `hyprsunset`** — no migration, two backends stay in the repo.
- **B. Migrate to `constellia nightlight toggle`** — one entry point, but
  atlanta's Hyprland path changes tool.
- **C. Teach atlanta to choose** — `hyprsunset` under Hyprland, `wlsunset`
  elsewhere, then migrate the binding.

Recommendation: **C** for one entry point without changing today's behaviour.

## 7. PR closure

The keybinding PR should close #13 only if it lands after the lifecycle work
(already merged via #36). The deferred items above can either stay out of that
PR or be included once decided.

- **A. Close #13 with the current migration** — remaining decisions become
  follow-up issues.
- **B. Hold `Closes #13`** until every item above is decided and implemented.

Recommendation: **A**, with this document as the follow-up list.
