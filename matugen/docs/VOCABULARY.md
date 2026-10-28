# Kosakata Warna Matugen (contoh keluaran)

> Indeks: [`README.md`](README.md) · dokumen ini melengkapi
> [`CHEATSHEETS.md`](CHEATSHEETS.md) (yang menjelaskan *perannya* untuk UI),
> sedangkan halaman ini menunjukkan *daftar mentah* nama-nama warna.
>
> **Hanya berlaku untuk alur wallpaper (Material You).** Alur palet tetap
> (`templates/kanagawa-dragon-lotus/`) tidak memakai nama-nama ini — lihat
> [`../templates/kanagawa-dragon-lotus/blueprint/README.md`](../templates/kanagawa-dragon-lotus/blueprint/README.md).

## Dari mana tabel ini

```bash
matugen color hex "#957FB8" --show-colors
```

Baris `source_color` di bawah menunjukkan sumber warnanya (`#957FB8`, ungu
Kanagawa). **Semua nilai di tabel bergantung pada warna sumber itu** — ganti
sumbernya, semua angka berubah. Jadi tabel ini bukan konstanta repo, hanya
contoh untuk melihat *bentuk* kosakatanya.

Tabel di bawah dirender ulang dengan **matugen 4.2.0** (`--show-colors`),
jadi angkanya cocok dengan mesin ini — bukan salinan versi lama.

Kolom `LIGHT` dan `DARK` = dua keluaran dalam satu perintah; template memilih
salah satunya lewat `{{ colors.<role>.light.hex }}` / `.<role>.dark.hex` (atau
`default` untuk mode aktif — lihat `CHEATSHEETS.md` §2).

## Yang perlu diperhatikan saat membaca

- **Nama MD3** (`primary`, `on_primary`, `surface_container_high`, …) adalah
  kosakata resmi yang dipakai `{{ colors.<role>.<scheme>.<format> }}`.
- **Nama `base00`–`base0f`** bukan MD3: itu keluaran backend base16, urutannya
  sama dengan indeks ANSI bila dipakai untuk terminal.
- **`source_color`** = warna asal, bukan role; muncul di kolom light dan dark
  karena memang sama.

---

