# Completion for constellia. Fish loads it lazily from
# ~/.config/fish/completions/constellia.fish.
# Keep it in sync with the usage() block in constellia/constellia.

complete -c constellia -f
complete -c constellia -s h -l help -d 'Show help'
complete -c constellia -l dry-run -d 'Print the backend argv, run nothing'
complete -c constellia -l wm -r -a 'hypr niri' -d 'Override WM detection'
complete -c constellia -l json -d 'JSON output for status and doctor'

complete -c constellia -n '__fish_use_subcommand' -a launcher -d 'Rofi menus or Noctalia launcher'
complete -c constellia -n '__fish_use_subcommand' -a notifications -d 'Notification panel and DND'
complete -c constellia -n '__fish_use_subcommand' -a screenshot -d 'Screen capture'
complete -c constellia -n '__fish_use_subcommand' -a wallpaper -d 'Wallpaper engine'
complete -c constellia -n '__fish_use_subcommand' -a session -d 'Lock, menu, power, DPMS'
complete -c constellia -n '__fish_use_subcommand' -a idle -d 'swayidle (atlanta only)'
complete -c constellia -n '__fish_use_subcommand' -a caffeine -d 'Idle inhibitor (noctalia only)'
complete -c constellia -n '__fish_use_subcommand' -a nightlight -d 'Nightlight'
complete -c constellia -n '__fish_use_subcommand' -a volume -d 'Volume and OSD'
complete -c constellia -n '__fish_use_subcommand' -a mic -d 'Microphone mute'
complete -c constellia -n '__fish_use_subcommand' -a brightness -d 'Backlight'
complete -c constellia -n '__fish_use_subcommand' -a bar -d 'Active shell bar'
complete -c constellia -n '__fish_use_subcommand' -a bar.panel -d 'Eww window (atlanta only)'
complete -c constellia -n '__fish_use_subcommand' -a osd -d 'Report volume, mic, brightness'
complete -c constellia -n '__fish_use_subcommand' -a theme -d 'Palette engine and theme status'
complete -c constellia -n '__fish_use_subcommand' -a feel -d 'matugen feel profile'
complete -c constellia -n '__fish_use_subcommand' -a shell -d 'Shell preference and lifecycle'
complete -c constellia -n '__fish_use_subcommand' -a status -d 'Shell per WM, with drift'
complete -c constellia -n '__fish_use_subcommand' -a doctor -d 'Backend paths and session'
complete -c constellia -n '__fish_use_subcommand' -a help -d 'Show help'

complete -c constellia -n '__fish_seen_subcommand_from launcher' -a 'apps run window toggle'
complete -c constellia -n '__fish_seen_subcommand_from notifications' -a 'toggle dnd clear'
complete -c constellia -n '__fish_seen_subcommand_from notifications; and __fish_seen_subcommand_from dnd' -a 'on off'
complete -c constellia -n '__fish_seen_subcommand_from screenshot' -a 'region screen window annotate'
complete -c constellia -n '__fish_seen_subcommand_from wallpaper' -a 'set next prev random pick status'
complete -c constellia -n '__fish_seen_subcommand_from wallpaper; and __fish_seen_subcommand_from set' \
    -a '(__fish_complete_path)' -d 'Image path'
complete -c constellia -n '__fish_seen_subcommand_from session' -a 'lock menu logout reboot poweroff dpms'
complete -c constellia -n '__fish_seen_subcommand_from session; and __fish_seen_subcommand_from dpms' -a 'off on'
complete -c constellia -n '__fish_seen_subcommand_from idle' -a 'toggle status'
complete -c constellia -n '__fish_seen_subcommand_from caffeine' -a 'toggle status'
complete -c constellia -n '__fish_seen_subcommand_from nightlight' -a 'toggle status'
complete -c constellia -n '__fish_seen_subcommand_from volume' -a 'up down mute'
complete -c constellia -n '__fish_seen_subcommand_from mic' -a 'toggle'
complete -c constellia -n '__fish_seen_subcommand_from brightness' -a 'up down'
complete -c constellia -n '__fish_seen_subcommand_from bar' -a 'show hide toggle status use switch'
complete -c constellia -n '__fish_seen_subcommand_from bar; and __fish_seen_subcommand_from use switch' -a 'waybar eww'
complete -c constellia -n '__fish_seen_subcommand_from bar.panel' -a 'toggle'
complete -c constellia -n '__fish_seen_subcommand_from bar.panel; and __fish_seen_subcommand_from toggle' \
    -a 'profile distro calendar-popup music-popup'
complete -c constellia -n '__fish_seen_subcommand_from osd' -a 'volume mic brightness'
complete -c constellia -n '__fish_seen_subcommand_from theme' -a 'palette status'
complete -c constellia -n '__fish_seen_subcommand_from theme; and __fish_seen_subcommand_from palette' \
    -a '(__fish_complete_path)' -d 'Wallpaper or blueprint'
complete -c constellia -n '__fish_seen_subcommand_from feel' -a 'default'
complete -c constellia -n '__fish_seen_subcommand_from shell' -a 'use select switch start stop status'
complete -c constellia -n '__fish_seen_subcommand_from shell; and __fish_seen_subcommand_from use switch' \
    -a 'noctalia atlanta'
