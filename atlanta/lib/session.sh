# Session detection. ATLANTA_SESSION wins so tests and one-off commands can
# answer without a compositor environment.

session_name() {
    if [[ -n ${ATLANTA_SESSION:-} ]]; then
        printf '%s\n' "$ATLANTA_SESSION"
        return 0
    fi
    if [[ -n ${NIRI_SOCKET:-} ]]; then
        printf 'niri\n'
        return 0
    fi
    if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
        printf 'hyprland\n'
        return 0
    fi
    case ${XDG_CURRENT_DESKTOP:-} in
        *[Hh]yprland*) printf 'hyprland\n' ;;
        *[Nn]iri*) printf 'niri\n' ;;
        *) printf 'unknown\n' ;;
    esac
}

require_hyprland() {
    local session
    session=$(session_name)
    [[ $session == hyprland ]] && return 0
    printf 'atlanta: %s is Hyprland-only (session: %s)\n' "$1" "$session" >&2
    exit 3
}

require_session() {
    local label=$1 session allowed list=
    shift
    session=$(session_name)
    for allowed in "$@"; do
        [[ $session == "$allowed" ]] && return 0
        list+=${list:+, }$allowed
    done
    printf 'atlanta: %s needs %s (session: %s)\n' "$label" "$list" "$session" >&2
    exit 3
}
