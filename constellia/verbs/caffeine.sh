#!/usr/bin/env bash
# Caffeine is an idle inhibitor. atlanta has no inhibitor (swayidle schedules
# actions instead), and Noctalia has no status reader, so only noctalia toggle
# is supported.
set -u

dir=${CONSTELLIA_DIR:-$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P)} || exit 1
# shellcheck source=../lib/backend.sh
source "$dir/lib/backend.sh"
# shellcheck source=../lib/state.sh
source "$dir/lib/state.sh"

capability=${1:-caffeine}
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
    '') fail 'caffeine needs a verb (toggle, status)' ;;
    *) fail "unknown caffeine verb: $verb (toggle, status)" ;;
esac

[[ $shell == noctalia ]] || unsupported
[[ $verb == status ]] && unsupported
run_backend noctalia msg caffeine-toggle
