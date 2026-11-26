#!/usr/bin/env bash
# The bar provider (waybar/eww) is an atlanta concept, so use/switch are
# atlanta-only. The panel toggle is an eww window and is atlanta-only too.
set -u

dir=${CONSTELLIA_DIR:-$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P)} || exit 1
# shellcheck source=../lib/backend.sh
source "$dir/lib/backend.sh"
# shellcheck source=../lib/state.sh
source "$dir/lib/state.sh"

capability=${1:-bar}
if (( $# > 0 )); then
    shift
fi
verb=${1:-}
if (( $# > 0 )); then
    shift
fi
shell=$(shell_get)

fail() {
    printf 'constellia: %s\n' "$*" >&2
    exit 2
}

unsupported() {
    printf 'constellia: %s is not supported on the %s shell\n' "$capability $verb" "$shell" >&2
    exit 3
}

if [[ $capability == bar.panel ]]; then
    [[ $verb == toggle ]] || fail 'bar.panel needs toggle'
    [[ -n ${1:-} ]] || fail 'bar.panel toggle needs a panel (profile, distro, calendar-popup, music-popup)'
    (( $# == 1 )) || fail 'bar.panel toggle takes exactly one panel'
    [[ $shell == atlanta ]] || unsupported
    run_backend atlanta bar.panel toggle "$1"
fi

case $verb in
    show|hide|toggle|status|use|switch) ;;
    '') fail 'bar needs a verb (show, hide, toggle, status, use, switch)' ;;
    *) fail "unknown bar verb: $verb (show, hide, toggle, status, use, switch)" ;;
esac

if [[ $shell == atlanta ]]; then
    run_backend atlanta bar "$verb" "$@"
fi

case $verb in
    show) run_backend noctalia msg bar-show ;;
    hide) run_backend noctalia msg bar-hide ;;
    toggle) run_backend noctalia msg bar-toggle ;;
    status) run_backend noctalia msg status ;;
    use|switch) unsupported ;;
esac
