# Jump - Bookmark directories in the terminal (Bash/Zsh version)
# This version is designed for Cygwin-based environments including Git Bash and MSYS2
# Get the latest version from https://github.com/morganfogg/jump

JUMPFILE="$HOME/jump.tsv"

jump() {
    local GET_BOOKMARK_PATH_SCRIPT
    GET_BOOKMARK_PATH_SCRIPT='NF > 1 && NR > 1 && tolower(name) == tolower($1) {print $2}'
    local REMOVE_BOOKMARK_SCRIPT
    REMOVE_BOOKMARK_SCRIPT='NF > 1 && NR > 1 && tolower(name) != tolower($1) {print $0}'
    # From https://www.gnu.org/software/gawk/manual/html_node/Shell-Quoting.html
    local SHELL_QUOTE
    SHELL_QUOTE='
        function shell_quote(s,
            SINGLE, QSINGLE, i, X, n, ret)
        {
            if (s == "")
                return "\"\""

            SINGLE = "\x27"  # single quote
            QSINGLE = "\"\x27\""
            n = split(s, X, SINGLE)

            ret = SINGLE X[1] SINGLE
            for (i = 2; i <= n; i++)
                ret = ret QSINGLE SINGLE X[i] SINGLE

            return ret
        }
        '

    if  [ ! -e "$JUMPFILE" ] ; then
        printf "Name\tPath\n" > "$JUMPFILE"
    fi

    sed -i 's/\r\n/\n/g' "$JUMPFILE" # Correct CRLF line endings

    local match
    local native_wd
    native_wd="$(cygpath -w "$(pwd)")"

    case $1 in
        -c) shift
            if [ -z "$1" ]; then
                echo "Specify the name of the bookmark"
                return 1
            fi
            match="$(awk -F "\t" -v name="$1" "$GET_BOOKMARK_PATH_SCRIPT" "$JUMPFILE")"
            if [ -z "$match" ]; then
                printf "%s\t%s\n" "$1" "$native_wd" >> "$JUMPFILE"
                printf "Created bookmark %s to %s\n" "$1" "$(pwd)"
            else
                echo "You already have a bookmark with that name. Do you want to replace it? (y/N): "
                read -r REPLY
                case "$REPLY" in
                    y|Y|yes|Yes|YES)
                        local updated
                        updated=$(awk -F "\t" -v name="$1" "$REMOVE_BOOKMARK_SCRIPT" "$JUMPFILE")
                        printf "Name\tPath\n" > "$JUMPFILE"
                        printf "%s\n" "$updated" >> "$JUMPFILE"
                        printf "%s\t%s\n" "$1" "$native_wd" >> "$JUMPFILE"

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
            match="$(awk -F "\t" -v name="$1" "$GET_BOOKMARK_PATH_SCRIPT" "$JUMPFILE")"
            if [ -z "$match" ]; then
                echo "No such bookmark"
                return 1
            else
                local updated
                updated=$(awk -F "\t" -v name="$1" "$REMOVE_BOOKMARK_SCRIPT" "$JUMPFILE")
                printf "Name\tPath\n%s\n" "$updated" > "$JUMPFILE"
                echo "Bookmark deleted"
            fi
        ;;
        -g) shift
            if [ -n "$1" ]; then
                match="$(awk -F "\t" -v name="$1" "$SHELL_QUOTE"'
                    NR > 1 && tolower(name) == tolower($1) {
                        "cygpath -u " shell_quote($2) | getline result
                        print result
                        exit
                    }
                ' "$JUMPFILE")"
                if [ -z "$match" ]; then
                    echo "No such bookmark"
                    return 1
                fi
                echo "$match"
            else
                awk -F "\t" "$SHELL_QUOTE"'
                NR == 1 { next }
                {
                    "cygpath -u " shell_quote($2) | getline result
                    results[$1] = result
                    if (length($1) > maxlength) {
                        maxlength = length($1)
                    }
                }
                END {
                    for (key in results) {
                        printf "%" maxlength "s | %s\n", key, results[key]
                    }
                }
            ' "$JUMPFILE" | sort -b
            fi
        ;;
        --help|"")
            printf "Jump: Bookmark directories in the terminal\n\n"
            printf "usage: jump [options] BOOKMARK\n\n"
            printf "Optional flags:\n"
            printf "  -d    Delete the specified bookmark\n"
            printf "  -c    Create a bookmark with the given name in the current directory\n"
            printf "  -l    List all available bookmarks\n"
        ;;
        -?*)
            printf "Unrecognized option. See 'jump --help'\n"
        ;;
        *)
            local result_count;
            match="$(awk -F "\t" -v name="$1" "$GET_BOOKMARK_PATH_SCRIPT" "$JUMPFILE")"
            result_count="$(printf "%s" "$match" | wc -l)"
            if [ -z "$match" ]; then
                echo "No such bookmark"
                return 1
            elif [ "$result_count" -gt 1 ]; then
                printf "Jumpfile invalid: Duplicate entries of bookmark %s\n. Please delete this bookmark and then recreate it, or edit the jumpfile manually to remove the duplicate.\n" "$1"
            else
                cd "$(cygpath -u "$match")" || return 1
            fi
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
        COMPLETIONS=$(awk -F "\t" 'NF > 1 && NR > 1 {print $1}' "$JUMPFILE")
        COMPREPLY=( $(compgen -W "$COMPLETIONS" -- "$WORD") )
    }

    complete -F _jump_completion jump
    complete -F _jump_completion j

elif [ -n "$ZSH_VERSION" ]; then
    # Zsh completions
    _jump_completion() {
        local COMPLETIONS
        COMPLETIONS=$(awk -F "\t" 'NF > 1 && NR > 1 {print $1}' "$JUMPFILE")
        _arguments -C "1: :($COMPLETIONS)" "2: :($COMPLETIONS)"
    }

    compdef _jump_completion j
    compdef _jump_completion jump
fi
