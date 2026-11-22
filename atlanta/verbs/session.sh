#!/usr/bin/env bash
# Session actions. wlogout is tracked so a second call closes it instead of
# stacking another layer surface.
set -u

dir=$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P) || exit 1
# shellcheck source=../lib/session.sh
source "$dir/lib/session.sh"
# shellcheck source=../lib/provider.sh
source "$dir/lib/provider.sh"
# shellcheck source=../lib/proc.sh
source "$dir/lib/proc.sh"

capability=${1:-session}
if (( $# > 0 )); then
    shift
fi
verb=${1:-}

fail() {
    printf 'atlanta: %s\n' "$*" >&2
    exit 2
}

case $verb in
    menu)
        wlogout=$(require_provider wlogout) || exit $?
        if tracked_pid wlogout wlogout >/dev/null; then
            stop_tracked wlogout wlogout
            exit 0
        fi
        start_tracked wlogout "$wlogout" -b 4 -n -m 100
        ;;
    lock)
        require_session 'session lock' hyprland niri
        run_provider hyprlock
        ;;
    logout)
        run_provider loginctl terminate-user "$USER"
        ;;
    reboot)
        run_provider systemctl reboot
        ;;
    poweroff)
        run_provider systemctl poweroff
        ;;
    *)
        fail 'session needs a verb (menu, lock, logout, reboot, poweroff)'
        ;;
esac
