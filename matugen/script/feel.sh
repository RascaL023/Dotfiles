#!/usr/bin/env bash
# Render satu profil rasa (feel) untuk WM yang sedang aktif.
#
#   matugen/script/feel.sh default                 # deteksi WM sendiri
#   matugen/script/feel.sh default --wm hypr       # paksa Hyprland (uji/cron)
#   matugen/script/feel.sh default --dry-run       # cetak rencana, tanpa tulis
#
# Satu profil adalah direktori berisi file per pemilik rasa:
#
#   profiles/<profil>/apps.json   # font/terminal/rofi — dipakai WM apa pun
#   profiles/<profil>/hypr.json   # knob Hyprland (shape, surface, material, motion)
#   profiles/<profil>/niri.json   # knob niri (placeholder; belum ada template)
#
# Yang dirender hanya bagian milik WM aktif: sesi Hyprland tidak pernah
# merender niri.json, dan sebaliknya. Bagian apps selalu ikut karena dibaca
# kitty/foot/alacritty/rofi/waybar/swaync di WM mana pun.
#
# Kenapa skrip dan bukan sekadar perintah matugen: symlink harus dibalik
# setelah render sukses, supaya tidak ada jendela waktu di mana konsumen
# membaca folder setengah jadi. Render selalu ke folder sementara
# (~/.myenv/theme/feel/generated/.<profil>.tmp), divalidasi, baru dipindah ke
# ~/.myenv/theme/feel/generated/<profil> dan `current` diarahkan ke sana.
# Render yang gagal tidak menyentuh profil yang sedang aktif.
set -euo pipefail

REPO="${HOME}/.dotfile"
STORE="${FEEL_ROOT:-${HOME}/.myenv/theme/feel}"
PROFILES="${REPO}/matugen/core/feel/profiles"
CONFIGS="${REPO}/matugen/core/feel"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")" && pwd -P)

# shellcheck source=wm.sh
source "${SCRIPT_DIR}/wm.sh"

profile=""
wm="auto"
dry_run=0
do_reload=1

usage() {
    cat <<'EOF'
usage: feel.sh <profil> [options]

  --wm auto|hypr|niri   WM yang dirender (default: auto, dideteksi dari sesi)
  -n, --dry-run         cetak perintah matugen, tidak menulis/mere-reload
  --no-reload           render + aktifkan, tapi jangan reload konsumen
  -h, --help            teks ini

Render per bagian: apps.json selalu, hypr.json hanya di sesi Hyprland,
niri.json hanya bila template niri sudah ada (belum).
EOF
}

while (( $# )); do
    case $1 in
        --wm)
            (( $# >= 2 )) || { echo "[ERR] --wm butuh auto|hypr|niri" >&2; exit 2; }
            wm=$2
            shift 2
            ;;
        --wm=*) wm=${1#*=}; shift ;;
        -n|--dry-run) dry_run=1; shift ;;
        --no-reload) do_reload=0; shift ;;
        -h|--help) usage; exit 0 ;;
        -*) echo "[ERR] opsi tidak dikenal: $1" >&2; usage >&2; exit 2 ;;
        *)
            if [[ -n $profile ]]; then
                echo "[ERR] argumen berlebih: $1" >&2
                exit 2
            fi
            profile=$1
            shift
            ;;
    esac
done

if [[ -z $profile ]]; then
    usage >&2
    exit 2
fi

if [[ $wm == auto ]]; then
    wm=$(wm_detect)
fi

case $wm in
    hypr|niri|unknown) ;;
    *) echo "[ERR] wm tidak dikenal: $wm (auto|hypr|niri)" >&2; exit 2 ;;
esac

