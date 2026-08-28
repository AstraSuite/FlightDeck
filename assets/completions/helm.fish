# fish completion for helm

complete -c helm -s g -l gui -d "Launch graphical interface"
complete -c helm -s t -l tray -d "Launch minimized in system tray"
complete -c helm -s h -l help -d "Show help"
complete -c helm -s v -l version -d "Show version"

complete -c helm -n "__fish_use_subcommand" -a "get" -d "Get a configuration variable"
complete -c helm -n "__fish_use_subcommand" -a "set" -d "Set a configuration variable"
complete -c helm -n "__fish_use_subcommand" -a "reload" -d "Reload Hyprland compositor"
complete -c helm -n "__fish_use_subcommand" -a "profile" -d "Manage configuration profiles"

complete -c helm -n "__fish_seen_subcommand_from profile" -a "list create restore delete"