```text
│            NAME            │  LIGHT  │  │   DARK  │  │
│ primary                    │ #69548D │  │ #D5BBFC │  │
│ on_primary                 │ #FFFFFF │  │ #3A255B │  │
│ primary_container          │ #ECDCFF │  │ #513C73 │  │
│ on_primary_container       │ #240E45 │  │ #ECDCFF │  │
│ inverse_primary            │ #D5BBFC │  │ #69548D │  │
│ primary_fixed              │ #ECDCFF │  │ #ECDCFF │  │
│ primary_fixed_dim          │ #D5BBFC │  │ #D5BBFC │  │
│ on_primary_fixed           │ #240E45 │  │ #240E45 │  │
│ on_primary_fixed_variant   │ #513C73 │  │ #513C73 │  │
│ secondary                  │ #645B70 │  │ #CEC2DB │  │
│ on_secondary               │ #FFFFFF │  │ #352D40 │  │
│ secondary_container        │ #EADEF7 │  │ #4B4357 │  │
│ on_secondary_container     │ #1F182A │  │ #EADEF7 │  │
│ secondary_fixed            │ #EADEF7 │  │ #EADEF7 │  │
│ secondary_fixed_dim        │ #CEC2DB │  │ #CEC2DB │  │
│ on_secondary_fixed         │ #1F182A │  │ #1F182A │  │
│ on_secondary_fixed_variant │ #4B4357 │  │ #4B4357 │  │
│ tertiary                   │ #7F525C │  │ #F1B7C3 │  │
│ on_tertiary                │ #FFFFFF │  │ #4B252F │  │
│ tertiary_container         │ #FFD9E0 │  │ #643B45 │  │
│ on_tertiary_container      │ #32101A │  │ #FFD9E0 │  │
│ tertiary_fixed             │ #FFD9E0 │  │ #FFD9E0 │  │
│ tertiary_fixed_dim         │ #F1B7C3 │  │ #F1B7C3 │  │
│ on_tertiary_fixed          │ #32101A │  │ #32101A │  │
│ on_tertiary_fixed_variant  │ #643B45 │  │ #643B45 │  │
│ error                      │ #BA1A1A │  │ #FFB4AB │  │
│ on_error                   │ #FFFFFF │  │ #690005 │  │
│ error_container            │ #FFDAD6 │  │ #93000A │  │
│ on_error_container         │ #410002 │  │ #FFDAD6 │  │
│ surface_dim                │ #DED8E0 │  │ #151218 │  │
│ surface                    │ #FEF7FF │  │ #151218 │  │
│ surface_tint               │ #69548D │  │ #D5BBFC │  │
│ surface_bright             │ #FEF7FF │  │ #3B383E │  │
│ surface_container_lowest   │ #FFFFFF │  │ #0F0D12 │  │
│ surface_container_low      │ #F8F1F9 │  │ #1D1A20 │  │
│ surface_container          │ #F3ECF4 │  │ #211E24 │  │
│ surface_container_high     │ #EDE6EE │  │ #2C292F │  │
│ surface_container_highest  │ #E7E0E8 │  │ #37333A │  │
│ on_surface                 │ #1D1A20 │  │ #E7E0E8 │  │
│ on_surface_variant         │ #49454E │  │ #CBC4CF │  │
│ outline                    │ #7B757F │  │ #958E99 │  │
│ outline_variant            │ #CBC4CF │  │ #49454E │  │
│ inverse_surface            │ #322F35 │  │ #E7E0E8 │  │
│ inverse_on_surface         │ #F6EEF7 │  │ #322F35 │  │
│ surface_variant            │ #E8E0EB │  │ #49454E │  │
│ background                 │ #FEF7FF │  │ #151218 │  │
│ on_background              │ #1D1A20 │  │ #E7E0E8 │  │
│ shadow                     │ #000000 │  │ #000000 │  │
│ scrim                      │ #000000 │  │ #000000 │  │
│ source_color               │ #957FB8 │  │ #957FB8 │  │
│ base00                     │ #E9E7EB │  │ #1E1925 │  │
│ base01                     │ #CCCACF │  │ #3B3642 │  │
│ base02                     │ #AFACB3 │  │ #58545E │  │
│ base03                     │ #928F96 │  │ #75717A │  │
│ base04                     │ #75717A │  │ #928F96 │  │
│ base05                     │ #58545E │  │ #AFACB3 │  │
│ base06                     │ #3B3642 │  │ #CCCACF │  │
│ base07                     │ #1E1925 │  │ #E9E7EB │  │
│ base08                     │ #FF7893 │  │ #FF7893 │  │
│ base09                     │ #E08AA7 │  │ #E08AA7 │  │
│ base0a                     │ #B297DE │  │ #B297DE │  │
│ base0b                     │ #D29A00 │  │ #D29A00 │  │
│ base0c                     │ #E28A9F │  │ #E28A9F │  │
│ base0d                     │ #B98EFF │  │ #B98EFF │  │
│ base0e                     │ #FF779D │  │ #FF779D │  │
│ base0f                     │ #767278 │  │ #767278 │  │
```

## Cara memakainya di template

```toml
# alur wallpaper
background = "{{ colors.surface.default.hex }}"
fg         = "{{ colors.on_surface.default.hex }}"
accent     = "{{ colors.primary.default.hex }}"
```

Untuk melihat daftar nama pada mesin ini (tanpa menghafal tabel di atas):

```bash
matugen color hex "#957FB8" --show-colors   # tabel seperti di atas
matugen color hex "#957FB8" -j hex          # dump JSON: untuk menemukan key
```

Pemetaan *role → pekerjaan UI* (mana yang untuk latar, teks, border, dsb.) ada
di [`CHEATSHEETS.md`](CHEATSHEETS.md).
