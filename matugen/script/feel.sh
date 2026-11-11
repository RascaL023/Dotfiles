#!/usr/bin/env bash
# Render satu profil rasa (feel) dan balik ~/.myenv/theme/feel/current ke hasilnya.
#
#   matugen/feel.sh default      # render profil default
#   matugen/feel.sh paper        # profil lain (matugen/core/feel/blueprint/paper.json)
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
CONFIG="${REPO}/matugen/core/feel/config.toml"
PROFILES="${REPO}/matugen/core/feel/blueprint"

profile="${1:-}"
if [[ -z $profile ]]; then
  echo "usage: feel.sh <profil>       # contoh: feel.sh default" >&2
  echo "profil tersedia:" >&2
  for f in "${PROFILES}"/*.json; do
    [[ -e $f ]] || continue
    echo "  $(basename "$f" .json)" >&2
  done
  exit 2
fi

src="${PROFILES}/${profile}.json"
if [[ ! -f $src ]]; then
  echo "[ERR] profil tidak ada: ${src}" >&2
  exit 1
fi

if ! command -v matugen >/dev/null 2>&1; then
  echo "[ERR] matugen tidak ada di PATH" >&2
  exit 1
fi

# `pgrep -x` tidak cukup: binari dari Nix bisa ber-comm ".swaync-wrapped"
# sementara argv0-nya "swaync". Cek ketiganya sebelum menyimpulkan "tidak jalan".
running() {
  local name=$1
  pgrep -x "$name" >/dev/null 2>&1 && return 0
  pgrep -f "(^|/)$name( |\$)" >/dev/null 2>&1 && return 0
  pgrep -x ".$name-wrapped" >/dev/null 2>&1
}

out="${STORE}/generated/${profile}"
tmp="${STORE}/generated/.${profile}.tmp"

echo "[feel] render ${profile} -> ${out}"
rm -rf "$tmp"
mkdir -p "$tmp"
if ! matugen json "$src" -c "$CONFIG" -p "$tmp"; then
  echo "[ERR] matugen gagal; ${STORE}/current tidak diubah" >&2
  rm -rf "$tmp"
  exit 1
fi

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

# Konsumen yang bisa memuat ulang CSS saat hidup. Yang tidak jalan dilewati,
# jadi skrip ini aman dipakai di sesi mana pun.
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

echo "[note] kitty/foot membaca font saat start; buka ulang terminalnya."
