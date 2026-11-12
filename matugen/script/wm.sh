#!/usr/bin/env bash
# Shared WM detection for matugen scripts. Source this file; do not execute it.
#
# Hyprland always exports HYPRLAND_INSTANCE_SIGNATURE and creates a runtime
# directory for it; niri exports NIRI_SOCKET. XDG_CURRENT_DESKTOP is only a
# fallback, because wrappers and `sudo -E`-style callers can strip the socket
# variables.
#
# Output: hypr | niri | unknown. Callers decide which templates that enables, so
# adding niri later means adding one case here, not rewriting the renderers.

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
