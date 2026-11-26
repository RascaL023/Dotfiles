#!/usr/bin/env bash
# Palette engine follows the shell; both engines flip the same store symlink,
# so switching shells never forces a re-render. Only the variant is stored.
set -u

dir=${CONSTELLIA_DIR:-$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P)} || exit 1
# shellcheck source=../lib/backend.sh
source "$dir/lib/backend.sh"
# shellcheck source=../lib/state.sh
source "$dir/lib/state.sh"

capability=${1:-theme}
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
    palette|status) ;;
    '') fail 'theme needs a verb (palette, status)' ;;
    *) fail "unknown theme verb: $verb (palette, status)" ;;
esac

theme_backend() {
    if [[ $shell == noctalia ]]; then
        printf 'noctalia-ctl'
    else
        printf 'matugen-ctl'
    fi
}

# The first bare argument that looks like a palette source. Consumer names and
# option values are skipped, so `palette -s vibrant img.png kitty` still works.
palette_source() {
    local arg lower skip=0
    for arg in "$@"; do
        if (( skip )); then
            skip=0
            continue
        fi
        case $arg in
            -s|--scheme)
                skip=1
                continue
                ;;
            --scheme=*|-*)
                continue
                ;;
        esac
        lower=${arg,,}
        case $lower in
            *.json|*.png|*.jpg|*.jpeg|*.webp|*.gif|*.bmp)
                printf '%s\n' "$arg"
                return 0
                ;;
        esac
    done
    return 1
}

palette_no_exec() {
    local arg
    for arg in "$@"; do
        case $arg in
            -n|--dry-run) return 0 ;;
        esac
    done
    return 1
}

# kanagawa-dark -> dark; kanagawa-light -> light; an image keeps dark.
variant_from_source() {
    local base=${1##*/}
    base=${base%.*}
    base=${base,,}
    case $base in
        *dark*) printf 'dark' ;;
        *light*) printf 'light' ;;
        *) printf 'dark' ;;
    esac
}

theme_palette() {
    local backend source variant status
    backend=$(theme_backend)
    if (( ${CONSTELLIA_DRY_RUN:-0} )); then
        dry_print "$backend" palette "$@"
        return 0
    fi
    source=$(palette_source "$@") || :
    invoke "$backend" palette "$@"
    status=$?
    (( status == 0 )) || exit "$status"
    [[ -n $source ]] || return 0
    palette_no_exec "$@" && return 0
    variant=$(variant_from_source "$source")
    theme_save "$variant" || {
        printf 'constellia: cannot write theme state in %s\n' "$constellia_state" >&2
        exit 1
    }
}

theme_status() {
    local engine palette feel variant
    engine=$(palette_engine)
    palette=$(palette_name)
    feel=$(feel_profile)
    variant=$(theme_variant)
    if (( ${CONSTELLIA_JSON:-0} )); then
        printf '{"engine":%s,"palette":%s,"variant":%s,"feel":%s,"wm":%s,"shell":%s}\n' \
            "$(json_or_null "$engine")" "$(json_or_null "$palette")" \
            "$(json_or_null "$variant")" "$(json_or_null "$feel")" \
            "$(json_or_null "${CONSTELLIA_WM:-unknown}")" \
            "$(json_or_null "$shell")"
        return 0
    fi
    printf '%-8s %s\n' engine "${engine:-none}"
    printf '%-8s %s\n' palette "${palette:-none}"
    printf '%-8s %s\n' variant "${variant:-unknown}"
    printf '%-8s %s\n' feel "${feel:-none}"
    printf '%-8s %s\n' wm "${CONSTELLIA_WM:-unknown}"
    printf '%-8s %s\n' shell "$shell"
}

case $verb in
    palette)
        theme_palette "$@"
        ;;
    status)
        (( $# == 0 )) || fail 'theme status takes no arguments'
        theme_status
        ;;
esac
