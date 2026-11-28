# Backend resolution and lifecycle helpers.
#
# Order (same as atlanta, so tests can replace everything):
#   1. $CONSTELLIA_BACKEND_DIR/<name>   fake or override
#   2. this checkout: ../<tool>/<name>
#   3. PATH
# `noctalia` has no checkout entry on purpose: it is the system binary.

# The entry point exports CONSTELLIA_DIR, so sourcing this costs no process.
constellia_dir=${CONSTELLIA_DIR:-$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P)}
constellia_repo=${constellia_dir%/*}

constellia_bus_ms=${CONSTELLIA_BUS_TIMEOUT_MS:-3000}
constellia_ready_ms=${CONSTELLIA_NOCTALIA_TIMEOUT_MS:-10000}
constellia_stop_ms=${CONSTELLIA_STOP_TIMEOUT_MS:-5000}

backend_repo_subdir() {
    case $1 in
        atlanta) printf 'atlanta\n' ;;
        rofi-ctl) printf 'rofi\n' ;;
        eww-ctl) printf 'eww\n' ;;
        matugen-ctl) printf 'matugen\n' ;;
        noctalia-ctl) printf 'noctalia\n' ;;
        *) return 1 ;;
    esac
}

backend_path() {
    local name=$1 subdir candidate
    if [[ -n ${CONSTELLIA_BACKEND_DIR:-} && -x $CONSTELLIA_BACKEND_DIR/$name ]]; then
        printf '%s\n' "$CONSTELLIA_BACKEND_DIR/$name"
        return 0
    fi
    if subdir=$(backend_repo_subdir "$name"); then
        candidate=$constellia_repo/$subdir/$name
        if [[ -x $candidate ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    fi
    command -v "$name" 2>/dev/null
}

require_backend() {
    local path
    path=$(backend_path "$1") || {
        printf 'constellia: %s is missing (run constellia doctor)\n' "$1" >&2
        exit 127
    }
    printf '%s\n' "$path"
}

dry_print() {
    local arg
    printf '[dry]'
    for arg in "$@"; do
        printf ' %s' "$arg"
    done
    printf '\n'
}

# Run without replacing this process (lifecycle steps need the return status).
invoke() {
    local name=$1 path
    shift
    if (( ${CONSTELLIA_DRY_RUN:-0} )); then
        dry_print "$name" "$@"
        return 0
    fi
    path=$(require_backend "$name") || exit $?
    "$path" "$@"
}

# The hot path: constellia is replaced by the backend, so one process remains.
run_backend() {
    local name=$1 path
    shift
    if (( ${CONSTELLIA_DRY_RUN:-0} )); then
        dry_print "$name" "$@"
        exit 0
    fi
    path=$(require_backend "$name") || exit $?
    exec "$path" "$@"
}

note() {
    printf '%s %s\n' "$1" "$2"
}

# --- Noctalia process (argv0-anchored; see DESIGN 17.1) ---------------------

# argv0 is either `noctalia` (started by the session) or an absolute path
# (started by `noctalia -d`), so anchor on both. `noctalia msg …` still
# cannot match because those cmdlines continue past the name.
noctalia_pattern='(^|/)noctalia$'

noctalia_pid() {
    local pgrep_path
    pgrep_path=$(backend_path pgrep) || return 1
    "$pgrep_path" -o -f "$noctalia_pattern" 2>/dev/null
}

noctalia_running() {
    [[ -n $(noctalia_pid) ]]
}

# atlanta's stack: the bar daemon (waybar or eww) or the wallpaper daemon.
# Nix wrappers rename the comm (.eww-wrapped), so match argv0 instead; the
# trailing separator keeps `eww-ctl` and friends out.
atlanta_running() {
    local pgrep_path name
    pgrep_path=$(backend_path pgrep) || return 1
    for name in waybar eww awww-daemon; do
        "$pgrep_path" -f '(^|/)'"$name"'( |$)' >/dev/null 2>&1 && return 0
    done
    return 1
}

# --- Notification bus -------------------------------------------------------

# 0 owned, 1 free, 2 the bus cannot be queried.
bus_has_owner() {
    local busctl out
    busctl=$(backend_path busctl) || return 2
    out=$("$busctl" --user call org.freedesktop.DBus /org/freedesktop/DBus \
        org.freedesktop.DBus NameHasOwner s org.freedesktop.Notifications 2>/dev/null) || return 2
    [[ $out == *true* ]]
}

bus_owner_pid() {
    local busctl key value
    busctl=$(backend_path busctl) || return 1
    while IFS='=' read -r key value; do
        [[ $key == PID ]] || continue
        printf '%s\n' "$value"
        return 0
    done < <("$busctl" --user status org.freedesktop.Notifications 2>/dev/null)
    return 1
}

# 100 ms poll. 0 free, 1 still owned.
wait_bus_free() {
    local attempt limit=$(( constellia_bus_ms / 100 ))
    (( limit > 0 )) || limit=1
    if (( ${CONSTELLIA_DRY_RUN:-0} )); then
        dry_print wait org.freedesktop.Notifications free "${constellia_bus_ms}ms"
        return 0
    fi
    for (( attempt=0; attempt<limit; attempt++ )); do
        bus_has_owner
        case $? in
            0) sleep 0.1 ;;
            # Free, or the bus cannot be queried: starting a daemon is safe.
            1|2) return 0 ;;
        esac
    done
    return 1
}

# --- Noctalia lifecycle -----------------------------------------------------

noctalia_status() {
    local noctalia_path
    noctalia_path=$(backend_path noctalia) || return 1
    "$noctalia_path" msg status >/dev/null 2>&1
}

# 200 ms poll, bounded by CONSTELLIA_NOCTALIA_TIMEOUT_MS.
wait_noctalia_ready() {
    local attempt limit=$(( constellia_ready_ms / 200 ))
    (( limit > 0 )) || limit=1
    if (( ${CONSTELLIA_DRY_RUN:-0} )); then
        dry_print wait noctalia ready "${constellia_ready_ms}ms"
        return 0
    fi
    for (( attempt=0; attempt<limit; attempt++ )); do
        noctalia_status && return 0
        sleep 0.2
    done
    return 1
}

start_noctalia() {
    local noctalia_path
    if (( ${CONSTELLIA_DRY_RUN:-0} )); then
        dry_print noctalia -d
        return 0
    fi
    if noctalia_running; then
        note 'already running' noctalia
        return 0
    fi
    noctalia_path=$(require_backend noctalia) || exit $?
    if ! "$noctalia_path" -d >/dev/null 2>&1; then
        note 'failed to start' noctalia
        return 1
    fi
    note started noctalia
}

# TERM, poll 5 s, KILL, poll 1 s. No PID file: `noctalia -d` daemonizes.
stop_noctalia() {
    local pkill_path attempt limit
    if (( ${CONSTELLIA_DRY_RUN:-0} )); then
        dry_print pkill -TERM -f "$noctalia_pattern"
        return 0
    fi
    if ! noctalia_running; then
        note 'not running' noctalia
        return 0
    fi
    pkill_path=$(require_backend pkill) || exit $?
    limit=$(( constellia_stop_ms / 100 ))
    (( limit > 0 )) || limit=1
    "$pkill_path" -TERM -f "$noctalia_pattern" 2>/dev/null || :
    for (( attempt=0; attempt<limit; attempt++ )); do
        noctalia_running || {
            note stopped noctalia
            return 0
        }
        sleep 0.1
    done
    note 'still alive after TERM, sending KILL to' noctalia
    "$pkill_path" -KILL -f "$noctalia_pattern" 2>/dev/null || :
    for (( attempt=0; attempt<10; attempt++ )); do
        noctalia_running || {
            note stopped noctalia
            return 0
        }
        sleep 0.1
    done
    printf 'constellia: noctalia is still running after KILL\n' >&2
    return 1
}
