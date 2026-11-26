#!/usr/bin/env bash
# atlanta keeps the only wallpaper index, so the atlanta side delegates instead
# of computing next/prev here. The two shells never share a wallpaper.
set -u

dir=${CONSTELLIA_DIR:-$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P)} || exit 1
# shellcheck source=../lib/backend.sh
source "$dir/lib/backend.sh"
# shellcheck source=../lib/state.sh
source "$dir/lib/state.sh"

capability=${1:-wallpaper}
if (( $# > 0 )); then
    shift
fi
verb=${1:-}
if (( $# > 0 )); then
    shift
fi
shell=$(shell_get)

fail() {
    printf 'constellia: %s\n' "$*" >&2
    exit 2
}

case $verb in
    set|next|prev|random|pick|status) ;;
    '') fail 'wallpaper needs a verb (set, next, prev, random, pick, status)' ;;
    *) fail "unknown wallpaper verb: $verb (set, next, prev, random, pick, status)" ;;
esac

if [[ $shell == atlanta ]]; then
    run_backend atlanta wallpaper "$verb" "$@"
fi

case $verb in
    set)
        [[ -n ${1:-} ]] || fail 'wallpaper set needs an image path'
        run_backend noctalia msg wallpaper-set "$1"
        ;;
    next) run_backend noctalia msg wallpaper-next ;;
    prev) run_backend noctalia msg wallpaper-previous ;;
    random) run_backend noctalia msg wallpaper-random ;;
    pick) run_backend noctalia msg panel-toggle launcher ;;
    status) run_backend noctalia msg wallpaper-get ;;
esac
