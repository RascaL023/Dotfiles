#!/usr/bin/env bash
# The OSD is a shell surface: atlanta uses wpctl plus the SwayNC bubble (via
# atlanta), noctalia uses its own OSD commands.
set -u

dir=${CONSTELLIA_DIR:-$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P)} || exit 1
# shellcheck source=../lib/backend.sh
source "$dir/lib/backend.sh"
# shellcheck source=../lib/state.sh
source "$dir/lib/state.sh"

capability=${1:-volume}
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

case $capability in
    volume)
        case $verb in
            up|down|mute) ;;
            '') fail 'volume needs a verb (up, down, mute)' ;;
            *) fail "unknown volume verb: $verb (up, down, mute)" ;;
        esac
        ;;
    mic)
        [[ $verb == toggle ]] || fail 'mic needs toggle'
        ;;
    brightness)
        case $verb in
            up|down) ;;
            '') fail 'brightness needs a verb (up, down)' ;;
            *) fail "unknown brightness verb: $verb (up, down)" ;;
        esac
        ;;
esac

if [[ $shell == atlanta ]]; then
    run_backend atlanta "$capability" "$verb" "$@"
fi

case $capability in
    volume)
        case $verb in
            up) run_backend noctalia msg volume-up ;;
            down) run_backend noctalia msg volume-down ;;
            mute) run_backend noctalia msg volume-mute ;;
        esac
        ;;
    mic) run_backend noctalia msg mic-mute ;;
    brightness)
        case $verb in
            up) run_backend noctalia msg brightness-up ;;
            down) run_backend noctalia msg brightness-down ;;
        esac
        ;;
esac
