#!/usr/bin/env bash

set -euo pipefail

repo=${HOME}/.dotfile
store=${FEEL_ROOT:-$HOME/.myenv/theme/feel}
profiles=$repo/matugen/core/feel/profiles
configs=$repo/matugen/core/feel
script_dir=$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")" && pwd -P)

# shellcheck source=lib.sh
source "$script_dir/lib.sh"
# shellcheck source=wm.sh
source "$script_dir/wm.sh"

profile=""
wm=auto
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
niri.json hanya di sesi niri.
EOF
}

while (( $# )); do
    case $1 in
        --wm)
            (( $# >= 2 )) || { fail "--wm butuh auto|hypr|niri"; exit 2; }
            wm=$2
            shift 2
            ;;
        --wm=*) wm=${1#*=}; shift ;;
        -n|--dry-run) dry_run=1; shift ;;
        --no-reload) do_reload=0; shift ;;
        -h|--help) usage; exit 0 ;;
        -*) fail "opsi tidak dikenal: $1"; usage >&2; exit 2 ;;
        *)
            [[ -z $profile ]] || { fail "argumen berlebih: $1"; exit 2; }
            profile=$1
            shift
            ;;
    esac
done

[[ -n $profile ]] || { usage >&2; exit 2; }

if [[ $wm == auto ]]; then
    wm=$(wm_detect)
fi

case $wm in
    hypr|niri|unknown) ;;
    *) fail "wm tidak dikenal: $wm (auto|hypr|niri)"; exit 2 ;;
esac

profile_dir=$profiles/$profile
if [[ ! -d $profile_dir ]]; then
    fail "profil tidak ada: $profile_dir"
    printf 'profil tersedia:\n' >&2
    for candidate in "$profiles"/*/; do
        [[ -d $candidate ]] || continue
        printf '  %s\n' "$(basename -- "$candidate")" >&2
    done
    exit 1
fi

have matugen || { fail "matugen tidak ada di PATH"; exit 1; }

parts=(apps)
if [[ $wm == hypr ]]; then
    parts+=(hypr)
elif [[ $wm == niri && -f $configs/config.niri.toml ]]; then
    parts+=(niri)
fi

out=$store/generated/$profile
tmp=$store/generated/.$profile.tmp

printf '[feel] profil=%s wm=%s bagian=%s\n' "$profile" "$wm" "${parts[*]}"
if [[ $wm == unknown ]]; then
    note "WM tidak dikenali; hanya apps.json yang dirender"
fi

render_part() {
    local part=$1
    local src=$profile_dir/$part.json
    local cfg=$configs/config.$part.toml

    [[ -f $src ]] || { fail "bagian profil tidak ada: $src"; return 1; }
    [[ -f $cfg ]] || { fail "config render tidak ada: $cfg"; return 1; }

    if (( dry_run )); then
        printf '[dry]  matugen json %s -c %s -p %s\n' "$src" "$cfg" "$tmp"
        return 0
    fi
    matugen json "$src" -c "$cfg" -p "$tmp" || {
        fail "matugen gagal untuk ${part}.json; ${store}/current tidak diubah"
        return 1
    }
}

if (( dry_run )); then
    for part in "${parts[@]}"; do
        render_part "$part"
    done
    exit 0
fi

stage "$tmp"
for part in "${parts[@]}"; do
    if ! render_part "$part"; then
        rm -rf -- "$tmp"
        exit 1
    fi
done

if ! count=$(validate_stage "$tmp"); then
    fail "render ditolak; ${store}/current tidak diubah"
    rm -rf -- "$tmp"
    exit 1
fi

bad=0
if have sassc && [[ -f $tmp/scss/_feel.scss ]]; then
    if ! sassc "$tmp/scss/_feel.scss" /dev/null; then
        fail "$tmp/scss/_feel.scss tidak bisa dikompilasi"
        bad=1
    fi
fi

if [[ $wm == niri ]] && have niri && [[ -f $tmp/niri/feel.kdl ]]; then
    if ! niri validate -c "$tmp/niri/feel.kdl" >/dev/null 2>&1; then
        fail "$tmp/niri/feel.kdl tidak lolos niri validate"
        bad=1
    fi
fi

if (( bad )); then
    fail "render ditolak; ${store}/current tidak diubah"
    rm -rf -- "$tmp"
    exit 1
fi

activate "$tmp" "$out" "$store/current" || {
    fail "gagal memindahkan render ke $out"
    exit 1
}
ok "$count berkas, current -> generated/$profile"

if (( ! do_reload )); then
    skip "reload konsumen dimatikan (--no-reload)"
    exit 0
fi

reload_apps() {
    if running eww; then
        if eww-ctl reload >/dev/null 2>&1; then
            ok "eww-ctl reload"
        else
            skip "eww-ctl reload gagal (daemon jalan?)"
        fi
    else
        skip "eww tidak jalan"
    fi

    if ! running waybar; then
        skip "waybar tidak jalan"
    elif pkill -SIGUSR2 waybar; then
        ok "waybar reload"
    else
        skip "waybar: reload gagal"
    fi

    if ! running swaync; then
        skip "swaync tidak jalan"
    elif swaync-client -rs >/dev/null 2>&1; then
        ok "swaync reload"
    else
        skip "swaync: reload gagal"
    fi
}

reload_niri() {
    if ! running niri; then
        skip "niri tidak jalan"
        return 0
    fi
    if touch "$repo/niri/config.kdl"; then
        ok "niri reload (config disentuh)"
    else
        skip "niri: gagal menyentuh config"
    fi
}

reload_hypr() {
    local sig=${HYPRLAND_INSTANCE_SIGNATURE:-}
    local runtime=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
    local feel_lua=$out/hypr/feel.lua

    if [[ -z $sig || ! -d $runtime/hypr/$sig ]]; then
        skip "hypr: sesi ini bukan Hyprland (atau instance mati)"
        return 0
    fi
    if have luac && ! luac -p "$feel_lua" 2>/dev/null; then
        fail "$feel_lua gagal luac -p; reload hypr dibatalkan"
        return 1
    fi
    if timeout 5 hyprctl --instance "$sig" reload >/dev/null 2>&1; then
        ok "hyprland reload"
    else
        skip "hypr: reload gagal"
    fi
}

reload_wm() {
    case $wm in
        niri) reload_niri ;;
        hypr) reload_hypr ;;
    esac
}

reload_apps
reload_wm || exit 1

note "kitty/foot membaca font saat start; buka ulang terminalnya."
