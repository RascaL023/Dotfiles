#!/usr/bin/env bash
# SwayNC owns the daemon; -t, -d, and -C are the flags this repo uses.
set -u

dir=$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P) || exit 1
# shellcheck source=../lib/provider.sh
source "$dir/lib/provider.sh"

capability=${1:-notifications}
if (( $# > 0 )); then
    shift
fi
verb=${1:-}

fail() {
    printf 'atlanta: %s\n' "$*" >&2
    exit 2
}

case $verb in
    toggle|dnd|clear) ;;
    '') fail 'notifications needs a verb (toggle, dnd, clear)' ;;
    *) fail "unknown notifications verb: $verb (toggle, dnd, clear)" ;;
esac

ctl=$(require_provider swaync-client) || exit $?

case $verb in
    toggle) exec "$ctl" -t ;;
    dnd) exec "$ctl" -d ;;
    clear) exec "$ctl" -C ;;
esac
