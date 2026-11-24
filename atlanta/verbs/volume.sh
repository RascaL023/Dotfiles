#!/usr/bin/env bash
# Volume changes live here so keybinds never carry wpctl invocations.
set -u

dir=$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P) || exit 1
# shellcheck source=../lib/provider.sh
source "$dir/lib/provider.sh"
# shellcheck source=../lib/feedback.sh
source "$dir/lib/feedback.sh"

capability=${1:-volume}
if (( $# > 0 )); then
    shift
fi
verb=${1:-}

fail() {
    printf 'atlanta: %s\n' "$*" >&2
    exit 2
}

step=${ATLANTA_VOLUME_STEP:-0.05}
wpctl=$(require_provider wpctl) || exit $?

case $verb in
    up) "$wpctl" set-volume @DEFAULT_AUDIO_SINK@ "${step}+" -l 1.0 || exit 1 ;;
    down) "$wpctl" set-volume @DEFAULT_AUDIO_SINK@ "${step}-" -l 1.0 || exit 1 ;;
    mute) "$wpctl" set-mute @DEFAULT_AUDIO_SINK@ toggle || exit 1 ;;
    *) fail 'volume needs a verb (up, down, mute)' ;;
esac

level=$(wpctl_level "$wpctl" @DEFAULT_AUDIO_SINK@) || exit 1
notify_osd Volume audio-volume-high "$level"
