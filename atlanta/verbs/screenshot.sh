#!/usr/bin/env bash
# grim writes the file; slurp and the compositor only describe the area.
set -u

dir=$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P) || exit 1
# shellcheck source=../lib/session.sh
source "$dir/lib/session.sh"
# shellcheck source=../lib/provider.sh
source "$dir/lib/provider.sh"

capability=${1:-screenshot}
if (( $# > 0 )); then
    shift
fi
verb=${1:-}
if (( $# > 0 )); then
    shift
fi

fail() {
    printf 'atlanta: %s\n' "$*" >&2
    exit 2
}

save_dir=${ATLANTA_SCREENSHOT_DIR:-$HOME/Pictures/Screenshots}

focused_output() {
    case $(session_name) in
        hyprland) hyprctl -j monitors 2>/dev/null | jq -r 'map(select(.focused))[0].name // empty' ;;
        niri) niri msg -j focused-output 2>/dev/null | jq -r '.name // empty' ;;
        *) return 0 ;;
    esac
}

window_geometry() {
    require_hyprland 'screenshot window'
    hyprctl activewindow -j 2>/dev/null |
        jq -r 'if (.address // null) == null or .mapped == false then empty
               else "\(.size[0])x\(.size[1])+\(.at[0])+\(.at[1])" end'
}

mkdir -p -- "$save_dir" || fail "cannot create $save_dir"
file=$save_dir/screenshot-$(date +%Y%m%d-%H%M%S).png

grim=$(require_provider grim) || exit $?

case $verb in
    region)
        slurp=$(require_provider slurp) || exit $?
        geometry=$("$slurp") || exit 0
        [[ -n $geometry ]] || exit 0
        "$grim" -g "$geometry" "$file"
        ;;
    screen)
        output=$(focused_output)
        if [[ -n $output ]]; then
            "$grim" -o "$output" "$file"
        else
            "$grim" "$file"
        fi
        ;;
    window)
        geometry=$(window_geometry)
        [[ -n $geometry ]] || fail 'no focused window'
        "$grim" -g "$geometry" "$file"
        ;;
    *)
        fail 'screenshot needs a verb (region, screen, window)'
        ;;
esac || exit 1

printf '%s\n' "$file"
notify-send -t 1500 -i camera-photo 'Screenshot saved' "${file##*/}" 2>/dev/null || :
