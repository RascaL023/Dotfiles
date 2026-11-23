#!/usr/bin/env bash
# `bar` drives the selected bar provider. `bar.panel` drives one Eww window
# through eww-ctl; the panel stays independent of the selected bar.
set -u

dir=$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P) || exit 1
# shellcheck source=../lib/provider.sh
source "$dir/lib/provider.sh"
# shellcheck source=../lib/state.sh
source "$dir/lib/state.sh"
# shellcheck source=../lib/bar.sh
source "$dir/lib/bar.sh"

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

provider_override=''
verb=''
arguments=()
while (( $# )); do
    case $1 in
        --provider)
            (( $# > 1 )) || fail '--provider needs a name (waybar, eww)'
            provider_override=$2
            shift 2
            ;;
        --provider=*)
            provider_override=${1#*=}
            shift
            ;;
        *)
            arguments+=("$1")
            shift
            ;;
    esac
done

(( ${#arguments[@]} <= 2 )) || fail "unexpected argument: ${arguments[2]}"
verb=${arguments[0]:-}
provider_argument=${arguments[1]:-}

# `use` stores the preference and leaves every bar alone. `switch` stops the
# provider recorded in state, then starts the new one; neither scans for a
# second running bar, so drift can leave both visible. See README.
case $verb in
    use|switch)
        [[ -z $provider_override ]] || fail "bar $verb takes the provider as its argument, not --provider"
        [[ -n $provider_argument ]] || fail "bar $verb needs a provider (waybar, eww)"
        bar_provider_valid "$provider_argument" || \
            fail "unknown bar provider: $provider_argument (waybar, eww)"
        if [[ $verb == switch ]]; then
            previous=$(bar_provider)
            if [[ $previous != "$provider_argument" ]]; then
                if ! bar_stop "$previous" >/dev/null 2>&1; then
                    printf 'atlanta: could not stop the %s bar\n' "$previous" >&2
                fi
            fi
        fi
        bar_provider_save "$provider_argument" || {
            printf 'atlanta: could not save the bar provider\n' >&2
            exit 1
        }
        printf 'bar provider: %s\n' "$provider_argument"
        [[ $verb == switch ]] || exit 0
        bar_start "$provider_argument"
        exit $?
        ;;
esac

provider=${provider_override:-$(bar_provider)}
bar_provider_valid "$provider" || \
    fail "unknown bar provider: $provider (waybar, eww)"
[[ -z $provider_argument ]] || fail "unexpected argument: $provider_argument"
[[ -n $verb ]] || fail 'bar needs a verb (show, hide, toggle, restart, reload, status)'
case $verb in
    show|hide|toggle|restart|reload|status) ;;
    *) fail "unknown bar verb: $verb" ;;
esac

bar_dispatch "$provider" "$verb"
exit $?
