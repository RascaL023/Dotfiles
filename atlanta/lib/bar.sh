# Bar providers. The selected provider lives in state.sh; this file maps the
# same bar verbs onto each provider so `bar` means "the selected bar".

bar_eww_daemon_state() {
    local ctl=${eww_ctl:-} output
    if [[ -z $ctl ]]; then
        ctl=$(provider_resolve eww-ctl) || {
            printf 'missing\n'
            return 1
        }
    fi
    # A timeout or a garbled answer is `unknown`, never `stopped`: a live
    # daemon reported as stopped makes `atlanta stop` skip `daemon stop`.
    if ! output=$(timeout 10 "$ctl" daemon status 2>/dev/null); then
        printf 'unknown\n'
        return 1
    fi
    case $output in
        'running pid '*) printf 'running\n' ;;
        'running (not managed)') printf 'unmanaged\n' ;;
        'stopped') printf 'stopped\n' ;;
        *) printf 'unknown\n' ;;
    esac
}

bar_island_running() {
    local output
    output=$(timeout 2 "$1" bar island status 2>/dev/null) || return 1
    [[ $output == *islands* ]]
}

bar_start() {
    local ctl
    case $1 in
        waybar)
            ctl=$(require_provider waybar-ctl) || return $?
            "$ctl" start
            ;;
        eww)
            ctl=$(require_provider eww-ctl) || return $?
            case $(bar_eww_daemon_state) in
                unmanaged)
                    printf 'atlanta: the Eww daemon is unmanaged; run eww-ctl daemon restart to adopt it\n' >&2
                    return 3
                    ;;
                stopped|unknown)
                    "$ctl" daemon start || return 1
                    ;;
            esac
            "$ctl" bar island start
            ;;
        *) return 2 ;;
    esac
}

bar_stop() {
    local ctl
    case $1 in
        waybar)
            ctl=$(require_provider waybar-ctl) || return $?
            "$ctl" stop
            ;;
        eww)
            ctl=$(require_provider eww-ctl) || return $?
            "$ctl" bar island stop
            ;;
        *) return 2 ;;
    esac
}

bar_toggle() {
    local ctl
    case $1 in
        waybar)
            ctl=$(require_provider waybar-ctl) || return $?
            "$ctl" toggle
            ;;
        eww)
            ctl=$(require_provider eww-ctl) || return $?
            "$ctl" bar island toggle
            ;;
        *) return 2 ;;
    esac
}

bar_reload() {
    local ctl
    case $1 in
        waybar)
            ctl=$(require_provider waybar-ctl) || return $?
            "$ctl" reload
            ;;
        eww)
            ctl=$(require_provider eww-ctl) || return $?
            "$ctl" bar island reload
            ;;
        *) return 2 ;;
    esac
}

# Waybar restarts its process; the island reloads in place on the shared daemon.
bar_restart() {
    local ctl
    case $1 in
        waybar)
            ctl=$(require_provider waybar-ctl) || return $?
            "$ctl" restart
            ;;
        eww) bar_reload "$1" ;;
        *) return 2 ;;
    esac
}

bar_status() {
    local ctl
    case $1 in
        waybar)
            ctl=$(require_provider waybar-ctl) || return $?
            "$ctl" status
            ;;
        eww)
            ctl=$(require_provider eww-ctl) || return $?
            "$ctl" bar island status
            ;;
        *) return 2 ;;
    esac
}

bar_dispatch() {
    case $2 in
        show) bar_start "$1" ;;
        hide) bar_stop "$1" ;;
        toggle) bar_toggle "$1" ;;
        reload) bar_reload "$1" ;;
        restart) bar_restart "$1" ;;
        status) bar_status "$1" ;;
        *) return 2 ;;
    esac
}
