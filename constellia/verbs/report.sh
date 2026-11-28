#!/usr/bin/env bash
# Reporting only: neither mode starts, stops, or writes anything.
set -u

dir=${CONSTELLIA_DIR:-$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P)} || exit 1
# shellcheck source=../lib/backend.sh
source "$dir/lib/backend.sh"
# shellcheck source=../lib/state.sh
source "$dir/lib/state.sh"
# shellcheck source=../lib/session.sh
source "$dir/lib/session.sh"

mode=${1:-status}
if (( $# > 0 )); then
    shift
fi

case $mode in
    status|doctor) ;;
    *) printf 'constellia: unknown report mode: %s\n' "$mode" >&2; exit 2 ;;
esac
if (( $# )); then
    printf 'constellia: %s takes no arguments\n' "$mode" >&2
    exit 2
fi

json=${CONSTELLIA_JSON:-0}
# Every binary constellia may exec, in the order doctor prints them.
doctor_backends=(atlanta rofi-ctl swaync-client noctalia noctalia-ctl
                 matugen-ctl busctl pgrep pkill)

# What is actually alive. Only the current WM can be attributed: noonctalia and
# the atlanta stack are session-wide processes.
live_shell() {
    if noctalia_running; then
        printf 'noctalia'
        return 0
    fi
    if atlanta_running; then
        printf 'atlanta'
        return 0
    fi
    printf 'none'
}

shell_line() {
    local wm=$1 raw value suffix=''
    raw=$(shell_raw "$wm")
    if [[ -z $raw ]]; then
        value=atlanta
    elif shell_valid "$raw"; then
        value=$raw
    else
        value=atlanta
        suffix=" state-invalid: $raw"
    fi
    printf '%s=%s%s\n' "$wm" "$value" "$suffix"
}

status_text() {
    local wm=${CONSTELLIA_WM:-unknown} shell live
    shell_line hypr
    shell_line niri
    [[ $wm == unknown ]] && return 0
    shell=$(shell_get)
    live=$(live_shell)
    [[ $live == "$shell" ]] && return 0
    printf 'drift: %s says %s, live is %s\n' "$wm" "$shell" "$live"
}

status_json() {
    local wm=${CONSTELLIA_WM:-unknown} wm_json=null shell_json=null live_json=null
    local drift=false hypr niri live_text shell
    hypr=$(shell_effective hypr)
    niri=$(shell_effective niri)
    if [[ $wm != unknown ]]; then
        shell=$(shell_get)
        live_text=$(live_shell)
        wm_json=$(json_quote "$wm")
        shell_json=$(json_quote "$shell")
        live_json=$(json_quote "$live_text")
        [[ $live_text == "$shell" ]] || drift=true
    fi
    printf '{"wm":%s,"shell":%s,"live":%s,"drift":%s,"shells":{"hypr":%s,"niri":%s},"invalid":{"hypr":%s,"niri":%s}}\n' \
        "$wm_json" "$shell_json" "$live_json" "$drift" \
        "$(json_quote "$hypr")" "$(json_quote "$niri")" \
        "$(json_or_null "$(shell_invalid hypr)")" \
        "$(json_or_null "$(shell_invalid niri)")"
}

shell_invalid() {
    local raw
    raw=$(shell_raw "$1")
    [[ -z $raw ]] && return 0
    shell_valid "$raw" && return 0
    printf '%s\n' "$raw"
}

status() {
    shell_warning
    if (( json )); then
        status_json
        return 0
    fi
    status_text
}

doctor_text() {
    local name path
    shell_warning
    printf '%-15s %s\n' wm "${CONSTELLIA_WM:-unknown}"
    printf '%-15s %s\n' shell "$(shell_get)"
    printf '%-15s %s\n' state "$constellia_shell_dir/${CONSTELLIA_WM:-unknown}"
    for name in "${doctor_backends[@]}"; do
        if path=$(backend_path "$name"); then
            printf '%-15s %s\n' "$name" "$path"
        else
            printf '%-15s %s\n' "$name" MISSING
        fi
    done
}

doctor_json() {
    local name path separator=''
    printf '{"wm":%s,"shell":%s,"state":%s,"backends":{' \
        "$(json_quote "${CONSTELLIA_WM:-unknown}")" \
        "$(json_quote "$(shell_get)")" \
        "$(json_quote "$constellia_shell_dir/${CONSTELLIA_WM:-unknown}")"
    for name in "${doctor_backends[@]}"; do
        printf '%s%s:' "$separator" "$(json_quote "$name")"
        separator=,
        if path=$(backend_path "$name"); then
            json_quote "$path"
        else
            printf 'null'
        fi
    done
    printf '}}\n'
}

case $mode in
    status) status ;;
    doctor)
        if (( json )); then
            doctor_json
        else
            doctor_text
        fi
        ;;
esac
