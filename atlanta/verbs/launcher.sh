#!/usr/bin/env bash
# Rofi owns the menu; atlanta only chooses the mode.
set -u

dir=$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P) || exit 1
# shellcheck source=../lib/provider.sh
source "$dir/lib/provider.sh"

capability=${1:-launcher}
if (( $# > 0 )); then
    shift
fi
verb=${1:-apps}
if (( $# > 0 )); then
    shift
fi

fail() {
    printf 'atlanta: %s\n' "$*" >&2
    exit 2
}

ctl=$(require_provider rofi-ctl) || exit $?

case $verb in
    apps|run|window|toggle)
        exec "$ctl" "$verb" "$@"
        ;;
    *)
        fail "unknown launcher verb: $verb (apps, run, window, toggle)"
        ;;
esac
