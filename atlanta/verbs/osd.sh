#!/usr/bin/env bash
# OSD reports; it never changes a level. Keybinds keep owning the mutation.
set -u

dir=$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P) || exit 1
# shellcheck source=../lib/provider.sh
source "$dir/lib/provider.sh"

capability=${1:-osd}
if (( $# > 0 )); then
    shift
fi
verb=${1:-}

fail() {
    printf 'atlanta: %s\n' "$*" >&2
    exit 2
}

notify() {
    notify-send -h string:x-canonical-private-synchronous:atlanta-osd \
        -t 1500 -i "$2" "$1" "$3" 2>/dev/null || :
    printf '%s %s\n' "$1" "$3"
}

wpctl_level() {
    wpctl get-volume "$1" | awk '{ printf "%d%s", $2 * 100, ($3 == "[MUTED]" ? " (muted)" : "") }'
}

case $verb in
    volume)
        wpctl=$(require_provider wpctl) || exit $?
        level=$(wpctl_level @DEFAULT_AUDIO_SINK@)
        notify Volume audio-volume-high "$level%"
        ;;
    mic)
        wpctl=$(require_provider wpctl) || exit $?
        level=$(wpctl_level @DEFAULT_AUDIO_SOURCE@)
        notify Microphone audio-input-microphone "$level%"
        ;;
    brightness)
        brightnessctl=$(require_provider brightnessctl) || exit $?
        current=$("$brightnessctl" get) || exit 1
        maximum=$("$brightnessctl" max) || exit 1
        (( maximum > 0 )) || fail 'brightnessctl reports a zero maximum'
        notify Brightness display-brightness-symbolic "$(( current * 100 / maximum ))%"
        ;;
    *)
        fail 'osd needs a verb (volume, mic, brightness)'
        ;;
esac
