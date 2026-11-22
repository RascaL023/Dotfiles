# Completion for atlanta. Fish loads it lazily from
# ~/.config/fish/completions/atlanta.fish.
# Keep it in sync with the usage() block in atlanta/atlanta.

complete -c atlanta -f
complete -c atlanta -s h -l help -d 'Show help'

complete -c atlanta -n '__fish_use_subcommand' -a launcher -d 'Rofi menus'
complete -c atlanta -n '__fish_use_subcommand' -a bar -d 'Waybar'
complete -c atlanta -n '__fish_use_subcommand' -a bar.panel -d 'Eww panel (reserved)'
complete -c atlanta -n '__fish_use_subcommand' -a notifications -d 'SwayNC'
complete -c atlanta -n '__fish_use_subcommand' -a screenshot -d 'grim + slurp'
complete -c atlanta -n '__fish_use_subcommand' -a session -d 'Menu, lock, power'
complete -c atlanta -n '__fish_use_subcommand' -a idle -d 'hypridle'
complete -c atlanta -n '__fish_use_subcommand' -a nightlight -d 'hyprsunset'
complete -c atlanta -n '__fish_use_subcommand' -a wallpaper -d 'awww'
complete -c atlanta -n '__fish_use_subcommand' -a osd -d 'Report volume, mic, brightness'
complete -c atlanta -n '__fish_use_subcommand' -a volume -d 'Volume up, down, mute'
complete -c atlanta -n '__fish_use_subcommand' -a mic -d 'Microphone mute toggle'
complete -c atlanta -n '__fish_use_subcommand' -a brightness -d 'Backlight up, down'
complete -c atlanta -n '__fish_use_subcommand' -a status -d 'State per capability'
complete -c atlanta -n '__fish_use_subcommand' -a doctor -d 'Provider paths and session'
complete -c atlanta -n '__fish_use_subcommand' -a help -d 'Show help'

complete -c atlanta -n '__fish_seen_subcommand_from launcher' -a 'apps run window toggle'
complete -c atlanta -n '__fish_seen_subcommand_from bar' -a 'show hide toggle restart reload status'
complete -c atlanta -n '__fish_seen_subcommand_from bar' -l provider -r -a waybar -d 'Bar provider'
complete -c atlanta -n '__fish_seen_subcommand_from bar.panel' -a 'toggle'
complete -c atlanta -n '__fish_seen_subcommand_from notifications' -a 'toggle dnd'
complete -c atlanta -n '__fish_seen_subcommand_from screenshot' -a 'region screen window'
complete -c atlanta -n '__fish_seen_subcommand_from session' -a 'menu lock logout reboot poweroff'
complete -c atlanta -n '__fish_seen_subcommand_from idle' -a 'toggle status'
complete -c atlanta -n '__fish_seen_subcommand_from nightlight' -a 'toggle status'
complete -c atlanta -n '__fish_seen_subcommand_from wallpaper' -a 'set next prev random pick status'
complete -c atlanta -n '__fish_seen_subcommand_from osd' -a 'volume mic brightness'
complete -c atlanta -n '__fish_seen_subcommand_from volume' -a 'up down mute'
complete -c atlanta -n '__fish_seen_subcommand_from mic' -a 'toggle'
complete -c atlanta -n '__fish_seen_subcommand_from brightness' -a 'up down'
complete -c atlanta -n '__fish_seen_subcommand_from wallpaper; and __fish_seen_subcommand_from set' \
    -a '(__fish_complete_path)' -d 'Image path'
complete -c atlanta -n '__fish_seen_subcommand_from status' -l check -d 'Exit 1 when a provider is missing'
