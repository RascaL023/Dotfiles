#!/usr/bin/env bash
# One bar provider is active at a time. Waybar is the focus; Eww keeps its
# slot so adding it later means filling in one branch, not reshaping the verb.
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

case $capability in
    bar.panel)
        printf 'atlanta: bar.panel is reserved; the Eww bar provider is not active yet\n' >&2
        exit 3
        ;;
esac

provider=waybar
verb=''
while (( $# )); do
    case $1 in
        --provider)
            (( $# > 1 )) || fail '--provider needs a name (waybar)'
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
    waybar) ;;
    eww)
        printf 'atlanta: bar provider eww is not active yet; waybar is the focus\n' >&2
        exit 3
        ;;
    *)
        fail "unknown bar provider: $provider (waybar)"
        ;;
esac

ctl=$(require_provider waybar-ctl) || exit $?

case $verb in
    show) exec "$ctl" start ;;
    hide) exec "$ctl" stop ;;
    toggle|restart|reload|status) exec "$ctl" "$verb" ;;
    '') fail 'bar needs a verb (show, hide, toggle, restart, reload, status)' ;;
    *) fail "unknown bar verb: $verb" ;;
esac
