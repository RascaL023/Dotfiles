#!/usr/bin/env bash
# Shared reporting for the OSD-driven capabilities: one swaync bubble per
# change, and the same formatting whether the caller reads or mutates a level.

notify_osd() {
    notify-send -h string:x-canonical-private-synchronous:atlanta-osd \
        -t 1500 -i "$2" "$1" "$3" 2>/dev/null || :
    printf '%s %s\n' "$1" "$3"
}

# A state change is a side effect, not output: no printf here, and the same
# capability always replaces its own bubble instead of stacking new ones.
notify_state() {
    notify-send -h "string:x-canonical-private-synchronous:atlanta-$1" \
        -t 2000 "$2" "$3" 2>/dev/null || :
}

wpctl_level() {
    "$1" get-volume "$2" |
        awk '{ printf "%d%%%s", $2 * 100, ($3 == "[MUTED]" ? " (muted)" : "") }'
}

brightness_level() {
    local current maximum
    current=$("$1" get) || return 1
    maximum=$("$1" max) || return 1
    (( maximum > 0 )) || return 1
    printf '%d%%' "$(( current * 100 / maximum ))"
}
