# Background processes atlanta owns. Identity comes from a PID file plus
# /proc, never from pgrep or pkill.

atlanta_runtime=${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}

track_pidfile() {
    printf '%s/atlanta-%s-%s.pid\n' "$atlanta_runtime" "$1" "$UID"
}

tracked_pid() {
    local name=$1 program=$2 file pid entry
    local -a args=()

    file=$(track_pidfile "$name")
    [[ -r $file ]] || return 1
    IFS= read -r pid < "$file" || return 1
    [[ $pid =~ ^[0-9]+$ && $pid -gt 1 ]] || return 1
    [[ -O /proc/$pid ]] || return 1
    mapfile -d '' -t args 2>/dev/null < "/proc/$pid/cmdline" || return 1

    for entry in "${args[@]}"; do
        [[ ${entry##*/} == "$program" ]] || continue
        printf '%s\n' "$pid"
        return 0
    done
    return 1
}

start_tracked() {
    local name=$1 program=$2 pid
    shift 2
    pid=$(tracked_pid "$name" "${program##*/}") && return 0
    nohup "$program" "$@" </dev/null >/dev/null 2>&1 &
    printf '%s\n' "$!" > "$(track_pidfile "$name")"
}

stop_tracked() {
    local name=$1 program=$2 pid index
    pid=$(tracked_pid "$name" "$program") || return 0
    kill -TERM -- "$pid" 2>/dev/null || :
    for (( index=0; index<50; index++ )); do
        kill -0 -- "$pid" 2>/dev/null || break
        sleep 0.02
    done
    rm -f -- "$(track_pidfile "$name")"
}
