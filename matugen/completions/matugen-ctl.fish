# Completion for matugen-ctl. Fish loads it lazily from
# ~/.config/fish/completions/matugen-ctl.fish, so this file only drives the menu.
# Keep it in sync with the usage() block in matugen/matugen-ctl.

# Resolve the wrapper (possibly a symlink in ~/.local/bin) so the lists below
# follow the checkout instead of hardcoding ~/.dotfile.
function __matugen_ctl_root --description 'Directory of the installed matugen-ctl'
    set -l bin (command -v matugen-ctl)
    test -n "$bin"; or return 1
    path dirname (path resolve $bin)
end

function __matugen_feel_profiles --description 'Feel profiles from core/feel/blueprint'
    set -l root (__matugen_ctl_root); or return
    set -l files $root/core/feel/blueprint/*.json
    test -e $files[1]; or return
    path basename -- $files | string replace -r '\.json$' ''
end

function __matugen_consumers --description 'Render consumers reported by palette.sh'
    set -l root (__matugen_ctl_root); or return
    test -x $root/script/palette.sh; or return
    $root/script/palette.sh --list 2>/dev/null
end

complete -c matugen-ctl -f
complete -c matugen-ctl -s h -l help -d 'Show help'

complete -c matugen-ctl -n '__fish_use_subcommand' -a palette -d 'Render a palette from a wallpaper or blueprint'
complete -c matugen-ctl -n '__fish_use_subcommand' -a feel -d 'Render a feel profile'
complete -c matugen-ctl -n '__fish_use_subcommand' -a reload -d 'Reload consumers without rendering'
complete -c matugen-ctl -n '__fish_use_subcommand' -a list -d 'List palettes, feel profiles, consumers'
complete -c matugen-ctl -n '__fish_use_subcommand' -a status -d 'Show the active palette and feel profile'
complete -c matugen-ctl -n '__fish_use_subcommand' -a help -d 'Show help'

complete -c matugen-ctl -n '__fish_seen_subcommand_from palette' -F
complete -c matugen-ctl -n '__fish_seen_subcommand_from palette' -s n -l dry-run -d 'Render without activating'
complete -c matugen-ctl -n '__fish_seen_subcommand_from palette' -l list -d 'List consumers and exit'

complete -c matugen-ctl -n '__fish_seen_subcommand_from feel' -a '(__matugen_feel_profiles)' -d 'Feel profile'
complete -c matugen-ctl -n '__fish_seen_subcommand_from reload' -a '(__matugen_consumers)' -d 'Consumer'
