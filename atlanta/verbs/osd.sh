#!/usr/bin/env bash
# OSD reports only; the mutation lives in volume, mic and brightness.
set -u

dir=$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P) || exit 1
# shellcheck source=../lib/provider.sh
source "$dir/lib/provider.sh"
# shellcheck source=../lib/feedback.sh
source "$dir/lib/feedback.sh"

capability=${1:-osd}
if (( $# > 0 )); then
    shift
fi
verb=${1:-}

fail() {
    printf 'atlanta: %s\n' "$*" >&2
    exit 2
}

case $verb in
    volume)
        wpctl=$(require_provider wpctl) || exit $?
        level=$(wpctl_level "$wpctl" @DEFAULT_AUDIO_SINK@) || exit 1
        notify_osd Volume audio-volume-high "$level"
        ;;
    mic)
        wpctl=$(require_provider wpctl) || exit $?
        level=$(wpctl_level "$wpctl" @DEFAULT_AUDIO_SOURCE@) || exit 1
        notify_osd Microphone audio-input-microphone "$level"
        ;;
    brightness)
        brightnessctl=$(require_provider brightnessctl) || exit $?
        level=$(brightness_level "$brightnessctl") ||
            fail 'brightnessctl could not report a level'
        notify_osd Brightness display-brightness-symbolic "$level"
        ;;
    *)
        fail 'osd needs a verb (volume, mic, brightness)'
        ;;
esac
