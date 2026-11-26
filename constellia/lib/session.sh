# WM detection. Same rules as matugen/script/wm.sh, duplicated here so
# constellia stays a self-contained checkout that tests can copy on its own.
# CONSTELLIA_WM (or CONSTELLIA_SESSION) wins, so tests and one-off commands
# answer without a compositor.

wm_detect() {
    local sig=${HYPRLAND_INSTANCE_SIGNATURE:-}
    local runtime=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}

    if [[ -n $sig && -d $runtime/hypr/$sig ]]; then
        printf 'hypr'
        return 0
    fi

    if [[ -n ${NIRI_SOCKET:-} ]]; then
        printf 'niri'
        return 0
    fi

    case ${XDG_CURRENT_DESKTOP:-} in
        *[Hh]yprland*) printf 'hypr' ;;
        *[Nn]iri*)     printf 'niri' ;;
        *)             printf 'unknown' ;;
    esac
}

wm_valid() {
    case $1 in
        hypr|niri) return 0 ;;
        *) return 1 ;;
    esac
}

# Prints the WM, or fails when an explicit override is not hypr/niri.
wm_resolve() {
    local value=${1:-}
    if [[ -z $value ]]; then
        wm_detect
        return 0
    fi
    wm_valid "$value" || return 1
    printf '%s\n' "$value"
}

require_wm() {
    [[ ${CONSTELLIA_WM:-unknown} != unknown ]] && return 0
    printf 'constellia: %s needs a compositor (wm: unknown)\n' "$1" >&2
    exit 3
}
