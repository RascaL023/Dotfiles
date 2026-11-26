#!/usr/bin/env bash
# Rofi owns the menu on atlanta; Noctalia owns the panel on noctalia. A style
# argument only exists on the rofi side.
set -u

dir=${CONSTELLIA_DIR:-$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P)} || exit 1
# shellcheck source=../lib/backend.sh
source "$dir/lib/backend.sh"
# shellcheck source=../lib/state.sh
source "$dir/lib/state.sh"

capability=${1:-launcher}
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

case $verb in
    apps|run|window|toggle) ;;
    '') fail 'launcher needs a verb (apps, run, window, toggle)' ;;
    *) fail "unknown launcher verb: $verb (apps, run, window, toggle)" ;;
esac

if [[ $shell == atlanta ]]; then
    run_backend rofi-ctl "$verb" "$@"
fi

case $verb in
    apps|toggle) run_backend noctalia msg panel-toggle launcher ;;
    run) run_backend noctalia msg panel-toggle launcher / ;;
    window) run_backend noctalia msg window-switcher ;;
esac
