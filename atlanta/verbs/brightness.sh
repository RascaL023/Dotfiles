#!/usr/bin/env bash
# Backlight changes live here so keybinds never carry brightnessctl invocations.
set -u

dir=$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P) || exit 1
# shellcheck source=../lib/provider.sh
source "$dir/lib/provider.sh"
# shellcheck source=../lib/feedback.sh
source "$dir/lib/feedback.sh"

capability=${1:-brightness}
if (( $# > 0 )); then
    shift
fi
verb=${1:-}

fail() {
    printf 'atlanta: %s\n' "$*" >&2
    exit 2
}

step=${ATLANTA_BRIGHTNESS_STEP:-5%}
ctl=$(require_provider brightnessctl) || exit $?

case $verb in
    up) "$ctl" -q set "+$step" || exit 1 ;;
    down) "$ctl" -q set "$step-" || exit 1 ;;
    *) fail 'brightness needs a verb (up, down)' ;;
esac

level=$(brightness_level "$ctl") || fail 'brightnessctl could not report a level'
notify_osd Brightness display-brightness-symbolic "$level"
