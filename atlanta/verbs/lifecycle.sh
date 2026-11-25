#!/usr/bin/env bash
# Start or stop the atlanta shell stack.
set -u

dir=$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P) || exit 1
# shellcheck source=../lib/provider.sh
source "$dir/lib/provider.sh"
# shellcheck source=../lib/state.sh
source "$dir/lib/state.sh"
# shellcheck source=../lib/bar.sh
source "$dir/lib/bar.sh"

action=${1:-}
if (( $# > 0 )); then
    shift
fi
if (( $# )); then
    printf 'atlanta: %s takes no arguments\n' "$action" >&2
    exit 2
fi

case $action in
    start|stop) ;;
    '') printf 'atlanta: lifecycle needs start or stop\n' >&2; exit 2 ;;
    *) printf 'atlanta: unknown lifecycle action: %s (start, stop)\n' "$action" >&2; exit 2 ;;
esac

# Eww runs behind eww-ctl: it owns the daemon and the island collector, so
# atlanta never calls `eww --config … daemon|kill` directly.

note() {
    printf '%s %s\n' "$1" "$2"
}

require_all() {
    local name
    for name in "$@"; do
        provider_resolve "$name" >/dev/null || {
            printf 'atlanta: %s is missing (check atlanta doctor)\n' "$name" >&2
            exit 127
        }
    done
}

awww_running() {
    timeout 2 "$awww" query >/dev/null 2>&1
}

swaync_running() {
    timeout 2 "$swaync_client" -c >/dev/null 2>&1
}

process_running() {
    local state
    [[ -r /proc/$1/stat ]] || return 1
    state=$(awk '{ print $3 }' "/proc/$1/stat" 2>/dev/null) || return 1
    [[ $state != Z ]]
}

waybar_running() {
    timeout 2 "$waybar_ctl" status >/dev/null 2>&1
}

# SwayNC 0.12.6 has no quit client flag. Its D-Bus owner is the provider
# identity; /proc verifies the PID before the signal, without pgrep/pkill.
swaync_pid() {
    local output pid arg
    local -a args=()

    output=$(timeout 2 "$busctl" --user status org.erikreider.swaync 2>/dev/null) || return 1
    pid=$(printf '%s\n' "$output" | awk -F= '$1 == "PID" { print $2; exit }')
    [[ $pid =~ ^[0-9]+$ && $pid -gt 1 ]] || return 1
    [[ -O /proc/$pid ]] || return 1

    mapfile -d '' -t args 2>/dev/null < "/proc/$pid/cmdline" || return 1
    for arg in "${args[@]}"; do
        [[ ${arg##*/} == swaync ]] || continue
        printf '%s\n' "$pid"
        return 0
    done
    return 1
}

start_awww() {
    if awww_running; then
        note 'already running' awww
        return 0
    fi
    nohup "$awww_daemon" >/dev/null 2>&1 &
    note started awww
}

start_eww() {
    local state
    state=$(bar_eww_daemon_state)
    case $state in
        running)
            note 'already running' eww
            return 0
            ;;
        unmanaged)
            # A daemon started outside eww-ctl has no island event FIFO; adopting
            # it is a deliberate action, not something `start` should do silently.
            note 'already running (not managed)' eww
            printf 'hint: run eww-ctl daemon restart to adopt it\n'
            return 0
            ;;
    esac
    "$eww_ctl" daemon start || {
        note 'failed to start' eww
        return 1
    }
    note started eww
}

start_swaync() {
    if swaync_running; then
        note 'already running' swaync
        return 0
    fi
    nohup "$swaync" >/dev/null 2>&1 &
    note started swaync
}

start_waybar() {
    if waybar_running; then
        note 'already running' waybar
        return 0
    fi
    "$waybar_ctl" start || {
        note 'failed to start' waybar
        return 1
    }
    note started waybar
}

start_island() {
    if [[ $(bar_eww_daemon_state) == unmanaged ]]; then
        printf 'island not started (unmanaged eww daemon)\n'
        return 0
    fi
    if bar_island_running "$eww_ctl"; then
        note 'already running' island
        return 0
    fi
    "$eww_ctl" bar island start || {
        note 'failed to start' island
        return 1
    }
    note started island
}

start_bar() {
    case $(bar_provider) in
        waybar) start_waybar ;;
        eww) start_island ;;
    esac
}

stop_waybar() {
    if ! waybar_running; then
        note 'not running' waybar
        return 0
    fi
    "$waybar_ctl" stop || {
        note 'failed to stop' waybar
        return 1
    }
    note stopped waybar
}

stop_bar() {
    case $(bar_provider) in
        waybar) stop_waybar ;;
        eww)
            # The daemon stop below closes the island and its collector.
            return 0
            ;;
    esac
}

stop_swaync() {
    local index pid
    if ! pid=$(swaync_pid); then
        note 'not running' swaync
        return 0
    fi
    kill -TERM -- "$pid" 2>/dev/null || :
    for (( index=0; index<50; index++ )); do
        process_running "$pid" || break
        sleep 0.02
    done
    if process_running "$pid"; then
        note 'failed to stop' swaync
        return 1
    fi
    note stopped swaync
}

stop_eww() {
    local status=0
    if [[ $(bar_eww_daemon_state) == stopped ]]; then
        note 'not running' eww
        return 0
    fi
    # daemon stop also closes every Eww window and stops the island collector.
    if "$eww_ctl" daemon stop; then
        note stopped eww
    else
        note 'failed to stop' eww
        status=1
    fi
    # Belt and braces: a daemon that answered `unknown` or survived a failed
    # stop still loses the measured window. `close` never starts a daemon.
    timeout 15 "$eww_ctl" close depth-clock >/dev/null 2>&1 || :
    return "$status"
}

stop_awww() {
    if ! awww_running; then
        note 'not running' awww
        return 0
    fi
    "$awww" kill >/dev/null 2>&1 || {
        note 'failed to stop' awww
        return 1
    }
    note stopped awww
}

case $action in
    start)
        start_requires=(awww-daemon awww eww-ctl eww swaync swaync-client)
        [[ $(bar_provider) == waybar ]] && start_requires+=(waybar-ctl)
        require_all "${start_requires[@]}"
        awww_daemon=$(provider_resolve awww-daemon)
        awww=$(provider_resolve awww)
        eww_ctl=$(provider_resolve eww-ctl)
        swaync=$(provider_resolve swaync)
        swaync_client=$(provider_resolve swaync-client)
        waybar_ctl=$(provider_resolve waybar-ctl)

        status=0
        start_awww || status=1
        start_eww || status=1
        start_swaync || status=1
        start_bar || status=1
        exit "$status"
        ;;
    stop)
        stop_requires=(awww eww-ctl eww busctl)
        [[ $(bar_provider) == waybar ]] && stop_requires+=(waybar-ctl)
        require_all "${stop_requires[@]}"
        awww=$(provider_resolve awww)
        eww_ctl=$(provider_resolve eww-ctl)
        busctl=$(provider_resolve busctl)
        waybar_ctl=$(provider_resolve waybar-ctl)

        status=0
        stop_bar || status=1
        stop_swaync || status=1
        stop_eww || status=1
        stop_awww || status=1
        exit "$status"
        ;;
esac
