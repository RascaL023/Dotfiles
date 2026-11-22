# Provider resolution: ATLANTA_PROVIDER_DIR (tests), then this checkout, then
# PATH. A ctl installed only in the repo must stay reachable.

atlanta_dir=$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P) || exit 1
atlanta_repo=$(CDPATH= cd -- "$atlanta_dir/.." && pwd -P) || exit 1

provider_repo_subdir() {
    case $1 in
        rofi-ctl) printf 'rofi\n' ;;
        waybar-ctl) printf 'waybar\n' ;;
        barctl) printf 'eww/bar\n' ;;
        matugen-ctl) printf 'matugen\n' ;;
        depth-ctl) printf 'eww/script\n' ;;
        *) return 1 ;;
    esac
}

provider_resolve() {
    local name=$1 subdir candidate
    if [[ -n ${ATLANTA_PROVIDER_DIR:-} && -x $ATLANTA_PROVIDER_DIR/$name ]]; then
        printf '%s\n' "$ATLANTA_PROVIDER_DIR/$name"
        return 0
    fi
    if subdir=$(provider_repo_subdir "$name"); then
        candidate=$atlanta_repo/$subdir/$name
        if [[ -x $candidate ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    fi
    command -v "$name" 2>/dev/null
}

require_provider() {
    local path
    path=$(provider_resolve "$1") || {
        printf 'atlanta: %s is missing (check atlanta doctor)\n' "$1" >&2
        exit 127
    }
    printf '%s\n' "$path"
}

run_provider() {
    local path
    path=$(require_provider "$1") || exit 1
    shift
    exec "$path" "$@"
}
