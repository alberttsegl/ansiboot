_ansiboot_complete() {
    local cur prev words cword
    _init_completion -n : || return

    local base_cmds sub_cmds flags inventory_groups inventory_hosts

    base_cmds="init install inventory ssh ping adhoc self-check uninstall help version"
    sub_cmds="list show generate validate"
    flags="--dry-run --force --verbose --quiet --limit --user --port --with-ssh-key --yes"

    inventory_groups=()
    inventory_hosts=()

    if [[ -f "$HOME/.ansiboot_cache" ]]; then
        mapfile -t inventory_groups < <(grep '^group:' "$HOME/.ansiboot_cache" | cut -d: -f2)
        mapfile -t inventory_hosts < <(grep '^host:' "$HOME/.ansiboot_cache" | cut -d: -f2)
    fi

    if [[ "$cword" -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "$base_cmds" -- "$cur") )
        return
    fi

    case "${words[1]}" in
        inventory)
            COMPREPLY=( $(compgen -W "$sub_cmds $flags" -- "$cur") )
            return
            ;;
        ssh|ping|adhoc)
            COMPREPLY=( $(compgen -W "${inventory_groups[*]} ${inventory_hosts[*]} $flags" -- "$cur") )
            return
            ;;
        uninstall)
            COMPREPLY=( $(compgen -W "--with-ssh-key --force --yes" -- "$cur") )
            return
            ;;
        self-check)
            COMPREPLY=( $(compgen -W "--strict --quiet" -- "$cur") )
            return
            ;;
        *)
            COMPREPLY=( $(compgen -W "$flags" -- "$cur") )
            return
            ;;
    esac
}

complete -F _ansiboot_complete ansiboot
