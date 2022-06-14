case "$(tr '[:upper:]' '[:lower:]' </proc/version)" in
  *microsoft*|*wsl* )
    JUMP_DIR="$(wslpath -u "$(cmd.exe /C 'echo %USERPROFILE%\\jumppoints' 2>/dev/null)" | tr -d '\r')"
    __jump_path_to_native() { wslpath -w "$1"; }
    __jump_path_from_native() { wslpath -u "$1"; }
  ;;
  *cygwin*|*mingw* )
    JUMP_DIR="$(cygpath -u "$(cmd.exe /c 'echo %USERPROFILE%\\jumppoints')" | tr -d '\r')"
    __jump_path_to_native() { cygpath -w "$1"; }
    __jump_path_from_native() { cygpath -u "$1"; }
  ;;
  *)
    JUMP_DIR="$HOME/jumppoints"
    __jump_path_to_native() { printf "%s\n" "$1"; }
    __jump_path_from_native() { printf "%s\n" "$1"; }
  ;;
esac


jump() {
    if [ ! -d "$JUMP_DIR" ]; then
        mkdir "$JUMP_DIR"
    fi
    case "$1" in
        -c)
            if [ -z "$2" ]; then
                echo "Specify a name for the bookmark" >&2
                return 1
            elif [ "${2#*/}" != "$2" ]; then
                echo "Bookmark name may not contain slashes"
            elif [ "$2" = "." ] || [ "$2" = ".." ]; then
                echo "Bookmark name invalid."
            fi
            if [ -e "$JUMP_DIR/$2" ] && [ "$2" != '-' ]; then
                printf 'You already have a bookmark with that name. Do you want to replace it? (y/N):\n'
                read -r REPLY
                case "$REPLY" in
                    y|Y|yes|Yes|YES)
                        : # Continue
                    ;;
                    *)
                        printf 'Canceled\n' >&2
                        return 1
                    ;;
                esac
            fi

            __jump_path_to_native "$(pwd)" > "$JUMP_DIR/$2"
            printf "Created bookmark %s to %s\n" "$2" "$(pwd)"
        ;;
        -d)
            if [ -n "$2" ]; then
                if [ -e "$JUMP_DIR"/"$2" ]; then
                    rm -- "$JUMP_DIR"/"$2"
                    printf "Deleted bookmark %s\n" "$2"
                else
                    printf 'No such bookmark\n'
                    return 1
                fi
            else
                printf 'Specify the name of the bookmark to delete\n'
                return 1
            fi
        ;;
        -g)
            if [ -n "$2" ]; then
                if [ -e "$JUMP_DIR"/"$2" ]; then
                    __jump_path_from_native "$(cat "$JUMP_DIR"/"$2")"
                else
                    printf 'No such bookmark\n'
                    return 1
                fi
            else
                {
                    for file in "$JUMP_DIR"/*; do
                        if [ -f "$file" ]; then
                            read -r line < "$file"
                            printf "%s\t%s\n" "${file##*/}" "$(__jump_path_from_native "$line")"
                        fi
                    done
                } | column -t
            fi
        ;;
        --prune) (
            counter="0"
            for file in "$JUMP_DIR"/*; do
                if [ -f "$file" ]; then
                    read -r location < "$file"
                    if [ ! -d "$(__jump_path_from_native "$location")" ]; then
                        rm "$file";
                        counter="$(("$counter" + 1))"
                    fi
                fi
            done
            printf "Pruned %s bookmarks(s)\n" "$counter"
        );;
        --help|"")
            printf 'Jump: Bookmark directories in the terminal\n\n'
            printf 'usage: jump [options] BOOKMARK\n\n'
            printf 'Optional flags:\n'
            printf '  -d       Delete the specified bookmark\n'
            printf '  -c       Create a bookmark with the given name in the current directory\n'
            printf '  -g       List all available bookmarks\n'
            printf '  --prune  Delete any bookmarks that point to non-existant directories.\n'
            return 0
        ;;
        -?*)
            echo "Unknown option. See jump --help"
        ;;
        *)
            if [ -z "$1" ]; then
                echo "Specify the bookmark to jump to" >&2
                return 1
            elif [ ! -e "$JUMP_DIR"/"$1" ]; then
                echo "No such bookmark" >&2
                return 1
            fi
            cd "$( __jump_path_from_native "$(cat "$JUMP_DIR/$1")")" || return 1
        ;;
    esac
}

if [ -n "$BASH_VERSION" ]; then
    # Bash completions
    _jump_completion() {
        local WORD
        local COMPLETIONS
        WORD="${COMP_WORDS[COMP_CWORD]}"
        COMPLETIONS=$(find "$JUMP_DIR" -type f | awk -F/ '{print $NF}')
        COMPREPLY=( $(compgen -W "$COMPLETIONS" -- "$WORD") )
    }

    complete -F _jump_completion jump
    complete -F _jump_completion j

elif [ -n "$ZSH_VERSION" ]; then
    # Zsh completions
    _jump_completion() {
        local COMPLETIONS
        COMPLETIONS="$(find "$JUMP_DIR" -type f | awk -F/ '{print $NF}')"
        _arguments -C "1: :($COMPLETIONS)" "2: :($COMPLETIONS)"
    }

    compdef _jump_completion j
    compdef _jump_completion jump
fi

alias j=jump
