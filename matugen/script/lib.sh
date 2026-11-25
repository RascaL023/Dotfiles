#!/usr/bin/env bash

have() { command -v "$1" >/dev/null 2>&1; }

# Nix wraps binaries (`.kitty-wrapped`), so comm and argv0 rarely match the name
# a user types; strip both shapes before comparing.
clean_name() {
    local name=${1##*/}
    name=${name#.}
    printf '%s' "${name%-wrapped}"
}

# running <name> — true when a live process starts with <name> in comm or argv0.
running() {
    local want=$1 pid comm argv0
    while read -r pid; do
        [[ $pid == "$$" ]] && continue
        comm=$(clean_name "$(cat "/proc/$pid/comm" 2>/dev/null)")
        argv0=$(clean_name "$(tr '\0' '\n' < "/proc/$pid/cmdline" 2>/dev/null | head -n1)")
        [[ $comm == "$want"* || $argv0 == "$want"* ]] && return 0
    done < <(pgrep -f -- "$want" 2>/dev/null)
    return 1
}

ok() { printf '[ok]   %s\n' "$*"; }
skip() { printf '[skip] %s\n' "$*"; }
note() { printf '[note] %s\n' "$*"; }
fail() { printf '[FAIL] %s\n' "$*" >&2; }

# stage <dir> — empty staging directory inside the store, so a failed render
# never touches the live folder.
stage() {
    rm -rf -- "$1"
    mkdir -p -- "$1"
}

# validate_stage <dir> — print the staged file count. Fails when nothing was
# rendered, or a file is empty or still holds a template placeholder.
validate_stage() {
    local dir=$1 file bad=0
    local -a files
    mapfile -t files < <(find "$dir" -type f | sort)
    if (( ! ${#files[@]} )); then
        fail "tidak ada berkas yang dirender"
        return 1
    fi
    for file in "${files[@]}"; do
        if [[ ! -s $file ]]; then
            fail "berkas kosong: ${file#"$dir"/}"
            bad=1
        elif grep -qE '\{\{|\}\}|<\*|\*>' "$file"; then
            fail "placeholder tersisa di ${file#"$dir"/}"
            bad=1
        fi
    done
    (( bad == 0 )) || return 1
    printf '%s' "${#files[@]}"
}

# activate <staged-dir> <target-dir> <current-link> — swap the target directory
# and point `current` at it.
activate() {
    local staged=$1 target=$2 link=$3
    rm -rf -- "$target"
    mv -- "$staged" "$target" || return 1
    mkdir -p -- "${link%/*}"
    ln -sfn -- "$target" "$link"
}
