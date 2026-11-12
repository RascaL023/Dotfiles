#!/usr/bin/env bash
# matugen/palette.sh — render a palette, activate it, reload its consumers.
#
#   palette.sh <wallpaper>        Flow A: derive colours from an image
#   palette.sh <blueprint.json>   Flow B: render <theme>/blueprint/<variant>.json
#   palette.sh [consumer ...]     reload only
#   palette.sh --list             print known consumers
#   palette.sh --dry-run ...      print what would run, change nothing
#
# Both palette configs write relative output_paths (`/kitty/theme.conf`), so the
# store folder is decided here: render into `<store>/generated/.<palette>.tmp`,
# validate, move it to `<store>/generated/<palette>`, then flip
# `<store>/current`. A failed render therefore never replaces the live palette,
# and config.toml carries no store path (the same contract as
# core/feel/config.toml). Reload is process-gated and wrapped in `timeout`; a
# Hyprland palette that fails `luac -p` is reported instead of applied.
#
# Store layout (feel.sh uses the sibling directory):
#
#   ~/.myenv/theme/palette/generated/<palette>/   colour output
#   ~/.myenv/theme/palette/current -> generated/<palette>
#   ~/.myenv/theme/feel/generated/<profil>/       look & feel output
#   ~/.myenv/theme/feel/current    -> generated/<profil>

set -u

timeout_s=${RELOAD_TIMEOUT:-5}
root=${HOME}/.dotfile/matugen
theme_root=${THEME_ROOT:-$HOME/.myenv/theme/palette}
generated=$theme_root/generated
current=$theme_root/current
depth_ctl=$HOME/.dotfile/eww/script/depth-ctl

dry_run=0
source_path=""
wanted=()

# --- helpers ---------------------------------------------------------------

have() { command -v "$1" >/dev/null 2>&1; }

