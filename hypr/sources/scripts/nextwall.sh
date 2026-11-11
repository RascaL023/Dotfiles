#!/usr/bin/env bash

# Folder wallpaper
DIR="$HOME/Pictures/Wallpaper"
WALLPAPER_ENGINE=awww
DEPTHCTL="$HOME/.dotfile/eww/scripts/depthctl"

# Depth clock: show the matching foreground, hide it when the new wallpaper has
# no mask. Never blocks the wallpaper transition and never fails the script.
depth_sync() {
    [[ -x $DEPTHCTL ]] || return 0
    "$DEPTHCTL" wallpaper "$1" >/dev/null 2>&1 || true
}

# Ambil semua file gambar (pakai array bash, lebih aman dari ls)
shopt -s nullglob  # Kalau gak ada file, array kosong (gak error)
FILES=("$DIR"/*.{jpg,jpeg,png,webp,gif})

# Cek apakah ada file
if [[ ${#FILES[@]} -eq 0 ]]; then
    notify-send "Error" "No wallpapers found in $DIR"
    exit 1
fi

# Mode "first" → set wallpaper pertama
if [[ $1 == "first" ]]; then
    $WALLPAPER_ENGINE img "${FILES[0]}" \
        --transition-type center \
        --transition-fps 60 \
        --transition-step 200
    depth_sync "${FILES[0]}"
    exit 0
fi

# rofi-ctl menyusun baris + ikon sendiri dan mencetak path absolut
SELECTED=$(rofi-ctl wallpaper -d "$DIR")

# Kalau gak ada yang dipilih, exit
[[ -z "$SELECTED" ]] && exit 0

# Set wallpaper
CHOSEN="$SELECTED"

# Init $WALLPAPER_ENGINE kalau belum jalan
$WALLPAPER_ENGINE query || $WALLPAPER_ENGINE init

# Set wallpaper dengan transisi
$WALLPAPER_ENGINE img "$CHOSEN" \
    --transition-type center \
    --transition-fps 60 \
    --transition-step 200

depth_sync "$CHOSEN"

# Optional: Simpan pilihan terakhir
# echo "$CHOSEN" > "$HOME/.cache/current_wallpaper"
