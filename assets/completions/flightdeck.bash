# bash completion for flightdeck
_flightdeck() {
    local cur prev words cword
    _init_completion || return

    local commands="get set reload profile --gui --tray --help --version"

    if [[ $cword -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
        return 0
    fi

    case "${words[1]}" in
        profile)
            local profile_cmds="list create restore delete"
            COMPREPLY=( $(compgen -W "$profile_cmds" -- "$cur") )
            return 0
            ;;
    esac
}

complete -F _flightdeck flightdeck
