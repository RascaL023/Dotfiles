# The only state atlanta owns: the last wallpaper index and the selected bar
# provider. Everything else belongs to the provider that already stores it.

wallpaper_dir=${ATLANTA_WALLPAPER_DIR:-$HOME/Pictures/Wallpaper}
atlanta_state=${XDG_STATE_HOME:-$HOME/.local/state}/atlanta
wallpaper_state=$atlanta_state/wallpaper
bar_state=$atlanta_state/bar

wallpaper_images() {
    local path
    shopt -s nullglob
    for path in "$wallpaper_dir"/*.{jpg,jpeg,png,webp,gif}; do
        [[ -f $path ]] && printf '%s\n' "$path"
    done
}

wallpaper_index() {
    local value=''
    [[ -r $wallpaper_state ]] && IFS= read -r value < "$wallpaper_state"
    [[ $value =~ ^[0-9]+$ ]] || value=0
    printf '%s\n' "$value"
}

wallpaper_index_save() {
    mkdir -p -- "$atlanta_state" || return 1
    printf '%s\n' "$1" > "$wallpaper_state"
}

bar_provider_valid() {
    case $1 in
        waybar|eww) return 0 ;;
        *) return 1 ;;
    esac
}

bar_provider() {
    local value=''
    [[ -r $bar_state ]] && IFS= read -r value < "$bar_state"
    if bar_provider_valid "$value"; then
        printf '%s\n' "$value"
    else
        printf 'waybar\n'
    fi
}

bar_provider_save() {
    mkdir -p -- "$atlanta_state" || return 1
    printf '%s\n' "$1" > "$bar_state"
}

wallpaper_at() {
    local -a images=()
    mapfile -t images < <(wallpaper_images)
    (( ${#images[@]} )) || return 1
    printf '%s\n' "${images[$(( $1 % ${#images[@]} ))]}"
}
