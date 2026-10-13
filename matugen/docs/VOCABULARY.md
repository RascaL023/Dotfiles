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
╭────────────────────────────┬─────────┬──┬─────────┬──╮
│            NAME            │  LIGHT  │  │   DARK  │  │
╞════════════════════════════╪═════════╪══╪═════════╪══╡
│ primary                    │ #665288 │  │ #D4BCF9 │  │
│ on_primary                 │ #FFFFFF │  │ #392659 │  │
│ primary_container          │ #806BA2 │  │ #9D86C0 │  │
│ on_primary_container       │ #FFFFFF │  │ #000000 │  │
│ inverse_primary            │ #D4BCF9 │  │ #69548A │  │
│ primary_fixed              │ #ECDCFF │  │ #ECDCFF │  │
│ primary_fixed_dim          │ #D4BCF9 │  │ #D4BCF9 │  │
│ on_primary_fixed           │ #241042 │  │ #241042 │  │
│ on_primary_fixed_variant   │ #503D71 │  │ #503D71 │  │
│ secondary                  │ #645A71 │  │ #CEC1DC │  │
│ on_secondary               │ #FFFFFF │  │ #352D42 │  │
│ secondary_container        │ #EBDDF9 │  │ #4E455B │  │
│ on_secondary_container     │ #4D445A │  │ #ECDFFB │  │
│ secondary_fixed            │ #EBDDF9 │  │ #EBDDF9 │  │
│ secondary_fixed_dim        │ #CEC1DC │  │ #CEC1DC │  │
│ on_secondary_fixed         │ #1F182C │  │ #1F182C │  │
│ on_secondary_fixed_variant │ #4C4359 │  │ #4C4359 │  │
│ tertiary                   │ #854965 │  │ #FCB1D1 │  │
│ on_tertiary                │ #FFFFFF │  │ #511E39 │  │
│ tertiary_container         │ #A1617E │  │ #C07C9B │  │
│ on_tertiary_container      │ #FFFFFF │  │ #000000 │  │
│ tertiary_fixed             │ #FFD8E6 │  │ #FFD8E6 │  │
│ tertiary_fixed_dim         │ #FCB1D1 │  │ #FCB1D1 │  │
│ on_tertiary_fixed          │ #380823 │  │ #380823 │  │
│ on_tertiary_fixed_variant  │ #6C344F │  │ #6C344F │  │
│ error                      │ #BA1A1A │  │ #FFB4AB │  │
│ on_error                   │ #FFFFFF │  │ #690005 │  │
│ error_container            │ #FFDAD6 │  │ #93000A │  │
│ on_error_container         │ #410002 │  │ #FFDAD6 │  │
│ surface_dim                │ #DED8DD │  │ #141316 │  │
│ surface                    │ #FEF7FD │  │ #141316 │  │
│ surface_tint               │ #69548A │  │ #D4BCF9 │  │
│ surface_bright             │ #FEF7FD │  │ #3B383C │  │
│ surface_container_lowest   │ #FFFFFF │  │ #0F0D11 │  │
│ surface_container_low      │ #F8F2F7 │  │ #1D1B1F │  │
│ surface_container          │ #F2ECF1 │  │ #211F23 │  │
│ surface_container_high     │ #ECE6EC │  │ #2B292D │  │
│ surface_container_highest  │ #E7E1E6 │  │ #363438 │  │
│ on_surface                 │ #1D1B1F │  │ #E7E1E6 │  │
│ on_surface_variant         │ #49454E │  │ #CBC4CF │  │
│ outline                    │ #7B757F │  │ #958E99 │  │
│ outline_variant            │ #CBC4CF │  │ #49454E │  │
│ inverse_surface            │ #322F34 │  │ #E7E1E6 │  │
│ inverse_on_surface         │ #F5EFF4 │  │ #322F34 │  │
│ surface_variant            │ #E8E0EC │  │ #49454E │  │
│ background                 │ #FEF7FD │  │ #141316 │  │
│ on_background              │ #1D1B1F │  │ #E7E1E6 │  │
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
╰────────────────────────────┴─────────┴──┴─────────┴──╯
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
