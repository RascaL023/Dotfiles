#!/usr/bin/env bash
# SwayNC on atlanta, the Noctalia panel on noctalia. DND without an argument
# toggles; on/off is explicit on both sides.
set -u

dir=${CONSTELLIA_DIR:-$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P)} || exit 1
# shellcheck source=../lib/backend.sh
source "$dir/lib/backend.sh"
# shellcheck source=../lib/state.sh
source "$dir/lib/state.sh"

capability=${1:-notifications}
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
    toggle|clear) ;;
    dnd)
        case ${1:-} in
            on|off|'') ;;
            *) fail 'notifications dnd needs on or off' ;;
        esac
        ;;
    '') fail 'notifications needs a verb (toggle, dnd, clear)' ;;
    *) fail "unknown notifications verb: $verb (toggle, dnd, clear)" ;;
esac

if [[ $shell == atlanta ]]; then
    case $verb in
        toggle) run_backend swaync-client -t ;;
        clear) run_backend swaync-client -C ;;
        dnd)
            case ${1:-} in
                on) run_backend swaync-client -d -sw ;;
                off) run_backend swaync-client -df ;;
                '') run_backend swaync-client -d ;;
            esac
            ;;
    esac
fi

case $verb in
    toggle) run_backend noctalia msg panel-toggle control-center notifications ;;
    clear) run_backend noctalia msg notification-clear-active ;;
    dnd)
        case ${1:-} in
            on) run_backend noctalia msg notification-dnd-set true ;;
            off) run_backend noctalia msg notification-dnd-set false ;;
            '') run_backend noctalia msg notification-dnd-toggle ;;
        esac
        ;;
esac
