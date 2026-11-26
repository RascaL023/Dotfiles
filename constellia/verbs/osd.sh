#!/usr/bin/env bash
# Report-only OSD. Noctalia's *-osd commands need a value argument, which would
# add a capability instead of mapping one, so this stays atlanta-only.
set -u

dir=${CONSTELLIA_DIR:-$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P)} || exit 1
# shellcheck source=../lib/backend.sh
source "$dir/lib/backend.sh"
# shellcheck source=../lib/state.sh
source "$dir/lib/state.sh"

capability=${1:-osd}
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
    volume|mic|brightness) ;;
    '') fail 'osd needs a verb (volume, mic, brightness)' ;;
    *) fail "unknown osd verb: $verb (volume, mic, brightness)" ;;
esac

if [[ $shell != atlanta ]]; then
    printf 'constellia: %s %s is not supported on the %s shell\n' "$capability" "$verb" "$shell" >&2
    exit 3
fi
run_backend atlanta osd "$verb"
