#!/usr/bin/env bash
# swayidle has no IPC, so atlanta owns the PID file of the instance it started.
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

require_session 'idle' hyprland niri
program=$(require_provider swayidle) || exit $?

# swayidle runs each event through `sh -c`, so the commands are strings. DPMS
# is the only compositor-specific action; `session dpms` owns that switch.
printf -v dpms_off '%q session dpms off' "$dir/atlanta"
printf -v dpms_on '%q session dpms on' "$dir/atlanta"
printf -v lock_screen '%q session lock' "$dir/atlanta"

idle_events=(
    timeout 300 'loginctl lock-session'
    timeout 330 "$dpms_off"
    resume "$dpms_on && notify-send -t 3000 Idle 'Welcome back' 2>/dev/null || :"
    timeout 600 'systemctl suspend'
    before-sleep 'loginctl lock-session'
    after-resume "$dpms_on"
    lock "$lock_screen"
    idlehint 300
)

case $verb in
    toggle)
        if tracked_pid idle swayidle >/dev/null; then
            stop_tracked idle swayidle
        else
            start_tracked idle "$program" "${idle_events[@]}"
        fi
        ;;
    status)
        if pid=$(tracked_pid idle swayidle); then
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
