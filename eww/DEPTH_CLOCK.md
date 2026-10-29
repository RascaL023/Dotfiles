# Task: Implement Dynamic Depth Wallpaper Clock using Eww

## Context

Repository: `~/.dotfile`

GitHub reference: https://github.com/RascaL023/Dotfiles/tree/dev

Target branch: `dev`

Wallpaper: `~/Pictures/Wallpaper/Nyx Bright.png`

Desktop environments: Niri and Hyprland (Wayland).

Available tools: Eww, awww, FFmpeg, Matugen.

**Objective:** Implement a lightweight, dynamic depth wallpaper clock using Eww, completely independent of Quickshell, Noctalia, and compositor-specific APIs.

Do not merely provide a design or code snippets. Implement the feature in the existing dotfiles, validate it, and test the resulting window wherever the local environment permits.

## 1. Read repository conventions first

Before making changes, inspect:

- `AGENTS.md`
- `README.md`
- `eww/eww.yuck`
- `eww/eww.scss`
- `eww/bar/README.md`
- `matugen/config.toml`
- `matugen/templates/general/source.scss`
- `matugen/templates/kanagawa-dragon-lotus/template/source.scss`
- `matugen/docs/MATUGEN_SKILLS.md`
- `hypr/sources/scripts/nextwall.sh`
- Current Niri and Hyprland configurations

Respect all existing repository rules.

Important observations from branch `dev`:

- Eww main config already imports `~/.myenv/theme/current/scss/theme`.
- Matugen already produces semantic SCSS color tokens.
- The project supports wallpaper-derived and fixed-palette themes.
- `eww/bar` uses a separate Eww configuration and controller.
- Existing Eww windows must not be broken.

Edit files only inside `~/.dotfile`. Do not edit generated Matugen output or symlinked config copies directly.

Do not run `.synchronizer/.sync.sh`, commit, push, or overwrite user configuration unnecessarily.

## 2. Target appearance

Use the reference image supplied with this task as the visual target.

The reference has:

- An oversized cinematic digital clock displaying `12:00`.
- Large, elegant, relatively narrow numerals across the upper-middle desktop.
- A character positioned in front of the central portion of the clock.
- Parts of the numerals hidden behind the character's silhouette.
- A subtle dark offset shadow behind the clock text for dimensionality.
- A completely transparent widget background.
- An existing top status bar that remains unobstructed.

Reproduce the **composition and depth effect**, not the exact colors or characters.

Use the actual `Nyx Bright.png` wallpaper as the image source. Do not use the reference screenshot as the wallpaper.

The clock must show the real local time in `HH:MM`, not a static `12:00`.

Layout should adapt to the actual wallpaper composition, display resolution, and output scaling. Do not assume the reference screenshot has the same dimensions as the physical monitor.

## 3. Rendering architecture

Use three conceptual layers:

1. Background: original wallpaper displayed using awww.
2. Middle: live Eww clock rendered over the wallpaper.
3. Foreground: transparent PNG containing the selected subject, displayed above the Eww clock.

Implement the clock and PNG as children of one Eww `overlay` widget.

The Eww `overlay` must draw the clock first and the foreground image afterward.

**Critical:** The foreground PNG stays static while the clock text updates. Do not regenerate the wallpaper or foreground PNG when the clock changes.

Use the Wayland bottom layer with no exclusive zone, so normal application windows remain above the depth clock.

Preserve the existing top bar and other shell components.

Investigate pointer/input behavior: `focusable "none"` does not by itself guarantee mouse click-through. Avoid large input-blocking surfaces where possible, and test the behavior.

## 4. Foreground generation

Inspect:

`~/Pictures/Wallpaper/Nyx Bright.png`

Determine:

- Original image dimensions.
- Actual wallpaper scaling/cropping used by awww.
- Foreground subject appropriate for masking.
- Expected position and size of the foreground relative to the clock.

Generate a transparent PNG containing only the subject region that should appear in front of the clock.

Requirements:

