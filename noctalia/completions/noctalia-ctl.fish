# Completion for noctalia-ctl, loaded lazily from
# ~/.config/fish/completions/noctalia-ctl.fish.

# Resolve the wrapper (possibly a symlink) so the lists follow the checkout.
function __noctalia_ctl_root --description 'Directory of the installed noctalia-ctl'
    set -l bin (command -v noctalia-ctl)
    test -n "$bin"; or return 1
    path dirname (path resolve $bin)
end

function __noctalia_consumers --description 'Consumers reported by palette.sh'
    set -l root (__noctalia_ctl_root); or return
    test -x $root/script/palette.sh; or return
    $root/script/palette.sh --list 2>/dev/null
end

complete -c noctalia-ctl -f
complete -c noctalia-ctl -s h -l help -d 'Show help'

complete -c noctalia-ctl -n '__fish_use_subcommand' -a palette -d 'Render a palette, activate it, then reload consumers'
complete -c noctalia-ctl -n '__fish_use_subcommand' -a help -d 'Show help'

complete -c noctalia-ctl -n '__fish_seen_subcommand_from palette' -F
complete -c noctalia-ctl -n '__fish_seen_subcommand_from palette' -s n -l dry-run -d 'Render without activating'
complete -c noctalia-ctl -n '__fish_seen_subcommand_from palette' -s N -l no-reload -d 'Activate without reloading consumers'
complete -c noctalia-ctl -n '__fish_seen_subcommand_from palette' -s s -l scheme -r -d 'Color generation scheme'
complete -c noctalia-ctl -n '__fish_seen_subcommand_from palette' -s b -l pure-black -d 'Re-anchor dark surfaces to true black'
complete -c noctalia-ctl -n '__fish_seen_subcommand_from palette' -l from-shell -d 'Render the palette Noctalia currently resolved'
complete -c noctalia-ctl -n '__fish_seen_subcommand_from palette' -s l -l list -d 'List consumers and exit'
complete -c noctalia-ctl -n '__fish_seen_subcommand_from palette' -a '(__noctalia_consumers)' -d 'Consumer'