# clean_name <path-or-comm> — Nix wraps binaries (`.kitty-wrapped`), so neither
# `pgrep -x` nor a plain substring match is reliable here.
clean_name() {
    local n=${1##*/}
    n=${n#.}
    printf '%s' "${n%-wrapped}"
}

# running <name> — true when the application is actually alive.
running() {
    local want=$1 pid comm argv0
    while read -r pid; do
        [[ $pid == "$$" ]] && continue
        comm=$(clean_name "$(cat "/proc/$pid/comm" 2>/dev/null)")
        argv0=$(clean_name "$(tr '\0' '\n' < "/proc/$pid/cmdline" 2>/dev/null | head -n1)")
        [[ $comm == "$want" || $argv0 == "$want" ]] && return 0
        [[ $comm == "$want"* || $argv0 == "$want"* ]] && return 0
    done < <(pgrep -f -- "$want" 2>/dev/null)
    return 1
}

ok() { printf '[ok]   %s\n' "$*"; }
skip() { printf '[skip] %s\n' "$*"; }
fail() { printf '[FAIL] %s\n' "$*" >&2; }

# run <label> <command...>
run() {
    local label=$1
    shift
    if (( dry_run )); then
        printf '[dry]  %s: %s\n' "$label" "$*"
        return 0
    fi
    if timeout "$timeout_s" "$@"; then
        ok "$label"
    else
        fail "$label: gagal atau lewat ${timeout_s}s"
        return 1
    fi
}

# --- palette ---------------------------------------------------------------

# render <image|blueprint.json> — one palette, from source to active theme.
render() {
    local src=$1 name cfg out tmp
    local -a cmd files
    if [[ ! -f $src ]]; then
        fail "sumber tidak ada: $src"
        return 1
    fi
    case $src in
        *.json)
            local dir
            dir=$(cd "$(dirname "$src")" && pwd) || return 1
            if [[ ${dir##*/} != blueprint ]]; then
                fail "blueprint harus <theme>/blueprint/<variant>.json: $src"
                return 1
            fi
            name=${dir%/*}
            name=${name##*/}
            cfg=$root/core/palette/$name/config.toml
            cmd=(matugen json "$src" -c "$cfg")
            ;;
        *.png|*.jpg|*.jpeg|*.webp|*.gif|*.bmp)
            name=wallpaper-based
            cfg=$root/core/palette/wallpaper-based/config.toml
            cmd=(matugen image "$src" --source-color-index 0 -c "$cfg")
            ;;
        *)
            fail "sumber harus gambar (png/jpg/webp) atau blueprint .json: $src"
            return 1
            ;;
    esac
    if [[ ! -f $cfg ]]; then
        fail "config tidak ada: $cfg"
        return 1
    fi
    if ! have matugen; then
        fail "matugen tidak ada di PATH"
        return 1
    fi

    out=$generated/$name
    tmp=$generated/.$name.tmp
    if (( dry_run )); then
        printf '[dry]  render %s: %s -p %s\n' "$name" "${cmd[*]}" "$tmp"
        return 0
    fi

    rm -rf "$tmp"
    mkdir -p "$tmp"
    if ! "${cmd[@]}" -p "$tmp"; then
        fail "matugen gagal; $out tidak diubah"
        rm -rf "$tmp"
        return 1
    fi

    mapfile -t files < <(find "$tmp" -type f | sort)
    if [[ ${#files[@]} -eq 0 ]]; then
        fail "tidak ada berkas yang dirender; $out tidak diubah"
        rm -rf "$tmp"
        return 1
    fi
    local f
    for f in "${files[@]}"; do
        if [[ ! -s $f ]]; then
            fail "berkas kosong: ${f#"$tmp"/}; $out tidak diubah"
            rm -rf "$tmp"
            return 1
        fi
        if grep -qE '\{\{|\}\}|<\*|\*>' "$f"; then
            fail "placeholder tersisa di ${f#"$tmp"/}; $out tidak diubah"
            rm -rf "$tmp"
            return 1
        fi
    done

    rm -rf "$out"
    mv "$tmp" "$out"
    ln -sfn "$out" "$current"
    ok "$name: ${#files[@]} berkas, current -> generated/$name"
}

# --- consumers -------------------------------------------------------------

# Alacritty 0.17 watches the theme's alacritty *directory*, not the file, so the
# trigger is an entry changing inside it: create the dir, then touch the import.
# Flipping `current` replaces the watched inode, so a theme flip still needs
# alacritty restarted.
reload_alacritty() {
    local dir=$current/alacritty
    run "alacritty dir" mkdir -p "$dir" || return 1
    if [[ ! -f $dir/theme.toml ]]; then
        skip "alacritty: $dir/theme.toml tidak ada (tema tanpa warna alacritty)"
        return 0
    fi
    if ! running alacritty; then
        skip "alacritty: tidak jalan"
        return 0
    fi
    run alacritty touch "$dir/theme.toml"
}

# SIGUSR1 makes kitty re-read kitty.conf.
reload_kitty() {
    if ! running kitty; then
        skip "kitty: tidak jalan"
        return 0
    fi
    run kitty pkill -SIGUSR1 kitty
}

reload_lazygit() { skip "lazygit: dibaca saat start (tanpa reload)"; }

# Noctalia owns gtk, swaync and waybar when it is the active shell.
reload_css() {
    if running noctalia; then
        skip "gtk/swaync/waybar: Noctalia yang mengurus"
        return 0
    fi
    if have dconf; then
        run "gtk theme" dconf write /org/gnome/desktop/interface/gtk-theme "'Adwaita'"
        run "gtk theme" dconf write /org/gnome/desktop/interface/gtk-theme "'Kanagawa-Dark-Dragon'"
    else
        skip "gtk: dconf tidak tersedia"
    fi
    if running swaync; then
        run swaync swaync-client -rs
    else
        skip "swaync: tidak jalan"
    fi
    if running waybar; then
        run waybar pkill -SIGUSR2 waybar
    else
        skip "waybar: tidak jalan"
    fi
}

# eww reads scss/_theme.scss through @import; the depth clock also repositions.
reload_scss() {
    if running eww; then
        run eww eww reload
    else
        skip "eww: tidak jalan"
    fi
    # depth-ctl resolves the wallpaper itself; refresh only repositions.
    if [[ -x $depth_ctl ]] && running eww; then
        run "depth clock" "$depth_ctl" refresh
    else
        skip "depth clock: eww tidak siap"
    fi
}

reload_rasi() { skip "rofi: dibaca saat dibuka"; }
reload_nvim() { skip "nvim: watcher core.theme_watch yang memuat ulang"; }

reload_herdr() {
    if ! have herdr; then
        skip "herdr: tidak terpasang"
        return 0
    fi
    if ! running herdr; then
        skip "herdr: server tidak jalan"
        return 0
    fi
    run herdr herdr server reload-config
}

reload_yazi() { skip "yazi: dibaca saat start (flavor menunjuk current)"; }
reload_foot() { skip "foot: tidak punya sinyal reload"; }

# hyprctl needs HYPRLAND_INSTANCE_SIGNATURE; a niri session must never get here.
reload_hypr() {
    local sig=${HYPRLAND_INSTANCE_SIGNATURE:-}
    local runtime=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
    local palette=$current/hypr/theme.lua
    if [[ -z $sig || ! -d $runtime/hypr/$sig ]]; then
        skip "hypr: sesi ini bukan Hyprland (atau instance mati)"
        return 0
    fi
    if [[ -f $palette ]] && have luac && ! luac -p "$palette" 2>/dev/null; then
        fail "hypr: $palette gagal luac -p, reload dibatalkan"
        return 1
    fi
    run hyprland hyprctl --instance "$sig" reload
}

# --- dispatch --------------------------------------------------------------

# Default order; aliases at the end map template names to the same consumer.
consumers=(alacritty kitty lazygit css scss rasi nvim herdr yazi foot hypr)
declare -A handler=(
    [alacritty]=reload_alacritty
    [kitty]=reload_kitty
    [lazygit]=reload_lazygit
    [css]=reload_css
    [scss]=reload_scss
    [rasi]=reload_rasi
    [nvim]=reload_nvim
    [herdr]=reload_herdr
    [yazi]=reload_yazi
    [foot]=reload_foot
    [hypr]=reload_hypr
    # aliases: template names from the two configs
    [yazi-tmtheme]=reload_yazi
    [gtk]=reload_css
    [gtk3]=reload_css
)

usage() {
    cat <<'EOF'
usage: palette.sh [options] [source] [consumer ...]

  <wallpaper>       Flow A: render colours from an image (palette wallpaper-based)
  <blueprint.json>  Flow B: render <theme>/blueprint/<variant>.json
  (no source)       reload only
  consumer ...      reload only these tools (see --list)
  -n, --dry-run     print the actions, change nothing
  -l, --list        print known consumers
  -h, --help        this text

A render goes to ~/.myenv/theme/palette/generated/<palette> and, once it
validates, flips ~/.myenv/theme/palette/current. Override the palette store
with THEME_ROOT (the feel store stays at ~/.myenv/theme/feel).
EOF
}

dispatch() {
    local tool rc=0
    if (( ${#wanted[@]} )); then
        for tool in "${wanted[@]}"; do
            if [[ -z ${handler[$tool]:-} ]]; then
                fail "consumer tidak dikenal: $tool (lihat --list)"
                rc=2
                continue
            fi
            "${handler[$tool]}" || rc=1
        done
    else
        for tool in "${consumers[@]}"; do
            "${handler[$tool]}" || rc=1
        done
    fi
    return "$rc"
}

main() {
    local arg
    for arg in "$@"; do
        case $arg in
            -n|--dry-run) dry_run=1 ;;
            -l|--list) printf '%s\n' "${consumers[@]}"; return 0 ;;
            -h|--help) usage; return 0 ;;
            -*) fail "opsi tidak dikenal: $arg"; usage >&2; return 2 ;;
            *)
                if [[ -z $source_path ]] && [[ -f $arg || $arg == */* ]]; then
                    source_path=$arg
                else
                    wanted+=("$arg")
                fi
                ;;
        esac
    done

    if [[ -n $source_path ]]; then
        render "$source_path" || return 1
    fi
    dispatch
}

main "$@"
