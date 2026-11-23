#!/usr/bin/env bash
# Reporting only: neither mode starts, stops, or writes anything.
set -u

dir=$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P) || exit 1
# shellcheck source=../lib/session.sh
source "$dir/lib/session.sh"
# shellcheck source=../lib/provider.sh
source "$dir/lib/provider.sh"
# shellcheck source=../lib/state.sh
source "$dir/lib/state.sh"
# shellcheck source=../lib/proc.sh
source "$dir/lib/proc.sh"

mode=${1:-status}
if (( $# > 0 )); then
    shift
fi

check=0
for argument in "$@"; do
    case $argument in
        --check) check=1 ;;
        *) printf 'atlanta: unknown option: %s\n' "$argument" >&2; exit 2 ;;
    esac
done

missing=0

row() {
    printf '%-14s %-12s %s\n' "$1" "$2" "$3"
}

row_ready() {
    local path
    if path=$(provider_resolve "$2"); then
        row "$1" "$2" "${3:-ready}"
    else
        row "$1" "$2" missing
        missing=1
    fi
}

row_tracked() {
    local pid
    if pid=$(tracked_pid "$1" "$2"); then
        row "$1" "$2" "running $pid"
    else
        row "$1" "$2" stopped
    fi
}

status_notifications() {
    local ctl count dnd
    if ! ctl=$(provider_resolve swaync-client); then
        row notifications swaync-client missing
        missing=1
        return
    fi
    count=$(timeout 1 "$ctl" -c 2>/dev/null) || count=''
    if [[ $count =~ ^[0-9]+$ ]]; then
        dnd=$(timeout 1 "$ctl" -D 2>/dev/null) || dnd=unknown
        case $dnd in
            true) dnd=on ;;
            false) dnd=off ;;
            *) dnd=unknown ;;
        esac
        row notifications swaync "running dnd=$dnd count=$count"
    else
        row notifications swaync "ready (daemon not confirmed)"
    fi
}

status_session() {
    local name
    if ! provider_resolve wlogout >/dev/null; then
        row session wlogout missing
        missing=1
    elif tracked_pid wlogout wlogout >/dev/null; then
        row session wlogout open
    else
        row session wlogout idle
    fi
    case $(session_name) in
        hyprland|niri)
            if ! provider_resolve hyprlock >/dev/null; then
                row session hyprlock missing
                missing=1
            fi
            ;;
    esac
    for name in loginctl systemctl; do
        if ! provider_resolve "$name" >/dev/null; then
            row session "$name" missing
            missing=1
        fi
    done
}

status_bar() {
    local ctl state provider
    provider=$(bar_provider)
    case $provider in
        waybar)
            if ! ctl=$(provider_resolve waybar-ctl); then
                row bar waybar missing
                missing=1
                return
            fi
            state=$(timeout 2 "$ctl" status 2>/dev/null) || :
            case $state in
                running*) row bar waybar "$state" ;;
                *) row bar waybar stopped ;;
            esac
            ;;
        eww)
            if ! ctl=$(provider_resolve eww-ctl); then
                row bar eww missing
                missing=1
                return
            fi
            state=$(timeout 2 "$ctl" bar island status 2>/dev/null) || :
            case $state in
                *islands*) row bar eww "running $state" ;;
                *) row bar eww stopped ;;
            esac
            ;;
    esac
}

status_panel() {
    local ctl out line key value daemon='' windows=''
    if ! ctl=$(provider_resolve eww-ctl); then
        row bar.panel eww-ctl missing
        missing=1
        return
    fi
    # eww-ctl status exits 0 even when the daemon is down, so read its output.
    out=$(timeout 2 "$ctl" status 2>/dev/null) || :
    while IFS= read -r line; do
        read -r key value <<< "$line"
        case $key in
            daemon) daemon=$value ;;
            windows) windows=$value ;;
        esac
    done <<< "$out"
    if [[ -z $daemon ]]; then
        row bar.panel eww 'ready (daemon not confirmed)'
    elif [[ $daemon == stopped ]]; then
        row bar.panel eww stopped
    else
        row bar.panel eww "$daemon windows=${windows:-none}"
    fi
}

status_wallpaper() {
    local count index path
    if ! provider_resolve awww >/dev/null; then
        row wallpaper awww missing
        missing=1
        return
    fi
    count=$(wallpaper_images | wc -l)
    if (( count == 0 )); then
        row wallpaper awww "no images in $wallpaper_dir"
        return
    fi
    index=$(wallpaper_index)
    path=$(wallpaper_at "$index") || path=unknown
    row wallpaper awww "$(( index % count ))/$count ${path##*/}"
}

status_feedback() {
    if provider_resolve wpctl >/dev/null; then
        row osd wpctl ready
        row volume wpctl ready
        row mic wpctl ready
    else
        row osd wpctl missing
        row volume wpctl missing
        row mic wpctl missing
        missing=1
    fi
    if provider_resolve brightnessctl >/dev/null; then
        row brightness brightnessctl ready
    else
        row brightness brightnessctl missing
        missing=1
    fi
    if ! provider_resolve notify-send >/dev/null; then
        row feedback notify-send "optional (OSD disabled)"
    fi
}

bar_state_warning() {
    local value=''
    [[ -r $bar_state ]] && IFS= read -r value < "$bar_state"
    [[ -z $value ]] && return 0
    bar_provider_valid "$value" && return 0
    printf "atlanta: unknown bar provider '%s'; using waybar\n" "$value" >&2
}

status() {
    bar_state_warning
    row_ready launcher rofi-ctl
    status_bar
    status_panel
    status_notifications
    row_ready screenshot grim
    row_ready screenshot slurp
    status_session
    case $(session_name) in
        hyprland|niri)
            row_tracked idle swayidle
            row_tracked nightlight wlsunset
            ;;
        *)
            row idle swayidle unsupported
            row nightlight wlsunset unsupported
            ;;
    esac
    status_wallpaper
    status_feedback
    row theme matugen deferred
    (( check && missing )) && exit 1
    exit 0
}

doctor() {
    local capability provider path name selected marker
    selected=$(bar_provider)
    bar_state_warning
    for name in waybar-ctl eww-ctl; do
        provider=${name%-ctl}
        if path=$(provider_resolve "$name"); then :; else path=MISSING; fi
        marker=''
        [[ $provider == "$selected" ]] && marker=' selected'
        printf '%-14s %-15s %s%s\n' bar "$name" "$path" "$marker"
    done
    while read -r capability provider; do
        if path=$(provider_resolve "$provider"); then
            printf '%-14s %-15s %s\n' "$capability" "$provider" "$path"
        else
            printf '%-14s %-15s %s\n' "$capability" "$provider" MISSING
        fi
    done <<'EOF'
launcher rofi-ctl
bar.panel eww-ctl
notifications swaync-client
screenshot grim
screenshot slurp
wallpaper awww
wallpaper depth-ctl
osd wpctl
osd brightnessctl
osd notify-send
volume wpctl
mic wpctl
brightness brightnessctl
session wlogout
session loginctl
session systemctl
session hyprlock
idle swayidle
nightlight wlsunset
EOF
    printf '%-14s %-15s %s\n' session "$(session_name)" current
}

case $mode in
    status) status ;;
    doctor) doctor ;;
    *) printf 'atlanta: unknown report mode: %s\n' "$mode" >&2; exit 2 ;;
esac
