#!/usr/bin/env bash

set -u

script_dir=$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")" && pwd -P)
# shellcheck source=lib.sh
source "$script_dir/lib.sh"

timeout_s=${RELOAD_TIMEOUT:-5}
root=$(dirname -- "$script_dir")
repo=$(dirname -- "$root")
theme_root=${THEME_ROOT:-$HOME/.myenv/theme/palette}
generated=$theme_root/generated
store=$generated/matugen
current=$theme_root/current
depth_ctl=$repo/eww/script/depth-ctl

dry_run=0
scheme=""
source_path=""
wanted=()

# --- helpers ---------------------------------------------------------------

# run <label> <command...> — dry-run aware, timeout-wrapped, one report line.
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
    local src=$1 name cfg out tmp count suffix=''
    local -a cmd

    if [[ ! -f $src ]]; then
        fail "sumber tidak ada: $src"
        return 1
    fi

    case $src in
        *.json)
            local blueprint_dir
            blueprint_dir=$(cd -- "$(dirname -- "$src")" && pwd) || return 1
            if [[ ${blueprint_dir##*/} != blueprint ]]; then
                fail "blueprint harus <theme>/blueprint/<variant>.json: $src"
                return 1
            fi
            name=${blueprint_dir%/*}
            name=${name##*/}
            cfg=$root/core/palette/$name/config.toml
            cmd=(matugen json "$src" -c "$cfg")
            ;;
        *.png|*.jpg|*.jpeg|*.webp|*.gif|*.bmp)
            name=wallpaper-based
            cfg=$root/core/palette/wallpaper-based/config.toml
            cmd=(matugen image "$src" --source-color-index 0 -c "$cfg")
            [[ -n $scheme ]] && cmd+=(--type "$scheme")
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

    out=$store/$name
    tmp=$store/.$name.tmp
    if (( dry_run )); then
        printf '[dry]  render %s: %s -p %s\n' "$name" "${cmd[*]}" "$tmp"
        return 0
    fi

    stage "$tmp"
    if ! "${cmd[@]}" -p "$tmp"; then
        fail "matugen gagal; $out tidak diubah"
        rm -rf -- "$tmp"
        return 1
    fi
    if ! count=$(validate_stage "$tmp"); then
        fail "$out tidak diubah"
        rm -rf -- "$tmp"
        return 1
    fi
    if ! activate "$tmp" "$out" "$current"; then
        fail "$out tidak diubah"
        return 1
    fi
    [[ -n $scheme ]] && suffix=" (scheme $scheme)"
    ok "matugen/$name: $count berkas, current -> generated/matugen/$name$suffix"
}

# --- consumers -------------------------------------------------------------

# alacritty watches the theme's alacritty *directory*, so the trigger is an entry
# changing inside it. Flipping `current` replaces the watched inode, hence a theme
# flip still needs alacritty restarted.
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
        run eww eww-ctl reload
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

# herdr runs one server per session and the CLI picks the socket the pane
# exported (HERDR_SOCKET_PATH); outside a pane that default points at the stopped
# `default` session. Every running session reads the same
# ~/.config/herdr/config.toml, so each one must be named explicitly.
reload_herdr() {
    local name rc=0
    local -a sessions
    if ! have herdr; then
        skip "herdr: tidak terpasang"
        return 0
    fi
    if have jq; then
        mapfile -t sessions < <(herdr session list --json 2>/dev/null |
            jq -r '.sessions[] | select(.running) | .name')
    else
        mapfile -t sessions < <(herdr session list 2>/dev/null |
            awk 'NR > 1 && $2 == "running" { print $1 }')
    fi
    if (( ! ${#sessions[@]} )); then
        skip "herdr: tidak ada sesi yang jalan"
        return 0
    fi
    for name in "${sessions[@]}"; do
        run "herdr: $name" herdr --session "$name" server reload-config || rc=1
    done
    return "$rc"
}

reload_yazi() { skip "yazi: dibaca saat start (flavor menunjuk current)"; }
reload_foot() { skip "foot: tidak punya sinyal reload"; }

# niri tidak punya reload; sentuh config agar watcher membaca ulang.
reload_niri() {
    if ! running niri; then
        skip "niri: tidak jalan"
        return 0
    fi
    run niri touch "$repo/niri/config.kdl"
}

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
consumers=(alacritty kitty lazygit css scss rasi nvim herdr yazi foot hypr niri)
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
    [niri]=reload_niri
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
  -s, --scheme <nama>  skema matugen untuk sumber gambar, mis. scheme-vibrant
                    (default: skema yang sekarang, scheme-tonal-spot)
  -l, --list        print known consumers
  -h, --help        this text

A render goes to ~/.myenv/theme/palette/generated/matugen/<palette> and, once
it validates, flips ~/.myenv/theme/palette/current. Override the palette store
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
    local arg ext
    while (( $# )); do
        arg=$1
        shift
        case $arg in
            -n|--dry-run) dry_run=1 ;;
            -l|--list) printf '%s\n' "${consumers[@]}"; return 0 ;;
            -s|--scheme)
                if (( ! $# )) || [[ -z $1 ]]; then
                    fail "--scheme butuh nama (lihat matugen image --help)"
                    usage >&2
                    return 2
                fi
                scheme=$1
                shift
                ;;
            --scheme=*)
                scheme=${arg#*=}
                if [[ -z $scheme ]]; then
                    fail "--scheme butuh nama (lihat matugen image --help)"
                    usage >&2
                    return 2
                fi
                ;;
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

    # --scheme is a matugen image option; a blueprint already carries its colours.
    if [[ -n $scheme ]]; then
        if [[ -z $source_path ]]; then
            fail "--scheme butuh sumber gambar"
            usage >&2
            return 2
        fi
        ext=${source_path##*.}
        ext=${ext,,}
        case $ext in
            png|jpg|jpeg|webp|gif|bmp) ;;
            *)
                fail "--scheme hanya untuk sumber gambar (blueprint sudah membawa warna)"
                return 2
                ;;
        esac
    fi

    if [[ -n $source_path ]]; then
        render "$source_path" || return 1
    fi
    dispatch
}

main "$@"
