# Completion for rofi-ctl. Fish loads it lazily from
# ~/.config/fish/completions/rofi-ctl.fish, so this file only drives the menu.
# Keep it in sync with the usage() block in rofi/rofi-ctl.

complete -c rofi-ctl -f
complete -c rofi-ctl -s h -l help -d 'Show help'

complete -c rofi-ctl -n '__fish_use_subcommand' -a apps -d 'Application launcher'
complete -c rofi-ctl -n '__fish_use_subcommand' -a run -d 'Command launcher'
complete -c rofi-ctl -n '__fish_use_subcommand' -a window -d 'Window switcher'
complete -c rofi-ctl -n '__fish_use_subcommand' -a toggle -d 'Open/close the launcher'
complete -c rofi-ctl -n '__fish_use_subcommand' -a shell -d 'Choose Noctalia or Native'
complete -c rofi-ctl -n '__fish_use_subcommand' -a menu -d 'Text menu from stdin'
complete -c rofi-ctl -n '__fish_use_subcommand' -a wallpaper -d 'Wallpaper gallery'
complete -c rofi-ctl -n '__fish_use_subcommand' -a password -d 'Password prompt'
complete -c rofi-ctl -n '__fish_use_subcommand' -a help -d 'Show help'

# The second word is the launcher style, only for apps/run/toggle.
complete -c rofi-ctl -n '__fish_seen_subcommand_from apps run toggle' -a apps -d 'Classic two-column style'
complete -c rofi-ctl -n '__fish_seen_subcommand_from apps run toggle' -a orbit -d 'Side-panel launcher'

complete -c rofi-ctl -n '__fish_seen_subcommand_from wallpaper' \
    -s d -l dir -r -a '(__fish_complete_directories)' -d 'Image directory'
