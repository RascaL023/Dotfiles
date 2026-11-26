#!/usr/bin/env bash
# swayidle is atlanta's; Noctalia schedules idle and lock internally and has no
# equivalent command, so this capability is deliberately atlanta-only.
set -u

dir=${CONSTELLIA_DIR:-$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P)} || exit 1
# shellcheck source=../lib/backend.sh
source "$dir/lib/backend.sh"
# shellcheck source=../lib/state.sh
source "$dir/lib/state.sh"
# shellcheck source=../lib/session.sh
source "$dir/lib/session.sh"

capability=${1:-idle}
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
    '') fail 'idle needs a verb (toggle, status)' ;;
    *) fail "unknown idle verb: $verb (toggle, status)" ;;
esac

require_wm "idle $verb"
[[ $shell == atlanta ]] || unsupported
run_backend atlanta idle "$verb" "$@"
