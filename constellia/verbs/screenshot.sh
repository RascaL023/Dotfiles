#!/usr/bin/env bash
# atlanta owns the grim/slurp path (region, output, window) and the timestamped
# directory. CONSTELLIA_SCREENSHOT_DIR is forwarded as its ATLANTA_SCREENSHOT_DIR.
# Noctalia renders into its own directory from shell.screenshot.directory.
set -u

dir=${CONSTELLIA_DIR:-$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P)} || exit 1
# shellcheck source=../lib/backend.sh
source "$dir/lib/backend.sh"
# shellcheck source=../lib/state.sh
source "$dir/lib/state.sh"

capability=${1:-screenshot}
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
    region|screen|window|annotate) ;;
    '') fail 'screenshot needs a verb (region, screen, window, annotate)' ;;
    *) fail "unknown screenshot verb: $verb (region, screen, window, annotate)" ;;
esac

if [[ $shell == atlanta ]]; then
    [[ $verb == annotate ]] && unsupported
    if [[ -n ${CONSTELLIA_SCREENSHOT_DIR:-} ]]; then
        export ATLANTA_SCREENSHOT_DIR=$CONSTELLIA_SCREENSHOT_DIR
    fi
    run_backend atlanta screenshot "$verb" "$@"
fi

case $verb in
    region) run_backend noctalia msg screenshot-region ;;
    screen) run_backend noctalia msg screenshot-fullscreen ;;
    window) run_backend noctalia msg screenshot-window ;;
    annotate) run_backend noctalia msg screenshot-annotate ;;
esac
