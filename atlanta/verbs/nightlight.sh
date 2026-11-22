#!/usr/bin/env bash
# hyprsunset has no IPC either; the tracked PID is the only truthful state.
set -u

dir=$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P) || exit 1
# shellcheck source=../lib/session.sh
source "$dir/lib/session.sh"
# shellcheck source=../lib/provider.sh
source "$dir/lib/provider.sh"
# shellcheck source=../lib/proc.sh
source "$dir/lib/proc.sh"

capability=${1:-nightlight}
if (( $# > 0 )); then
    shift
fi
verb=${1:-}

fail() {
    printf 'atlanta: %s\n' "$*" >&2
    exit 2
}

require_hyprland 'nightlight'
program=$(require_provider hyprsunset) || exit $?
temperature=${ATLANTA_NIGHTLIGHT_TEMP:-4000}

case $verb in
    toggle)
        if tracked_pid hyprsunset hyprsunset >/dev/null; then
            stop_tracked hyprsunset hyprsunset
        else
            start_tracked hyprsunset "$program" -t "$temperature"
        fi
        ;;
    status)
        if pid=$(tracked_pid hyprsunset hyprsunset); then
            printf 'running %s\n' "$pid"
        else
            printf 'stopped\n'
            exit 1
        fi
        ;;
    *)
        fail 'nightlight needs a verb (toggle, status)'
        ;;
esac