- Preserve alpha transparency.
- Preserve the original subject's position.
- Avoid visible outlines or halos.
- Ensure accurate alignment with the original wallpaper.
- Prefer cropping the transparent foreground to the relevant region to reduce memory usage.
- Do not resize independently in a way that causes foreground/background misalignment.
- Avoid putting the entire original wallpaper into the foreground image.

Use an already available segmentation or image-editing tool when possible. FFmpeg may be used for cropping, scaling, and format conversion, but do not assume FFmpeg can automatically segment a complex subject.

If automatic segmentation is unavailable or produces visibly incorrect results, report the limitation clearly. Do not fabricate a successful mask. Provide a reproducible manual correction workflow if needed.

Foreground extraction is an offline/preprocessing operation, not a continuously running background task.

Store generated assets in a suitable cache or asset location following repository conventions. Do not commit large generated images without necessity.

## 5. Eww implementation

Prefer extending the existing Eww main configuration rather than creating another Eww instance.

Suggested structure (adjust if the repository conventions indicate a better arrangement):

```text
eww/
├── eww.yuck
├── eww.scss
├── windows/
│   └── depth-clock.yuck
├── styles/
│   └── _depth-clock.scss
└── scripts/
    └── depthctl
```

Use namespaced variables and CSS classes to avoid conflicts with existing widgets.

Requirements:

- Real local clock in 24-hour `HH:MM` format.
- Clock refresh aligned closely with minute changes, without unnecessarily frequent polling.
- No repeated image processing during clock updates.
- Transparent background.
- Configurable clock position, font size, and geometry.
- Clock and foreground aligned in the same coordinate space.
- No screen-space reservation.
- No duplicate Eww daemon.
- No conflicts with `eww/bar/barctl`.
- Clean start, stop, and reload behavior.
- Reuse existing Eww infrastructure when possible.

Verify Eww syntax against the locally installed version before implementing. The repo's bar documentation targets Eww 0.6.0, but check the actual runtime version.

Avoid introducing a complex script framework for what can be expressed directly in Yuck and SCSS.

## 6. Mandatory Matugen integration

**Matugen is the existing centralized color authority. Do not create another color-generation system.**

The repository supports two flows:

Flow A: wallpaper-derived Material You.

Flow B: fixed palette (`kanagawa-dragon-lotus`).

Both already generate semantic SCSS tokens and expose the active theme through:

`~/.myenv/theme/current/scss/theme`

The existing `eww/eww.scss` already imports that theme.

The depth clock must consume these existing semantic tokens.

Examples of available tokens:

- `$primary-accent`
- `$secondary-accent`
- `$text-primary`
- `$text-secondary`
- `$layer-base`
- `$layer-lowest`
- `$background`
- `$foreground`

Use the appropriate semantic token for the clock foreground and its shadow.

For example, the clock color may use `$primary-accent` while the text shadow uses a darker existing token with an opacity adjustment.

Do not copy literal hex values from the reference screenshot.

Do not hardcode separate palettes for wallpaper-derived and fixed themes.

Do not introduce a new JSON palette, color extraction process, or redundant Matugen template unless technically necessary.

Keep color, layout, and behavior responsibilities separate:

- Matugen owns the palette.
- Eww SCSS owns visual presentation.
- Eww Yuck owns the widget structure.
- Wallpaper preprocessing owns the foreground mask.

Reusing current tokens is preferred over changing Matugen templates.

Verify that switching between both existing Matugen flows results in correct clock colors. Investigate how the active Eww stylesheet is reloaded when the theme changes.

If a reload integration is missing, implement the smallest safe solution following the existing theme-switch workflow. Do not modify the external theme switcher blindly.

Do not force regeneration of a wallpaper-derived palette merely because the depth wallpaper changes. The selected visual wallpaper and active color theme must be allowed to remain independent.

## 7. Layout and geometry

Detect the actual target display and compositor.

The repository includes Niri output configurations for `LVDS-1` and `HDMI-A-1`. Verify the active outputs instead of assuming a particular monitor index.

Implement the initial layout on the active target output.

Aim for:

- Large clock occupying much of the horizontal space.
- Clock located in the upper-middle portion of the wallpaper.
- Subject overlapping the central clock digits.
- Adequate spacing beneath the existing top bar.
- Crisp foreground boundaries.
- Readability without solid background panels.

Choose a suitable installed font after inspecting available fonts. The reference uses expressive, large numerals; the current Monocraft widget font is not necessarily appropriate for this particular clock.

Clock geometry and positioning should be adjustable without modifying generated palette files.

If necessary, provide a small set of documented layout parameters rather than hardcoding unrelated coordinates throughout the implementation.

## 8. Wallpaper switching

The current wallpaper selector is:

`hypr/sources/scripts/nextwall.sh`

Inspect its actual behavior before modifying it.

For the initial implementation, ensure that:

`~/Pictures/Wallpaper/Nyx Bright.png`

works correctly with its corresponding foreground.

When the wallpaper changes:

- Do not leave the Nyx foreground floating over an unrelated wallpaper.
- If the new wallpaper has no foreground mask, hide or disable the depth layer safely.
- Avoid unnecessary segmentation on every wallpaper change.
- Keep original awww transitions functional.
- Handle filenames containing spaces.
- Avoid modifying Niri or Hyprland configuration unless genuinely necessary.

If integrating directly with the wallpaper selector adds too much coupling, implement a minimal reusable `depthctl` command that the selector can invoke.

Do not refactor the entire wallpaper-management system as part of this task.

## 9. Resource efficiency

The implementation should be lightweight.

Avoid:

- Quickshell.
- A custom Rust daemon.
- A second long-running Eww daemon if the existing one can be reused.
- Continuous FFmpeg execution.
- Runtime AI/depth estimation.
- Continuous wallpaper re-rendering.
- Unnecessary full-screen transparent image buffers.
- Repeated polling faster than needed.

Prefer a cached PNG foreground and a simple native Eww clock label.

Benchmark the additional CPU and memory overhead if local tools are available. Do not claim resource improvements without measurements.

## 10. Verification and acceptance criteria

Perform the following checks:

1. Validate Eww Yuck and SCSS syntax.
2. Confirm the existing Eww widgets still load.
3. Confirm the independent Eww bar is unaffected.
4. Confirm the clock displays the actual local time.
5. Confirm time changes without wallpaper regeneration.
6. Confirm the foreground accurately occludes the clock.
7. Confirm no opaque background appears around the PNG.
8. Confirm awww continues displaying the original wallpaper.
9. Confirm application windows appear above the depth effect.
10. Confirm the existing top bar remains visible.
11. Confirm the new window does not reserve desktop space.
12. Check pointer behavior over transparent regions.
13. Verify the clock uses Matugen's current SCSS tokens.
14. Test both wallpaper-derived and fixed-palette color flows where practical.
15. Confirm stopping the depth clock does not terminate the Eww bar.
16. Check that the design is not dependent on Hyprland-only functionality.
17. Test using Niri and Hyprland when both sessions are available.
18. Verify that wallpaper changes cannot leave a mismatched foreground visible.

Use screenshots for visual comparison if the environment supports capturing the desktop.

Do not report tests as passed unless they were actually executed.

## 11. Deliverables

Provide:

- Working Eww depth-clock widget.
- SCSS styling fully integrated with existing Matugen tokens.
- Transparent foreground PNG derived from `Nyx Bright.png`, if image segmentation is possible.
- Minimal control/setup scripts, only if needed.
- Documentation containing commands for starting, stopping, and adjusting the widget.
- Explanation of how the dynamic clock interacts with the static foreground.
- List of modified/created files.
- Test results and any remaining limitations.

Keep changes scoped to this feature. Do not introduce unrelated refactors.

**Definition of done:** The original Nyx Bright wallpaper is displayed through awww, a large live Eww clock appears over it, the chosen subject visibly overlaps and conceals part of the clock, and the clock's colors automatically derive from the currently active Matugen theme rather than hardcoded values.

Implement the feature, not just a proposal. Do not commit or push changes.

