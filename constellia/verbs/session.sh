#!/usr/bin/env bash
# Lock belongs to the active shell: hyprlock on atlanta, the Noctalia lockscreen
# on noctalia. Noctalia has no verified session-menu panel, so menu is atlanta.
set -u

dir=${CONSTELLIA_DIR:-$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P)} || exit 1
# shellcheck source=../lib/backend.sh
source "$dir/lib/backend.sh"
# shellcheck source=../lib/state.sh
source "$dir/lib/state.sh"
# shellcheck source=../lib/session.sh
source "$dir/lib/session.sh"

capability=${1:-session}
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

case $verb in
    lock|menu|logout|reboot|poweroff) ;;
    dpms)
        case ${1:-} in
            off|on) ;;
            *) fail 'session dpms needs off or on' ;;
        esac
        ;;
    '') fail 'session needs a verb (lock, menu, logout, reboot, poweroff, dpms)' ;;
    *) fail "unknown session verb: $verb (lock, menu, logout, reboot, poweroff, dpms)" ;;
esac

case $verb in
    lock|dpms) require_wm "session $verb" ;;
esac

if [[ $shell == atlanta ]]; then
    run_backend atlanta session "$verb" "$@"
fi

case $verb in
    menu) unsupported ;;
    lock) run_backend noctalia msg session lock ;;
    logout) run_backend noctalia msg session logout ;;
    reboot) run_backend noctalia msg session reboot ;;
    poweroff) run_backend noctalia msg session shutdown ;;
    dpms)
        case $1 in
            off) run_backend noctalia msg dpms-off ;;
            on) run_backend noctalia msg dpms-on ;;
        esac
        ;;
esac
