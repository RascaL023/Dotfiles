#!/usr/bin/env bash
# Shell preference and lifecycle. `switch` proves the target is alive before it
# writes state; `start`/`stop` never write state and never switch silently.
set -u

dir=${CONSTELLIA_DIR:-$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P)} || exit 1
# shellcheck source=../lib/backend.sh
source "$dir/lib/backend.sh"
# shellcheck source=../lib/state.sh
source "$dir/lib/state.sh"
# shellcheck source=../lib/session.sh
source "$dir/lib/session.sh"

capability=${1:-shell}
if (( $# > 0 )); then
    shift
fi
verb=${1:-}
if (( $# > 0 )); then
    shift
fi

fail() {
    printf 'constellia: %s\n' "$*" >&2
    exit 2
}

runtime_fail() {
    printf 'constellia: %s\n' "$*" >&2
    exit 1
}

case $verb in
    status|use|select|switch|start|stop) ;;
    '') fail 'shell needs a verb (status, use, select, switch, start, stop)' ;;
    *) fail "unknown shell verb: $verb (status, use, select, switch, start, stop)" ;;
esac

shell_use() {
    local target=${1:-}
    (( $# == 1 )) || fail 'shell use needs exactly one shell (noctalia, atlanta)'
    shell_valid "$target" || fail "unknown shell: $target (noctalia, atlanta)"
    require_wm 'shell use'
    shell_save "$target" || runtime_fail "cannot write state in $constellia_shell_dir"
    printf 'shell %s: %s\n' "$CONSTELLIA_WM" "$target"
}

plan_switch() {
    case $1 in
        noctalia)
            dry_print atlanta stop
            dry_print wait org.freedesktop.Notifications free "${constellia_bus_ms}ms"
            dry_print noctalia -d
            dry_print wait noctalia ready "${constellia_ready_ms}ms"
            ;;
        atlanta)
            dry_print pkill -TERM -f "$noctalia_pattern"
            dry_print atlanta start
            ;;
    esac
    dry_print write "$constellia_shell_dir/${CONSTELLIA_WM}=$1"
}

stop_atlanta() {
    if ! backend_path atlanta >/dev/null; then
        printf 'constellia: atlanta is not installed; nothing to stop\n'
        return 0
    fi
    if ! invoke atlanta stop; then
        printf 'constellia: atlanta stop failed; nothing else was changed\n' >&2
        exit 1
    fi
}

restore_atlanta() {
    if invoke atlanta start; then
        printf 'constellia: atlanta restored; state unchanged\n' >&2
    else
        printf 'constellia: atlanta could not be restored; run constellia shell start\n' >&2
    fi
}

# A half-started atlanta stack can hold the notification bus, so stop it before
# giving the bus back to noctalia.
restore_noctalia() {
    invoke atlanta stop >/dev/null 2>&1 || :
    if start_noctalia && wait_noctalia_ready; then
        printf 'constellia: noctalia restored; state unchanged\n' >&2
    else
        printf 'constellia: noctalia could not be restored; run constellia shell start\n' >&2
    fi
}

refuse_second_stack() {
    local running=$1 recorded=$2
    printf 'constellia: %s is running while this WM records %s; refusing to start a second stack\n' "$running" "$recorded" >&2
    printf 'hint: constellia shell switch %s\n' "$running" >&2
    exit 4
}

switch_to_noctalia() {
    local owner bus_state
    stop_atlanta
    if noctalia_running; then
        # Hybrid session: adopt the daemon that already holds the bus instead
        # of refusing a switch to the shell that is already alive.
        if ! wait_noctalia_ready; then
            printf 'constellia: noctalia is running but did not answer\n' >&2
            exit 1
        fi
        return 0
    fi
    wait_bus_free
    bus_state=$?
    if (( bus_state != 0 )); then
        if (( bus_state == 1 )); then
            owner=$(bus_owner_pid) || owner=unknown
            printf 'constellia: org.freedesktop.Notifications is still owned (pid %s); atlanta was stopped, restoring it\n' "$owner" >&2
        else
            printf 'constellia: cannot query org.freedesktop.Notifications; atlanta was stopped, restoring it\n' >&2
        fi
        restore_atlanta
        exit 4
    fi
    if ! start_noctalia; then
        printf 'constellia: noctalia failed to start; state not written\n' >&2
        restore_atlanta
        exit 1
    fi
    if ! wait_noctalia_ready; then
        printf 'constellia: noctalia started but did not answer; state not written\n' >&2
        stop_noctalia
        restore_atlanta
        exit 1
    fi
}

switch_to_atlanta() {
    stop_noctalia || exit 1
    if ! invoke atlanta start; then
        printf 'constellia: atlanta start failed; state not written\n' >&2
        restore_noctalia
        exit 1
    fi
}

# Shared by `switch` and `select`: prove the target, then write state last.
shell_switch() {
    local target=$1 current
    current=$(shell_get)
    if [[ $current == "$target" ]]; then
        printf 'shell %s is already %s\n' "$CONSTELLIA_WM" "$target"
        exit 0
    fi
    if (( CONSTELLIA_DRY_RUN )); then
        plan_switch "$target"
        exit 0
    fi
    case $target in
        noctalia) switch_to_noctalia ;;
        atlanta) switch_to_atlanta ;;
    esac
    shell_save "$target" || runtime_fail "cannot write state in $constellia_shell_dir"
    printf 'shell %s: %s\n' "$CONSTELLIA_WM" "$target"
}

