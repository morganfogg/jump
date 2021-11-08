# Jump - Bookmark directories in the terminal (Bash/Zsh version)
# Get the latest version from https://github.com/morganfogg/jump

case "$(uname -sv)" in
  *Microsoft*|*WSL* )
    JUMPFILE="$(wslpath -u "$(cmd.exe /c 'echo %USERPROFILE%\\jump.tsv')" | tr -d '\r')"
    __jump_path_to_native() { wslpath -w "$1"; }
    __jump_path_from_native() { wslpath -u "$1"; }
    __jump_list_bookmarks_script() {
paste /dev/fd/3 3<<-EOF /dev/fd/4 4<<-EOF | column -t
$(cut -f 1 "$JUMPFILE" | tail -n +2)
EOF
$(cut -f 2 "$JUMPFILE" | tail -n +2 | tr '\n' '\0' | xargs -0 -n1 wslpath -u)
EOF
    }
  ;;
  *CYGWIN*|*MINGW* )
    JUMPFILE="$(cygpath -u "$(cmd.exe /c 'echo %USERPROFILE%\\jump.tsv')" | tr -d '\r')"
    __jump_path_to_native() { cygpath -w "$1"; }
    __jump_path_from_native() { cygpath -u "$1"; }
    __jump_list_bookmarks_script() {
paste /dev/fd/3 3<<-EOF /dev/fd/4 4<<-EOF | column -t
$(cut -f 1 "$JUMPFILE" | tail -n +2)
EOF
$(cut -f 2 "$JUMPFILE" | tail -n +2 | cygpath -u -f -)
EOF
    }
  ;;
  *)
    JUMPFILE="$HOME/jump.tsv"
    __jump_path_to_native() { printf "%s\n" "$1"; }
    __jump_path_from_native() { printf "%s\n" "$1"; }
    __jump_list_bookmarks_script() { column -t "$JUMPFILE"; }
  ;;
esac

__JUMP_AWK_GET_BOOKMARK='NF > 1 && NR > 1 && tolower(name) == tolower($1) {print $2; exit}'
__JUMP_AWK_REMOVE_BOOKMARAK='NF > 1 && NR > 1 && tolower(name) != tolower($1) {print $0}'

jump() {
    if  [ ! -e "$JUMPFILE" ] ; then
        printf 'Name\tPath\n' > "$JUMPFILE"
    fi

    sed -i 's/\r\n/\n/g' "$JUMPFILE" # Correct any CRLF line endings

    local match

    case $1 in
        -c)
            if [ -z "$2" ]; then
                >&2 printf 'Specify the name of the bookmark\n'
                return 1
            elif [ "$#" -gt 2 ]; then
                >&2 printf 'Too many arguments\n'
                return 1
            fi
            local native_wd
            native_wd="$(__jump_path_to_native "$(pwd)")"

            match="$(awk -F '\t' -v name="$2" "$__JUMP_AWK_GET_BOOKMARK" "$JUMPFILE")"
            if [ -z "$match" ]; then
                printf '%s\t%s\n' "$2" "$native_wd" >> "$JUMPFILE"
                printf 'Created bookmark %s to %s\n' "$2" "$(pwd)"
            else
                printf 'You already have a bookmark with that name. Do you want to replace it? (y/N): \n'
                read -r REPLY
                case "$REPLY" in
                    y|Y|yes|Yes|YES)
                        local updated
                        updated="$(awk -F '\t' -v name="$2" "$__JUMP_AWK_REMOVE_BOOKMARAK" "$JUMPFILE")"
                        printf 'Name\tPath\n' > "$JUMPFILE"
                        printf '%s\n' "$updated" >> "$JUMPFILE"
                        printf '%s\t%s\n' "$2" "$native_wd" >> "$JUMPFILE"

                        printf 'Updated bookmark %s to %s\n' "$2" "$(pwd)"
                    ;;
                    *)
                        >&2 printf 'Canceled\n'
                        return 1
                    ;;
                esac
            fi
        ;;
        -d)
            if [ -z "$2" ]; then
                >&2 printf 'Specify the name of the bookmark\n'
                return 1
            elif [ "$#" -gt 2 ]; then
                >&2 printf 'Too many arguments\n'
                return 1
            fi
            match="$(awk -F '\t' -v name="$2" "$__JUMP_AWK_GET_BOOKMARK" "$JUMPFILE")"
            if [ -z "$match" ]; then
                >&2 printf 'No such bookmark\n'
                return 1
            else
                local updated
                updated="$(awk -F '\t' -v name="$2" "$__JUMP_AWK_REMOVE_BOOKMARAK" "$JUMPFILE")"
                printf 'Name\tPath\n%s\n' "$updated" > "$JUMPFILE"
                printf 'Bookmark deleted\n'
            fi
        ;;
        -g)
            if [ "$#" -gt 2 ]; then
                >&2 printf 'Too many arguments\n';
                return 1;
            fi
            if [ -n "$2" ]; then
                match="$(awk -F "\t" -v name="$2" '
                    NR > 1 && tolower(name) == tolower($1) {
                        print $2
                        exit
                    }
                ' "$JUMPFILE")"
                if [ -z "$match" ]; then
                    >&2 printf 'No such bookmark\n'
                    return 1
                fi
                __jump_path_from_native "$match"
            else
               __jump_list_bookmarks_script
            fi
        ;;
        --help|"")
            printf 'Jump: Bookmark directories in the terminal\n\n'
            printf 'usage: jump [options] BOOKMARK\n\n'
            printf 'Optional flags:\n'
            printf '  -d    Delete the specified bookmark\n'
            printf '  -c    Create a bookmark with the given name in the current directory\n'
            printf '  -l    List all available bookmarks\n'
        ;;
        -?*)
            printf 'Unrecognized option. See "jump --help"\n'
        ;;
        *)
            if [ "$#" -gt 1 ]; then
                >&2 printf 'Too many arguments\n'
                return 1
            fi
            local result_count;
            match="$(awk -F '\t' -v name="$1" "$__JUMP_AWK_GET_BOOKMARK" "$JUMPFILE")"
            result_count="$(printf '%s' "$match" | wc -l)"
            if [ -z "$match" ]; then
                >&2 printf 'No such bookmark\n'
                return 1
            elif [ "$result_count" -gt 1 ]; then
                >&2 printf 'Jumpfile invalid: Duplicate entries of bookmark %s\n. Please delete this bookmark and then recreate it, or edit the jumpfile manually to remove the duplicate.\n' "$1"
                return 1
            fi
            cd "$(__jump_path_from_native "$match")" || return 1
        ;;
    esac
}

alias j=jump

if [ -n "$BASH_VERSION" ]; then
    # Bash completions
    _jump_completion() {
        local WORD
        local COMPLETIONS
        WORD="${COMP_WORDS[COMP_CWORD]}"
        COMPLETIONS=$(awk -F '\t' 'NF > 1 && NR > 1 {print $1}' "$JUMPFILE")
        COMPREPLY=( $(compgen -W "$COMPLETIONS" -- "$WORD") )
    }

    complete -F _jump_completion jump
    complete -F _jump_completion j

elif [ -n "$ZSH_VERSION" ]; then
    # Zsh completions
    _jump_completion() {
        local COMPLETIONS
        COMPLETIONS=$(awk -F '\t' 'NF > 1 && NR > 1 {print $1}' "$JUMPFILE")
        _arguments -C "1: :($COMPLETIONS)" "2: :($COMPLETIONS)"
    }

    compdef _jump_completion j
    compdef _jump_completion jump
fi
