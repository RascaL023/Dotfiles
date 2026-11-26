#!/usr/bin/env bash
# Feel always belongs to matugen, on both shells: Noctalia reads its own
# settings.toml and never theme/feel/current. Windows, terminals and rofi keep
# one look whichever shell is active.
set -u

dir=${CONSTELLIA_DIR:-$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P)} || exit 1
# shellcheck source=../lib/backend.sh
source "$dir/lib/backend.sh"

capability=${1:-feel}
if (( $# > 0 )); then
    shift
fi
profile=${1:-}

if [[ -z $profile ]]; then
    printf 'constellia: feel needs a profile (see matugen-ctl list)\n' >&2
    exit 2
fi
shift

run_backend matugen-ctl feel "$profile" --wm "${CONSTELLIA_WM:-unknown}" "$@"
