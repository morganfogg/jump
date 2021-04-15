# Jump - Bookmark directories in the terminal. (Windows Subsystem for Linux version)
# Compatible with Bash, Zsh and probably most other sh-based shells.
# https://github.com/morganfogg/jump

JUMPFILE=$(wslpath -u "$(cmd.exe /c "echo %USERPROFILE%\\jump.tsv")" | tr -d '\r')

function jump() {
    if  [ ! -e "$JUMPFILE" ] ; then
        printf "Name\tPath\n" > "$JUMPFILE"
    fi
    local MATCH
    case $1 in
        -c) shift
            if [ -z "$1" ]; then
                echo "Specify the name of the bookmark"
                return 1
            fi
            MATCH="$(awk -F "\t" -v name="$1" 'BEGIN {IGNORECASE = 1;} NF >  1&& NR > 1 && name == $1 {print $2}' "$JUMPFILE")"
            if [ -z "$MATCH" ]; then
                printf "%s\t%s\n" "$1" "$(wslpath -w "$(pwd)")" >> "$JUMPFILE"
                printf "Created bookmark %s to %s\n" "$1" "$(pwd)"
            else
                echo "You already have a bookmark with that name. Do you want to replace it? (y/N): "
                read -r REPLY
                case "$REPLY" in
                    y|Y|yes|Yes|YES)
                        local UPDATED
                        UPDATED=$(awk -F "\t" -v name="$1" 'BEGIN {IGNORECASE = 1;} NF > 1 && NR > 1 && name != $1 {print $0}' "$JUMPFILE")
                        printf "Name\tPath\n" > "$JUMPFILE"
                        printf "%s\n" "$UPDATED" >> "$JUMPFILE"
                        printf "%s\t%s\n" "$1" "$(wslpath -w "$(pwd)")" >> "$JUMPFILE"

                        printf "Updated bookmark %s to %s\n" "$1" "$(pwd)"
                    ;;
                    *)
                        echo "Canceled"
                        return 1
                    ;;
                esac
            fi
        ;;
        -d) shift
            if [ -z "$1" ]; then
                echo "Specify the name of the bookmark"
                return 1
            fi
            MATCH="$(awk -F "\t" -v name="$1" 'BEGIN {IGNORECASE = 1;} name == $1 {print $2}' "$JUMPFILE")"
            if [ -z "$MATCH" ]; then
                echo "No such bookmark"
                return 1
            else
                local UPDATED
                UPDATED=$(awk -F "\t" -v name="$1" 'BEGIN {IGNORECASE = 1;} NF > 1 && NR > 1 && name != $1 {print $0}' "$JUMPFILE")
                printf "Name\tPath\n%s\n" "$UPDATED" > "$JUMPFILE"
                echo "Bookmark deleted"
            fi
        ;;
        -l)
            awk -F "\t" '{print $1, "->", $2}' "$JUMPFILE"
        ;;
        --help|"")
            echo "Jump: Bookmark directories in the terminal"
            echo ""
            echo "usage: jump [options] BOOKMARK"
            echo ""
            echo "Optional flags:"
            echo "  -d    Delete the specified bookmark"
            echo "  -c    Create a bookmark with the given name in the current directory"
            echo "  -l    List all available bookmarks"
            echo ""
        ;;
        -?*)
            echo "Unrecognized option. See 'jump --help'"
        ;;
        *)
            MATCH="$(awk -F "\t" -v name="$1" 'BEGIN {IGNORECASE = 1;} NF > 1 && NR > 1 && name == $1 {print $2}' "$JUMPFILE")"
            RESULT_COUNT="$(printf "%s" "$MATCH" | wc -l)"
            if [ -z "$MATCH" ]; then
                echo "No such bookmark"
                return 1
            elif [ "$RESULT_COUNT" -gt 1 ]; then
                printf "Jumpfile invalid: Duplicate entries of bookmark %s\n. Please delete this bookmark and then recreate it, or edit the jumpfile manually to remove the duplicate.\n" "$1"
            else
                cd "$(wslpath -u "$MATCH" | tr -d '\r')" || return 1;
            fi
        ;;
    esac
}

alias j=jump

if type complete >/dev/null 2>&1; then
    # Bash completions
    function _jump_completion() {
        local WORD
        local COMPLETIONS
        WORD="${COMP_WORDS[COMP_CWORD]}"
        COMPLETIONS=$(awk -F "\t" 'BEGIN {IGNORECASE = 1;} NF > 1 && NR > 1 {print $1}' "$JUMPFILE")
        COMPREPLY=( $(compgen -W "$COMPLETIONS" -- "$WORD") )
    }

    complete -F _jump_completion jump
    complete -F _jump_completion j

elif type compdef >/dev/null 2>&1; then
    # Zsh completions
    function _jump_completion() {
        local COMPLETIONS
        COMPLETIONS=$(awk -F "\t" 'BEGIN {IGNORECASE = 1;} NF > 1 && NR > 1 {print $1}' "$JUMPFILE")
        _arguments -C "1: :($COMPLETIONS)" "2: :($COMPLETIONS)"
    }

    compdef _jump_completion j
    compdef _jump_completion jump
fi