dir="${PROFILES}/${profile}"
if [[ ! -d $dir ]]; then
    echo "[ERR] profil tidak ada: ${dir}" >&2
    echo "profil tersedia:" >&2
    for candidate in "${PROFILES}"/*/; do
        [[ -d $candidate ]] || continue
        echo "  $(basename "$candidate")" >&2
    done
    exit 1
fi

if ! command -v matugen >/dev/null 2>&1; then
    echo "[ERR] matugen tidak ada di PATH" >&2
    exit 1
fi

# Bagian yang dirender = pemilik rasa untuk WM ini. apps selalu ikut.
parts=(apps)
if [[ $wm == hypr ]]; then
    parts+=(hypr)
elif [[ $wm == niri && -f ${CONFIGS}/config.niri.toml ]]; then
    parts+=(niri)
fi

out="${STORE}/generated/${profile}"
tmp="${STORE}/generated/.${profile}.tmp"

echo "[feel] profil=${profile} wm=${wm} bagian=${parts[*]}"
if [[ $wm == niri ]]; then
    echo "[note] template niri belum ada; hanya apps.json yang dirender"
elif [[ $wm == unknown ]]; then
    echo "[note] WM tidak dikenali; hanya apps.json yang dirender"
fi

render_part() {
    local part=$1
    local src="${dir}/${part}.json"
    local cfg="${CONFIGS}/config.${part}.toml"

    if [[ ! -f $src ]]; then
        echo "[ERR] bagian profil tidak ada: ${src}" >&2
        return 1
    fi
    if [[ ! -f $cfg ]]; then
        echo "[ERR] config render tidak ada: ${cfg}" >&2
        return 1
    fi
    if (( dry_run )); then
        printf '[dry]  matugen json %s -c %s -p %s\n' "$src" "$cfg" "$tmp"
        return 0
    fi
    if ! matugen json "$src" -c "$cfg" -p "$tmp"; then
        echo "[ERR] matugen gagal untuk ${part}.json; ${STORE}/current tidak diubah" >&2
        return 1
    fi
}

if (( dry_run )); then
    for part in "${parts[@]}"; do
        render_part "$part" || exit 1
    done
    exit 0
fi

rm -rf "$tmp"
mkdir -p "$tmp"

for part in "${parts[@]}"; do
    if ! render_part "$part"; then
        rm -rf "$tmp"
        exit 1
    fi
done

# Validasi sebelum dipakai: tidak boleh ada berkas kosong, placeholder sisa,
# atau render yang tidak menghasilkan apa-apa.
mapfile -t files < <(find "$tmp" -type f | sort)
if [[ ${#files[@]} -eq 0 ]]; then
    echo "[ERR] tidak ada berkas yang dirender; ${STORE}/current tidak diubah" >&2
    rm -rf "$tmp"
    exit 1
fi

bad=0
for f in "${files[@]}"; do
    if [[ ! -s $f ]]; then
        echo "[ERR] berkas kosong: ${f#"$tmp"/}" >&2
        bad=1
        continue
    fi
    if grep -qE '\{\{|\}\}|<\*|\*>' "$f"; then
        echo "[ERR] placeholder tersisa di ${f#"$tmp"/}" >&2
        bad=1
    fi
done

if command -v sassc >/dev/null 2>&1 && [[ -f ${tmp}/scss/_feel.scss ]]; then
    if ! sassc "${tmp}/scss/_feel.scss" /dev/null; then
        echo "[ERR] ${tmp}/scss/_feel.scss tidak bisa dikompilasi" >&2
        bad=1
    fi
fi

if [[ $bad -ne 0 ]]; then
    echo "[ERR] render ditolak; ${STORE}/current tidak diubah" >&2
    rm -rf "$tmp"
    exit 1
fi

# Folder profil diganti utuh dari hasil yang sudah lolos validasi.
rm -rf "$out"
mv "$tmp" "$out"
mkdir -p "$STORE"
ln -sfn "$out" "${STORE}/current"
echo "[ok]   ${#files[@]} berkas, current -> generated/${profile}"

if (( ! do_reload )); then
    echo "[skip] reload konsumen dimatikan (--no-reload)"
    exit 0
fi

# `pgrep -x` tidak cukup: binari dari Nix bisa ber-comm ".swaync-wrapped"
# sementara argv0-nya "swaync". Cek ketiganya sebelum menyimpulkan "tidak jalan".
running() {
    local name=$1
    pgrep -x "$name" >/dev/null 2>&1 && return 0
    pgrep -f "(^|/)$name( |\$)" >/dev/null 2>&1 && return 0
    pgrep -x ".$name-wrapped" >/dev/null 2>&1
}

# Konsumen generik (apps.json): hanya yang benar-benar hidup disentuh.
if running eww; then
    if eww reload >/dev/null 2>&1; then
        echo "[ok]   eww reload"
    else
        echo "[skip] eww reload gagal (daemon jalan?)"
    fi
else
    echo "[skip] eww tidak jalan"
fi

if running waybar; then
    pkill -SIGUSR2 waybar && echo "[ok]   waybar reload"
else
    echo "[skip] waybar tidak jalan"
fi

if running swaync; then
    swaync-client -rs >/dev/null 2>&1 && echo "[ok]   swaync reload"
else
    echo "[skip] swaync tidak jalan"
fi

# Konsumen WM: hanya saat bagian hypr ikut dirender, dan hanya di sesi Hyprland.
if [[ $wm == hypr ]]; then
    sig=${HYPRLAND_INSTANCE_SIGNATURE:-}
    runtime=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
    feel_lua="${out}/hypr/feel.lua"

    if [[ -z $sig || ! -d $runtime/hypr/$sig ]]; then
        echo "[skip] hypr: sesi ini bukan Hyprland (atau instance mati)"
    elif command -v luac >/dev/null 2>&1 && ! luac -p "$feel_lua" 2>/dev/null; then
        echo "[ERR] ${feel_lua} gagal luac -p; reload hypr dibatalkan" >&2
        exit 1
    elif timeout 5 hyprctl --instance "$sig" reload >/dev/null 2>&1; then
        echo "[ok]   hyprland reload"
    else
        echo "[skip] hypr: reload gagal"
    fi
fi

echo "[note] kitty/foot membaca font saat start; buka ulang terminalnya."
