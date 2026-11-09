#!/usr/bin/env bash
#
# dotfile synchronizer
# Manage app configs via symlinks into ~/.dotfile
#
set -uo pipefail

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
config="${XDG_CONFIG_HOME:-$HOME/.config}"
dotfile="$HOME/.dotfile"
tools_file="$dotfile/tools.list"
state_file="$dotfile/.synchronizer/state.tmp"

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
log()  { printf '[%s] %s\n' "$1" "$2"; }
info() { log "OK"   "$1"; }
skip() { log "SKIP" "$1"; }
link() { log "LINK" "$1"; }
err()  { log "ERR"  "$1" >&2; }

# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------
auth() {
  for i in {1..3}; do
    clear

    read -p "Password: " pass
    [[ $pass == "atmin123" ]] && return 0

  done
  return 1
}

# ---------------------------------------------------------------------------
# tools.list reader: "name" auto-locates under $config, "name:path" is an
# explicit source. Emits "name<TAB>path".
# ---------------------------------------------------------------------------
tools_reader() {
  local line name path
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line#"${line%%[![:space:]]*}"}"   # ltrim
    line="${line%"${line##*[![:space:]]}"}"   # rtrim
    [[ -z "$line" || "$line" == \#* ]] && continue

    if [[ "$line" == *:* ]]; then
      name="${line%%:*}"
      path="${line#*:}"
      path="${path/#\~/$HOME}"                 # expand leading ~
    else
      name="$line"
      path=""
    fi
    printf '%s\t%s\n' "$name" "$path"
  done < "$tools_file"
}

lookup_tool() {
  local want="$1" name path
  while IFS=$'\t' read -r name path; do
    [[ "$name" == "$want" ]] && { printf '%s\n' "$path"; return 0; }
  done < <(tools_reader)
  return 1
}

resolve_src() {
  local name="$1" path="$2"
  if [[ -n "$path" ]]; then
    printf '%s\n' "$path"
    return 0
  fi
  find "$config" \( -type d -o -type f -o -type l \) -name "$name" -print -quit 2>/dev/null
}

# ---------------------------------------------------------------------------
# State file helpers   (format: name<TAB>original_path)
# ---------------------------------------------------------------------------
state_get() {
  [[ -f "$state_file" ]] || return 1
  local name="$1" n p
  while IFS=$'\t' read -r n p; do
    [[ "$n" == "$name" ]] && { printf '%s\n' "$p"; return 0; }
  done < "$state_file"
  return 1
}

state_set() {
  local name="$1" path="$2"
  mkdir -p "$(dirname "$state_file")"
  touch "$state_file"
  state_del "$name"
  printf '%s\t%s\n' "$name" "$path" >> "$state_file"
}

state_del() {
  [[ -f "$state_file" ]] || return 0
  local name="$1" tmp
  tmp="$(mktemp)"
  grep -v -P "^${name}\t" "$state_file" > "$tmp" 2>/dev/null || true
  mv "$tmp" "$state_file"
}

# ---------------------------------------------------------------------------
# Per-tool actions
# ---------------------------------------------------------------------------

link_tool() {
  local name="$1" path="$2" src linkpath target bak
  src="$(resolve_src "$name" "$path")"

  if [[ -z "$src" ]]; then
    err "$name: source not found"
    return 1
  fi

  linkpath="$src"
  target="$dotfile/$name"

  if [[ -L "$linkpath" ]] &&
     [[ "$(readlink -f "$linkpath")" == "$(readlink -f "$target")" ]]; then
    skip "$name already linked"
    state_set "$name" "$linkpath"
    return 0
  fi

  if [[ ! -e "$linkpath" ]]; then
    err "$name: $linkpath does not exist"
    return 1
  fi

  if [[ -e "$target" ]]; then
    bak="$target.bak-$(date +%Y%m%d%H%M%S)"
    skip "$name: $target exists -> backup to $(basename "$bak")"
    if ! mv "$target" "$bak"; then
      err "$name: backup failed"
      return 1
    fi
  fi

  link "$name"
  if ! mv "$linkpath" "$target"; then
    err "$name: move failed"
    return 1
  fi
  if ! ln -sfn "$target" "$linkpath"; then
    err "$name: symlink failed, rolling back"
    mv "$target" "$linkpath"
    return 1
  fi
  state_set "$name" "$linkpath"
}

restore_tool() {
  local name="$1" path="$2" linkpath realpath
  linkpath="$(state_get "$name")" || linkpath=""
  [[ -z "$linkpath" ]] && linkpath="$(resolve_src "$name" "$path")"
  [[ -z "$linkpath" ]] && linkpath="$config/$name"

  realpath="$dotfile/$name"

  if [[ ! -L "$linkpath" ]]; then
    skip "$name: $linkpath is not a symlink"
    return 0
  fi

  if [[ ! -e "$realpath" ]]; then
    err "$name: $realpath missing"
    return 1
  fi

  info "restoring $name"
  if ! unlink "$linkpath"; then
    err "$name: unlink failed"
    return 1
  fi
  if ! mv "$realpath" "$linkpath"; then
    err "$name: move back failed, recreating symlink"
    ln -sfn "$realpath" "$linkpath"
    return 1
  fi
  state_del "$name"
}

status_tool() {
  local name="$1" path="$2" src target state
  src="$(resolve_src "$name" "$path")"
  target="$dotfile/$name"

  if [[ -n "$src" && -L "$src" ]] &&
     [[ "$(readlink -f "$src")" == "$(readlink -f "$target")" ]]; then
    state="LINKED"
  elif [[ -e "$target" ]]; then
    state="STAGED (not linked)"
  elif [[ -n "$src" ]]; then
    state="NOT LINKED"
  else
    state="MISSING"
  fi
  printf '%-16s %s\n' "$name" "$state"
}

# ---------------------------------------------------------------------------
# Driver: run an action over all tools, or only the requested ones
#   run_action <action_fn> [tool ...]
# ---------------------------------------------------------------------------
run_action() {
  local action="$1"; shift
  local name path t p

  if [[ $# -eq 0 ]]; then
    while IFS=$'\t' read -r name path; do
      "$action" "$name" "$path"
    done < <(tools_reader)
  else
    for t in "$@"; do
      if p="$(lookup_tool "$t")"; then
        "$action" "$t" "$p"
      else
        err "unknown tool: $t (not in tools.list)"
      fi
    done
  fi
}

# ---------------------------------------------------------------------------
# Public actions (all tools or specific ones)
# ---------------------------------------------------------------------------
staging() { run_action link_tool    "$@"; }
restore() { run_action restore_tool "$@"; }
status()  {
  printf '%-16s %s\n' "TOOL" "STATE"
  run_action status_tool "$@"
}

# ---------------------------------------------------------------------------
# Menu (interactive)
# ---------------------------------------------------------------------------
ask_target() {
  local t
  read -p "Target (kosong = semua): " t
  printf '%s' "$t"
}

menus() {
  local t
  while true; do
    echo "1. Start linkings"
    echo "2. Restore links"
    echo "3. Status"
    echo "4. Clear"
    echo "0. Exit"
    read -p "❯ " inp

    case $inp in
      0) echo "Bye.."; exit ;;
      1) t="$(ask_target)"; staging $t ;;
      2) t="$(ask_target)"; restore $t ;;
      3) t="$(ask_target)"; status  $t ;;
      4) clear ;;
      *) echo "Invalid" ;;
    esac
    echo "Done..."
  done
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
[[ -f "$tools_file" ]] || { err "tools.list not found: $tools_file"; exit 1; }

# Non-interactive: sync.sh <link|restore|status> [tool ...]
if [[ $# -gt 0 ]]; then
  cmd="$1"; shift
  case "$cmd" in
    link)    staging "$@" ;;
    restore) restore "$@" ;;
    status)  status  "$@" ;;
    *) err "Unknown command: $cmd (use: link|restore|status [tool ...])"; exit 1 ;;
  esac
  exit 0
fi

# Interactive mode
if auth; then
  echo "Welcome $(whoami)!"
else
  exit
fi

menus
