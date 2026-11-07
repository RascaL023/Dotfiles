# Waybar

`waybar-ctl` adalah pintu masuk untuk menjalankan, menghentikan, dan memuat ulang
bar. Pemanggil tidak perlu tahu config mana yang dipakai sesi aktif.

## Kenapa config dipisah

`modules-left` berbeda per sesi. `hyprland/workspaces` dan `niri/workspaces`
tidak boleh berada di daftar yang sama: modul workspace milik compositor yang
tidak berjalan membuat Waybar segfault. Karena itu `config.hyprland.jsonc` dan
`config.niri.jsonc` meng-`include` `config.jsonc` lalu menimpa `modules-left`
(`include` mengganti array, bukan menyambung). `waybar` telanjang tidak tahu
sesi mana yang aktif, jadi jangan dipanggil langsung.

## Pemanggilan

```bash
~/.config/waybar/waybar-ctl start
~/.config/waybar/waybar-ctl toggle
~/.config/waybar/waybar-ctl reload
~/.config/waybar/waybar-ctl status
```

| Perintah | Hasil |
|---|---|
| `start` | Jalankan bar untuk sesi ini; sudah jalan berarti tidak melakukan apa pun |
| `stop` | Hentikan bar; sudah mati berarti tidak melakukan apa pun |
| `toggle` | `start` bila mati, `stop` bila hidup |
| `restart` | `stop` lalu `start` |
| `reload` | Kirim SIGUSR2, aksi reload bawaan Waybar |
| `status` | `running <pid> <session>` (exit `0`) atau `not running` (exit `1`) |
| `config` | Cetak path config untuk sesi ini |
| `run` | Jalankan Waybar di foreground, mis. `run -- -l debug` |

Argumen tambahan diteruskan ke Waybar, jadi `start -- -l debug` sah. Nama perintah
yang tidak dikenal, sesi yang tidak dikenal, dan config yang hilang ditolak
dengan exit `2`; Waybar yang tidak ada di `PATH` menghasilkan `127`.

## Pemilihan sesi

Urutannya `--session hyprland|niri`, lalu `NIRI_SOCKET`, lalu
`HYPRLAND_INSTANCE_SIGNATURE`. Tanpa salah satunya, skrip berhenti dengan exit
`2` alih-alih menebak: menjalankan `niri/workspaces` di luar niri adalah kondisi
segfault yang justru ingin dihindari.

## Proses

PID ditulis ke `$XDG_RUNTIME_DIR/dotfile-waybar-$UID.pid` (fallback `$TMPDIR`,
lalu `/tmp`). Sebelum mengirim sinyal, skrip memeriksa bahwa proses masih milik
pengguna dan command line-nya menyebut `-c` dengan config yang sama. PID yang
sudah dipakai ulang atau milik proses lain tidak pernah dibunuh, dan `status`
melaporkannya sebagai `not running`.

Style tidak perlu sinyal tersendiri: `reload_style_on_change` aktif di
`config.jsonc`, jadi Waybar memuat ulang CSS yang di-`@import` saat berubah.

## Struktur

```text
waybar/
├── waybar-ctl                  # start/stop/toggle/reload, pemilihan sesi, PID
├── launch.sh -> waybar-ctl     # symlink kompatibilitas
├── config.jsonc                # modul dan tampilan bersama
├── config.hyprland.jsonc       # modules-left untuk Hyprland
├── config.niri.jsonc           # modules-left untuk niri
├── style.css                   # membaca palet Matugen
├── source.css                  # daftar @define-color
└── tests/test_waybar_ctl.py    # kontrak argumen, sesi, PID, dan sinyal
```

`launch.sh` adalah symlink relatif ke `waybar-ctl`, dipakai pemanggil lama.
Setelah semuanya memakai `waybar-ctl`, symlink itu bisa dihapus.

## Pemeriksaan

```bash
bash -n ~/.config/waybar/waybar-ctl
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s ~/.config/waybar/tests -v
```

Tes memakai Waybar tiruan; tidak menyalakan bar sungguhan.
