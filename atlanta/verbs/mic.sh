#!/usr/bin/env bash
# Microphone mute, reported through the same bubble as volume.
set -u

dir=$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P) || exit 1
# shellcheck source=../lib/provider.sh
source "$dir/lib/provider.sh"
# shellcheck source=../lib/feedback.sh
source "$dir/lib/feedback.sh"

capability=${1:-mic}
if (( $# > 0 )); then
    shift
fi
verb=${1:-}

fail() {
    printf 'atlanta: %s\n' "$*" >&2
    exit 2
}

wpctl=$(require_provider wpctl) || exit $?

case $verb in
    toggle) "$wpctl" set-mute @DEFAULT_AUDIO_SOURCE@ toggle || exit 1 ;;
    *) fail 'mic needs a verb (toggle)' ;;
esac

level=$(wpctl_level "$wpctl" @DEFAULT_AUDIO_SOURCE@) || exit 1
notify_osd Microphone audio-input-microphone "$level"
