# The only state constellia owns: the chosen shell per WM. Theme state arrives
# in phase 5; nothing else is copied (wallpaper and bar belong to atlanta).
#
# A missing file is atlanta: without constellia, this repo starts the atlanta
# stack. An unknown value is also atlanta, and report.sh flags it.

constellia_state=${CONSTELLIA_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/constellia}
constellia_shell_dir=$constellia_state/shell

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
