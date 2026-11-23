# Completion for eww-ctl. Fish loads it lazily from
# ~/.config/fish/completions/eww-ctl.fish, so this file only drives the menu.
# Keep it in sync with the argparse surface in eww/eww-ctl.

complete -c eww-ctl -f
complete -c eww-ctl -s h -l help -d 'Show help'

complete -c eww-ctl -n '__fish_use_subcommand' -a daemon -d 'Eww daemon lifecycle (the one start path)'
complete -c eww-ctl -n '__fish_use_subcommand' -a bar -d 'Bar modules; the island bar lives here'
complete -c eww-ctl -n '__fish_use_subcommand' -a open -d 'Open a window'
complete -c eww-ctl -n '__fish_use_subcommand' -a close -d 'Close a window'
complete -c eww-ctl -n '__fish_use_subcommand' -a toggle -d 'Toggle a window'
complete -c eww-ctl -n '__fish_use_subcommand' -a reload -d 'Reload Yuck/SCSS without restarting the daemon'
complete -c eww-ctl -n '__fish_use_subcommand' -a status -d 'Daemon state and open windows'
complete -c eww-ctl -n '__fish_use_subcommand' -a validate -d 'Compile SCSS/Python and validate settings/includes'

complete -c eww-ctl -n '__fish_seen_subcommand_from daemon' -a 'start stop restart status' -d 'Daemon action'

complete -c eww-ctl -n '__fish_seen_subcommand_from bar' -a island -d 'Island bar'
complete -c eww-ctl -n '__fish_seen_subcommand_from island' -a 'start stop toggle reload status doctor action' -d 'Island action'
complete -c eww-ctl -n '__fish_seen_subcommand_from island' -l monitor -r -f -d 'Connector name or Eww monitor index'

set -l windows islands calendar-popup music-popup profile distro depth-clock
complete -c eww-ctl -n '__fish_seen_subcommand_from open close toggle' -a "$windows" -d 'Window'

set -l island_actions launcher workspace volume-mute volume-scroll volume-set brightness-scroll brightness-set \
    music-toggle music-scroll music-previous music-next music-panel-toggle music-panel-close \
    calendar-toggle calendar-previous calendar-next calendar-today notifications dnd network power
complete -c eww-ctl -n '__fish_seen_subcommand_from action' -a "$island_actions" -d 'Island action'
