#!/usr/bin/env bash
# awww displays the image; atlanta keeps only the index of the last one.
set -u

dir=$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P) || exit 1
# shellcheck source=../lib/provider.sh
source "$dir/lib/provider.sh"
# shellcheck source=../lib/state.sh
source "$dir/lib/state.sh"

capability=${1:-wallpaper}
if (( $# > 0 )); then
    shift
fi
verb=${1:-status}
if (( $# > 0 )); then
    shift
fi

fail() {
    printf 'atlanta: %s\n' "$*" >&2
    exit 2
}

sync_depth() {
    local depth
    depth=$(provider_resolve depth-ctl) || return 0
    "$depth" wallpaper "$1" >/dev/null 2>&1 || :
}

apply_wallpaper() {
    local path=$1 awww index=0 found=-1
    [[ -f $path ]] || fail "wallpaper not found: $path"

    awww=$(require_provider awww) || exit $?
    "$awww" query >/dev/null 2>&1 || "$awww" init >/dev/null 2>&1 || :
    "$awww" img "$path" \
        --transition-type center --transition-fps 60 --transition-step 200 || exit 1
    sync_depth "$path"

    while IFS= read -r candidate; do
        [[ $candidate == "$path" ]] && found=$index
        index=$(( index + 1 ))
    done < <(wallpaper_images)
    (( found >= 0 )) && wallpaper_index_save "$found"
    printf '%s\n' "$path"
}

count_images() {
    local -a images=()
    mapfile -t images < <(wallpaper_images)
    printf '%s\n' "${#images[@]}"
}

case $verb in
    set)
        [[ -n ${1:-} ]] || fail 'wallpaper set needs an image path'
        apply_wallpaper "$1"
        ;;
    pick)
        ctl=$(require_provider rofi-ctl) || exit $?
        selected=$("$ctl" wallpaper -d "$wallpaper_dir") || exit $?
        [[ -n $selected ]] || exit 0
        apply_wallpaper "$selected"
        ;;
    next|prev|random)
        count=$(count_images)
        (( count )) || fail "no wallpaper images in $wallpaper_dir"
        index=$(wallpaper_index)
        case $verb in
            next) index=$(( (index + 1) % count )) ;;
            prev) index=$(( (index - 1 + count) % count )) ;;
            random)
                index=$(( RANDOM % count ))
                if (( count > 1 && index == $(wallpaper_index) )); then
                    index=$(( (index + 1) % count ))
                fi
                ;;
        esac
        apply_wallpaper "$(wallpaper_at "$index")"
        ;;
    status)
        count=$(count_images)
        (( count )) || fail "no wallpaper images in $wallpaper_dir"
        index=$(wallpaper_index)
        printf '%s (%s/%s)\n' "$(wallpaper_at "$index")" "$(( index % count ))" "$count"
        ;;
    *)
        fail 'wallpaper needs a verb (set, next, prev, random, pick, status)'
        ;;
esac
