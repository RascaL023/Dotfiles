#!/usr/bin/env bash
# hypridle has no IPC, so atlanta owns the PID file of the instance it started.
set -u

dir=$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P) || exit 1
# shellcheck source=../lib/session.sh
source "$dir/lib/session.sh"
# shellcheck source=../lib/provider.sh
source "$dir/lib/provider.sh"
# shellcheck source=../lib/proc.sh
source "$dir/lib/proc.sh"

capability=${1:-idle}
if (( $# > 0 )); then
    shift
fi
verb=${1:-}

fail() {
    printf 'atlanta: %s\n' "$*" >&2
    exit 2
}

require_hyprland 'idle'
program=$(require_provider hypridle) || exit $?

case $verb in
    toggle)
        if tracked_pid hypridle hypridle >/dev/null; then
            stop_tracked hypridle hypridle
        else
            start_tracked hypridle "$program"
        fi
        ;;
    status)
        if pid=$(tracked_pid hypridle hypridle); then
            printf 'running %s\n' "$pid"
        else
            printf 'stopped\n'
            exit 1
        fi
        ;;
    *)
        fail 'idle needs a verb (toggle, status)'
        ;;
esac
