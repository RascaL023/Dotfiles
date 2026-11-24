#!/usr/bin/env bash
set -u

usage() {
    cat <<'EOF'
Usage: install.sh [--dry-run] [--remove]

  no flag     Create the symlinks (idempotent, safe to re-run)
  --dry-run   Print what would change and touch nothing
  --remove    Remove only the symlinks that point into this checkout
  -h, --help  This text

Links:
  atlanta                     -> ~/.local/bin/atlanta
  completions/atlanta.fish    -> ~/.config/fish/completions/atlanta.fish

BIN_DIR and FISH_COMPLETION_DIR override the two destinations.
Exit: 0 ok, 1 conflict or missing source, 2 usage.
EOF
}

fail() {
    printf 'install.sh: %s\n' "$*" >&2
    exit 2
}

dir=$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")" && pwd -P) || exit 1
bin_dir=${BIN_DIR:-$HOME/.local/bin}
fish_dir=${FISH_COMPLETION_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/fish/completions}

dry_run=0
remove=0
while (( $# )); do
    case $1 in
        -h|--help|help) usage; exit 0 ;;
        -n|--dry-run) dry_run=1 ;;
        --remove) remove=1 ;;
        *) fail "unknown argument: $1 (use --help)" ;;
    esac
    shift
done

links=(
    "$dir/atlanta|$bin_dir/atlanta"
    "$dir/completions/atlanta.fish|$fish_dir/atlanta.fish"
)

resolved() { readlink -f -- "$1" 2>/dev/null || :; }

status=0
for pair in "${links[@]}"; do
    src=${pair%%|*}
    dst=${pair#*|}

    [[ -e $src ]] || {
        printf 'install.sh: missing source: %s\n' "$src" >&2
        status=1
        continue
    }

    if (( remove )); then
        if [[ -L $dst && $(resolved "$dst") == "$(resolved "$src")" ]]; then
            if (( dry_run )); then
                printf 'would remove %s\n' "$dst"
            else
                rm -f -- "$dst" && printf 'removed %s\n' "$dst"
            fi
        else
            printf 'skip %s (absent, or not a link to %s)\n' "$dst" "$src"
        fi
        continue
    fi

    if [[ -L $dst && $(resolved "$dst") == "$(resolved "$src")" ]]; then
        printf 'ok    %s\n' "$dst"
        continue
    fi

    if [[ -e $dst || -L $dst ]]; then
        printf 'install.sh: %s exists and is not a link to %s\n' "$dst" "$src" >&2
        status=1
        continue
    fi

    if (( dry_run )); then
        printf 'would link %s -> %s\n' "$dst" "$src"
        continue
    fi

    mkdir -p -- "$(dirname -- "$dst")" || { status=1; continue; }
    ln -s -- "$src" "$dst" && printf 'link  %s -> %s\n' "$dst" "$src"
done

exit "$status"
