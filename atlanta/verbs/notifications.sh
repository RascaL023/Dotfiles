#!/usr/bin/env bash
# SwayNC owns the daemon; -t and -d are the flags this repo already relies on.
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

ctl=$(require_provider swaync-client) || exit $?

case $verb in
    toggle) exec "$ctl" -t ;;
    dnd) exec "$ctl" -d ;;
    clear)
        printf 'atlanta: notifications clear is not wired; swaync-client --help does not answer here\n' >&2
        exit 3
        ;;
    *) fail 'notifications needs a verb (toggle, dnd)' ;;
esac
