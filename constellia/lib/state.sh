# The only state constellia owns: the chosen shell per WM and the theme variant.
# Nothing else is copied (wallpaper and bar belong to atlanta).
#
# A missing shell file is atlanta: without constellia, this repo starts the
# atlanta stack. An unknown value is also atlanta, and report.sh flags it.

constellia_state=${CONSTELLIA_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/constellia}
constellia_shell_dir=$constellia_state/shell
constellia_theme_state=$constellia_state/theme

palette_store=${THEME_ROOT:-$HOME/.myenv/theme/palette}
feel_store=${FEEL_ROOT:-$HOME/.myenv/theme/feel}

shell_valid() {
    case $1 in
        atlanta|noctalia) return 0 ;;
        *) return 1 ;;
    esac
}

# Raw value of shell/<wm>; empty when the file is missing or unreadable.
shell_raw() {
    local file=$constellia_shell_dir/${1:-unknown} value=''
    [[ -r $file ]] && IFS= read -r value < "$file"
    printf '%s\n' "$value"
}

# The effective shell for an arbitrary WM (used to report both WMs).
shell_effective() {
    local value
    value=$(shell_raw "$1")
    if shell_valid "$value"; then
        printf '%s\n' "$value"
    else
        printf 'atlanta\n'
    fi
}

shell_get() {
    shell_effective "${CONSTELLIA_WM:-unknown}"
}

# Prints a warning only when the file exists and holds an unknown value.
shell_warning() {
    local value
    value=$(shell_raw "${CONSTELLIA_WM:-unknown}")
    [[ -z $value ]] && return 0
    shell_valid "$value" && return 0
    printf "constellia: unknown shell '%s' in state; using atlanta\n" "$value" >&2
}

# Atomic: one rename, and only for the WM of this session.
shell_save() {
    local wm=${CONSTELLIA_WM:-}
    [[ -n $wm && $wm != unknown ]] || return 1
    shell_valid "$1" || return 1
    mkdir -p -- "$constellia_shell_dir" || return 1
    printf '%s\n' "$1" > "$constellia_shell_dir/.$wm.tmp" \
        && mv -f -- "$constellia_shell_dir/.$wm.tmp" "$constellia_shell_dir/$wm"
}

# --- Theme state ------------------------------------------------------------
# engine, palette and feel are derived from the store symlinks; only the
# variant is stored, because no generated path names dark/light.

# Resolved directory behind a store link; empty when it is missing or dangling.
store_target() {
    local target
    target=$(readlink -f -- "$1" 2>/dev/null) || return 0
    [[ -d $target ]] || return 0
    printf '%s\n' "$target"
}

palette_engine() {
    local target
    target=$(store_target "$palette_store/current")
    [[ -n $target ]] || return 0
    target=${target%/*}
    printf '%s\n' "${target##*/}"
}

palette_name() {
    local target
    target=$(store_target "$palette_store/current")
    [[ -n $target ]] && printf '%s\n' "${target##*/}"
}

feel_profile() {
    local target
    target=$(store_target "$feel_store/current")
    [[ -n $target ]] && printf '%s\n' "${target##*/}"
}

theme_variant() {
    local key value
    [[ -r $constellia_theme_state ]] || return 0
    while IFS='=' read -r key value; do
        [[ $key == variant ]] && {
            printf '%s\n' "$value"
            return 0
        }
    done < "$constellia_theme_state"
}

theme_save() {
    mkdir -p -- "$constellia_state" || return 1
    printf 'variant=%s\nupdated=%s\n' "$1" "$(date +%s)" > "$constellia_state/.theme.tmp" \
        && mv -f -- "$constellia_state/.theme.tmp" "$constellia_theme_state"
}

# --- Report formatting ------------------------------------------------------

json_quote() {
    local value=$1
    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    printf '"%s"' "$value"
}

json_or_null() {
    [[ -z $1 ]] && {
        printf 'null'
        return 0
    }
    json_quote "$1"
}
