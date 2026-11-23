#!/usr/bin/env bash
# `bar` drives Waybar. `bar.panel` drives one Eww window through eww-ctl; they
# are separate providers with separate jobs, so one never starts the other.
set -u

dir=$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P) || exit 1
# shellcheck source=../lib/provider.sh
source "$dir/lib/provider.sh"

capability=${1:-bar}
if (( $# > 0 )); then
    shift
fi

fail() {
    printf 'atlanta: %s\n' "$*" >&2
    exit 2
}

# Windows a keybind may toggle. `islands` is excluded on purpose: opening it
# through eww-ctl's plain window path skips the collector, so the island must go
# through `bar show|hide|toggle`. `depth-clock` is excluded too; its geometry is
# measured by depth-ctl and synced with the wallpaper.
panels='profile distro calendar-popup music-popup'

case $capability in
    bar.panel)
        verb=${1:-}
        panel=${2:-}
        case $verb in
            toggle) ;;
            '') fail 'bar.panel needs a verb (toggle) and a panel' ;;
            *) fail "unknown bar.panel verb: $verb (toggle)" ;;
        esac
        [[ -n $panel ]] || fail "bar.panel toggle needs a panel ($panels)"
        (( $# <= 2 )) || fail "unexpected argument: $3"
        case $panel in
            islands)
                fail 'bar.panel does not toggle islands; use atlanta bar show|hide|toggle'
                ;;
            profile|distro|calendar-popup|music-popup) ;;
            *) fail "unknown panel: $panel ($panels)" ;;
        esac
        ctl=$(require_provider eww-ctl) || exit $?
        exec "$ctl" toggle "$panel"
        ;;
esac

provider=waybar
verb=''
while (( $# )); do
    case $1 in
        --provider)
            (( $# > 1 )) || fail '--provider needs a name (waybar, eww)'
            provider=$2
            shift 2
            ;;
        --provider=*)
            provider=${1#*=}
            shift
            ;;
        *)
            [[ -z $verb ]] || fail "unexpected argument: $1"
            verb=$1
            shift
            ;;
    esac
done

case $provider in
    waybar)
        ctl=$(require_provider waybar-ctl) || exit $?
        case $verb in
            show) exec "$ctl" start ;;
            hide) exec "$ctl" stop ;;
            toggle|restart|reload|status) exec "$ctl" "$verb" ;;
            '') fail 'bar needs a verb (show, hide, toggle, restart, reload, status)' ;;
            *) fail "unknown bar verb: $verb" ;;
        esac
        ;;
    eww)
        # The island lives on the shared Eww daemon; eww-ctl owns both.
        ctl=$(require_provider eww-ctl) || exit $?
        case $verb in
            show) exec "$ctl" bar island start ;;
            hide) exec "$ctl" bar island stop ;;
            toggle) exec "$ctl" bar island toggle ;;
            reload) exec "$ctl" bar island reload ;;
            status) exec "$ctl" bar island status ;;
            restart)
                printf 'atlanta: bar has no Eww island restart; use bar reload or eww-ctl daemon restart\n' >&2
                exit 3
                ;;
            '') fail 'bar needs a verb (show, hide, toggle, reload, status)' ;;
            *) fail "unknown bar verb: $verb" ;;
        esac
        ;;
    *)
        fail "unknown bar provider: $provider (waybar, eww)"
        ;;
esac