# Rofi owns the card; constellia owns the action. Let rofi exit first, so its
# keyboard grab is gone before the other stack is stopped.
shell_select() {
    local choice target row=0 rofi status
    (( $# == 0 )) || fail 'shell select takes no arguments'
    require_wm 'shell select'
    [[ $(shell_get) == atlanta ]] && row=1
    if (( CONSTELLIA_DRY_RUN )); then
        dry_print rofi-ctl shell -selected-row "$row"
        return 0
    fi
    rofi=$(require_backend rofi-ctl) || exit $?
    choice=$("$rofi" shell -selected-row "$row") || {
        status=$?
        # Cancelling the picker is not a failure and changes nothing.
        (( status == 1 )) && exit 0
        exit "$status"
    }
    case $choice in
        # `Native` is accepted so an older card label keeps working.
        Noctalia|noctalia)      target=noctalia ;;
        Native|Atlanta|atlanta) target=atlanta ;;
        '')                     exit 0 ;;
        *)                      fail "unknown shell choice: $choice (Noctalia, Atlanta)" ;;
    esac
    shell_switch "$target"
}

shell_start() {
    local current
    require_wm 'shell start'
    current=$(shell_get)
    case $current in
        atlanta)
            if (( ! CONSTELLIA_DRY_RUN )) && noctalia_running; then
                refuse_second_stack noctalia atlanta
            fi
            invoke atlanta start
            exit $?
            ;;
        noctalia)
            if (( CONSTELLIA_DRY_RUN )); then
                start_noctalia
                wait_noctalia_ready
                return 0
            fi
            if noctalia_running; then
                note 'already running' noctalia
                return 0
            fi
            atlanta_running && refuse_second_stack atlanta noctalia
            start_noctalia || exit 1
            if ! wait_noctalia_ready; then
                printf 'constellia: noctalia did not answer\n' >&2
                exit 1
            fi
            ;;
    esac
}

shell_stop() {
    local current
    require_wm 'shell stop'
    current=$(shell_get)
    case $current in
        atlanta) invoke atlanta stop ;;
        noctalia) stop_noctalia ;;
    esac
}

case $verb in
    status)
        exec bash "$dir/verbs/report.sh" status "$@"
        ;;
    use)
        shell_use "$@"
        ;;
    select)
        shell_select "$@"
        ;;
    switch)
        target=${1:-}
        (( $# == 1 )) || fail 'shell switch needs exactly one shell (noctalia, atlanta)'
        shell_valid "$target" || fail "unknown shell: $target (noctalia, atlanta)"
        require_wm 'shell switch'
        shell_switch "$target"
        ;;
    start)
        (( $# == 0 )) || fail 'shell start takes no arguments'
        shell_start
        ;;
    stop)
        (( $# == 0 )) || fail 'shell stop takes no arguments'
        shell_stop
        ;;
esac
