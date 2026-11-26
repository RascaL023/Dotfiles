#!/usr/bin/env bash
# atlanta tracks wlsunset. Noctalia's nightlight-force-toggle is the immediate
# on/off effect; nightlight-toggle only edits the schedule, so it is not used.
set -u

dir=${CONSTELLIA_DIR:-$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P)} || exit 1
# shellcheck source=../lib/backend.sh
source "$dir/lib/backend.sh"
# shellcheck source=../lib/state.sh
source "$dir/lib/state.sh"
# shellcheck source=../lib/session.sh
source "$dir/lib/session.sh"

capability=${1:-nightlight}
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
    toggle|status) ;;
    '') fail 'nightlight needs a verb (toggle, status)' ;;
    *) fail "unknown nightlight verb: $verb (toggle, status)" ;;
esac

require_wm "nightlight $verb"
[[ $shell == atlanta ]] && run_backend atlanta nightlight "$verb" "$@"
[[ $verb == status ]] && unsupported
run_backend noctalia msg nightlight-force-toggle
