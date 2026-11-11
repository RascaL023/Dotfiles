# Completion for waybar-ctl. Fish loads it lazily from
# ~/.config/fish/completions/waybar-ctl.fish, so this file only drives the menu.
# Keep it in sync with the usage() block in waybar/waybar-ctl.

complete -c waybar-ctl -f
complete -c waybar-ctl -s h -l help -d 'Show help'

complete -c waybar-ctl -n '__fish_use_subcommand' -a start -d 'Start the bar for this session'
complete -c waybar-ctl -n '__fish_use_subcommand' -a stop -d 'Stop the bar'
complete -c waybar-ctl -n '__fish_use_subcommand' -a toggle -d 'Start when stopped, stop when running'
complete -c waybar-ctl -n '__fish_use_subcommand' -a restart -d 'Stop, then start'
complete -c waybar-ctl -n '__fish_use_subcommand' -a reload -d 'Send SIGUSR2'
complete -c waybar-ctl -n '__fish_use_subcommand' -a status -d 'PID and session, or "not running"'
complete -c waybar-ctl -n '__fish_use_subcommand' -a config -d 'Config path for this session'
complete -c waybar-ctl -n '__fish_use_subcommand' -a run -d 'Run in the foreground'
complete -c waybar-ctl -n '__fish_use_subcommand' -a help -d 'Show help'

complete -c waybar-ctl -l session -r -f -a hyprland -d 'Force the Hyprland session'
complete -c waybar-ctl -l session -r -f -a niri -d 'Force the niri session'
