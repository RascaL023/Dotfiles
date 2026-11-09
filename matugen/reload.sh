#!/usr/bin/env bash

# matugen/reload.sh — let the running desktop pick up freshly rendered files.
# Both matugen configs have no post_hook, so this is the only place activation
# happens: nothing is reloaded for a process that is not running, every call is
# wrapped in `timeout` (a dead D-Bus service can wait forever), and a palette
# that fails `luac -p` is reported instead of applied.
#
#   reload.sh                 reload every consumer
#   reload.sh kitty hypr      reload only those
#   reload.sh --list          print known consumers
#   reload.sh --dry-run …     print what would run, change nothing

set -u

timeout_s=${RELOAD_TIMEOUT:-5}
theme_root=${THEME_ROOT:-$HOME/.myenv/theme}
current=$theme_root/current
depthctl=$HOME/.dotfile/eww/scripts/depthctl

dry_run=0
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

# --- consumers -------------------------------------------------------------

# Alacritty 0.17 watches the theme's alacritty *directory*, not the file, so the
# trigger is an entry changing inside it: create the dir, then touch the import.
# Flipping ~/.myenv/theme/current replaces the watched inode, so a theme flip
# still needs alacritty restarted.
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
    # depthctl resolves the wallpaper itself; refresh only repositions.
    if [[ -x $depthctl ]] && running eww; then
        run "depth clock" "$depthctl" refresh
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
usage: reload.sh [options] [consumer ...]

  (no consumer)     reload every consumer matugen feeds
  consumer ...      reload only these (see --list)
  -n, --dry-run     print the actions, change nothing
  -l, --list        print known consumers
  -h, --help        this text
EOF
}

main() {
    local arg tool rc=0
    for arg in "$@"; do
        case $arg in
            -n|--dry-run) dry_run=1 ;;
            -l|--list) printf '%s\n' "${consumers[@]}"; return 0 ;;
            -h|--help) usage; return 0 ;;
            -*) fail "opsi tidak dikenal: $arg"; usage >&2; return 2 ;;
            *) wanted+=("$arg") ;;
        esac
    done

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

main "$@"
