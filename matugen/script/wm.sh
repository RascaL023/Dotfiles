#!/usr/bin/env bash

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
