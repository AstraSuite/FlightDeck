# fish completion for flightdeck

complete -c flightdeck -s g -l gui -d "Launch graphical interface"
complete -c flightdeck -s t -l tray -d "Launch minimized in system tray"
complete -c flightdeck -s h -l help -d "Show help"
complete -c flightdeck -s v -l version -d "Show version"

complete -c flightdeck -n "__fish_use_subcommand" -a "get" -d "Get a configuration variable"
complete -c flightdeck -n "__fish_use_subcommand" -a "set" -d "Set a configuration variable"
complete -c flightdeck -n "__fish_use_subcommand" -a "reload" -d "Reload Hyprland compositor"
complete -c flightdeck -n "__fish_use_subcommand" -a "profile" -d "Manage configuration profiles"

complete -c flightdeck -n "__fish_seen_subcommand_from profile" -a "list create restore delete"
