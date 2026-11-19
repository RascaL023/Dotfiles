#!/usr/bin/env bash

set -u

timeout_s=${RELOAD_TIMEOUT:-5}
root=${HOME}/.dotfile/noctalia
palette=wallpaper-based
store_name=noctalia-wallpaper
render_cfg=$root/core/palette/$palette/config.toml
theme_root=${THEME_ROOT:-$HOME/.myenv/theme/palette}
generated=$theme_root/generated
current=$theme_root/current
reload_script=$HOME/.dotfile/matugen/script/palette.sh

dry_run=0
do_reload=1
scheme=""
pure_black=""
source_path=""
wanted=()

have() { command -v "$1" >/dev/null 2>&1; }

ok() { printf '[ok]   %s\n' "$*"; }
skip() { printf '[skip] %s\n' "$*"; }
fail() { printf '[FAIL] %s\n' "$*" >&2; }

shell_theme_value() {
    local key=$1
    sed -n "s/^[[:space:]]*$key[[:space:]]*=[[:space:]]*\"\([^\"]*\)\".*/\1/p" \
        "$root/config.toml" 2>/dev/null | head -n1
}

wall_scheme() {
    local v
    v=$(shell_theme_value wallpaper_scheme)
    printf '%s' "${scheme:-${v:-m3-tonal-spot}}"
}

pure_black_enabled() {
    local v
    if [[ -n $pure_black ]]; then
        [[ $pure_black == true ]]
        return
    fi
    [[ $(shell_theme_value pure_black_dark) == true ]]
}

usage() {
    printf 'usage: noctalia-ctl palette <wallpaper|palette.json> [options] [consumer ...]\n'
    printf '       noctalia-ctl palette --list\n\n'
    printf 'options: -n/--dry-run, -N/--no-reload, -s/--scheme <name>, -b/--pure-black,\n'
    printf '         -l/--list, -h/--help\n'
    printf 'A palette with no source reloads consumers only.\n\n'
    printf 'See %s/README.md for palette sources and the store layout.\n' "$root"
}

# Noctalia reports a failed template as a warning and writes nothing, so a
# missing or empty file must fail here.
validate() {
    local dir=$1 file
    local -a files
    mapfile -t files < <(find "$dir" -type f | sort)
    if [[ ${#files[@]} -eq 0 ]]; then
        fail "tidak ada berkas yang dirender"
        return 1
    fi
    for file in "${files[@]}"; do
        if [[ ! -s $file ]]; then
            fail "berkas kosong: ${file#"$dir"/}"
            return 1
        fi
        if grep -qE '\{\{|\}\}|<\*|\*>' "$file"; then
            fail "placeholder tersisa di ${file#"$dir"/}"
            return 1
        fi
    done
    return 0
}

render_palette() {
    local image=$1 out=$2 scheme_name
    local -a cmd
    scheme_name=$(wall_scheme)
    cmd=(noctalia theme "$image" --both --scheme "$scheme_name" -o "$out")
    if pure_black_enabled; then
        cmd=(noctalia theme "$image" --both --scheme "$scheme_name" --pure-black -o "$out")
    fi
    if (( dry_run )); then
        printf '[dry]  palette: %s\n' "${cmd[*]}"
        return 0
    fi
    if ! "${cmd[@]}"; then
        fail "palette gagal dibuat dari $image"
        return 1
    fi
    ok "palette: $(basename "${out}") (scheme $scheme_name)"
}

# The store is decided here: output_path is relative to the render config, so
# the config is copied into the staging directory, and the folder is moved into
# place only after it validates.
render() {
    local src=$1 palette_json out tmp
    local -a cmd
    if [[ ! -f $src ]]; then
        fail "sumber tidak ada: $src"
        return 1
    fi
    case $src in
        *.json) ;;
        *.png|*.jpg|*.jpeg|*.webp|*.gif|*.bmp) ;;
        *)
            fail "sumber harus gambar (png/jpg/webp) atau token map .json"
            return 1
            ;;
    esac
    if [[ ! -f $render_cfg ]]; then
        fail "config render tidak ada: $render_cfg"
        return 1
    fi
    if ! have noctalia; then
        fail "noctalia tidak ada di PATH"
        return 1
    fi

    out=$generated/$store_name
    tmp=$generated/.$store_name.tmp
    if (( dry_run )); then
        if [[ $src == *.json ]]; then
            printf '[dry]  render %s: noctalia theme --theme-json %s -c %s (cwd %s)\n' \
                "$store_name" "$src" "$render_cfg" "$tmp"
        else
            render_palette "$src" "$tmp/palette.json"
            printf '[dry]  render %s: noctalia theme --theme-json %s/palette.json -c %s (cwd %s)\n' \
                "$store_name" "$tmp" "$render_cfg" "$tmp"
        fi
        return 0
    fi

    rm -rf "$tmp"
    mkdir -p "$tmp"
    cp "$render_cfg" "$tmp/config.toml"

    if [[ $src == *.json ]]; then
        palette_json=$src
    else
        palette_json=$tmp/palette.json
        render_palette "$src" "$palette_json" || { rm -rf "$tmp"; return 1; }
    fi

    cmd=(noctalia theme --theme-json "$palette_json" -c ./config.toml)
    if ! ( cd "$tmp" && "${cmd[@]}" ); then
        fail "noctalia gagal merender; $out tidak diubah"
        rm -rf "$tmp"
        return 1
    fi
    rm -f "$tmp/config.toml"

    if ! validate "$tmp"; then
        fail "$out tidak diubah"
        rm -rf "$tmp"
        return 1
    fi

    rm -rf "$out"
    mv "$tmp" "$out"
    ln -sfn "$out" "$current"
    ok "$store_name: $(find "$out" -type f | wc -l) berkas, current -> generated/$store_name"
}

# Reload rules live in matugen/script/palette.sh; they read the same `current`
# symlink, so consumers do not care who rendered the palette.
reload() {
    if (( ! do_reload )); then
        skip "reload dimatikan (--no-reload)"
        return 0
    fi
    if [[ ! -x $reload_script ]]; then
        fail "script reload tidak ada: $reload_script"
        return 1
    fi
    if (( dry_run )); then
        printf '[dry]  reload: %s %s\n' "$reload_script" "${wanted[*]-}"
        return 0
    fi
    if timeout "$timeout_s" "$reload_script" "${wanted[@]}"; then
        ok "reload"
    else
        fail "reload gagal atau lewat ${timeout_s}s"
        return 1
    fi
}

list_consumers() {
    if [[ -x $reload_script ]]; then
        "$reload_script" --list
        return
    fi
    printf '%s\n' alacritty kitty lazygit css scss rasi nvim herdr yazi foot hypr niri
}

main() {
    local arg
    while (( $# )); do
        arg=$1
        shift
        case $arg in
            -n|--dry-run) dry_run=1 ;;
            -N|--no-reload) do_reload=0 ;;
            -l|--list) list_consumers; return 0 ;;
            -s|--scheme)
                if (( ! $# )); then
                    fail "--scheme butuh nama generator"
                    return 2
                fi
                scheme=$1
                shift
                ;;
            -b|--pure-black) pure_black=true ;;
            -h|--help) usage; return 0 ;;
            --) while (( $# )); do wanted+=("$1"); shift; done ;;
            -*)
                fail "opsi tidak dikenal: $arg"
                usage >&2
                return 2
                ;;
            *)
                if [[ -z $source_path && ( -f $arg || $arg == */* ) ]]; then
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
    reload
}

main "$@"
