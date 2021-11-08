# Jump - Bookmark directories in the terminal (Fish version).
# Get the latest version from https://github.com/morganfogg/jump

switch (uname -sv)
  case '*Microsoft*' '*WSL*'
    set JUMPFILE (wslpath -u (cmd.exe /c 'echo %USERPROFILE%\\jump.tsv') | tr -d '\r')
    function __jump_path_to_native; wslpath -w "$argv[1]"; end
    function __jump_path_from_native; wslpath -u "$argv[1]"; end
    function __jump_list_bookmarks_script
        paste (cut -f 1 "$JUMPFILE" | tail -n +2 | psub) (cut -f 2 "$JUMPFILE" | tail -n +2 | tr '\n' '\0' | xargs -0 -n1 wslpath -u | psub) | column -t
    end
  case '*CYGWIN*' '*MINGW*'
    set JUMPFILE (cygpath -u (cmd.exe /c 'echo %USERPROFILE%\\jump.tsv') | tr -d '\r')
    function __jump_path_to_native; wslpath -w "$argv[1]"; end
    function __jump_path_from_native; wslpath -u "$argv[1]"; end
    function __jump_list_bookmarks_script
        paste (cut -f 1 "$JUMPFILE" | tail -n +2 | psub) (cut -f 2 "$JUMPFILE" | tail -n +2 | tr '\n' '\0' | cygpath -u -f - | psub) | column -t
    end
  case '*'
    set JUMPFILE "$HOME/jump.tsv"
    function __jump_path_to_native; printf "%s\n" "$argv[1]"; end
    function __jump_path_from_native; printf "%s\n" "$argv[1]"; end
    function __jump_list_bookmarks_script; column -t "$JUMPFILE"; end
end

set __JUMP_AWK_GET_BOOKMARK 'NF > 1 && NR > 1 && tolower(name) == tolower($1) {print $2; exit}'
set __JUMP_AWK_REMOVE_BOOKMARAK 'NF > 1 && NR > 1 && tolower(name) != tolower($1) {print $0}'


function jump
    if  [ ! -e "$JUMPFILE" ]
        printf 'Name\tPath\n' > "$JUMPFILE"
    end

    set -l match
    set -l native_wd (__jump_path_to_native (pwd))

    switch "$argv[1]"
        case '-c'
            if [ -z "$argv[2]" ]
                echo 'Specify the name of the bookmark' >&2
                return 1
            else if [ (count $argv) -gt 2 ]; then
                printf 'Too many arguments\n' >&2
                return 1
            end
            set match (awk -F '\t' -v name="$argv[2]" "$__JUMP_AWK_GET_BOOKMARK" "$JUMPFILE")
            if [ -z "$match" ]
                printf '%s\t%s\n' "$argv[2]" "$native_wd" >> "$JUMPFILE"
                printf 'Created bookmark %s to %s\n' "$argv[2]" (pwd)
            else
                echo 'You already have a bookmark with that name. Do you want to replace it? (y/N): '
                read -P 'Choose> ' REPLY
                switch "$REPLY"
                    case y Y yes Yes YES
                        set -l updated (awk -F '\t' -v name="$argv[2]" "$__JUMP_AWK_REMOVE_BOOKMARAK" "$JUMPFILE" | string split0)
                        printf 'Name\tPath\n' > "$JUMPFILE"
                        printf '%s\n' "$updated" >> "$JUMPFILE"
                        printf '%s\t%s\n' "$argv[2]" "$native_wd" >> "$JUMPFILE"
                        printf 'Updated bookmark %s to %s\n' "$argv[2]" (pwd)
                    case "*"
                        echo 'Canceled' >&2
                        return 1
                end
            end
        case '-d'
            if [ -z "$argv[2]" ]
                echo 'Specify the name of the bookmark' >&2
                return 1
            else if [ (count $argv) -gt 2 ]; then
                printf 'Too many arguments\n' >&2
                return 1
            end
            set match (awk -F '\t' -v name="$argv[2]" "$__JUMP_AWK_GET_BOOKMARK" "$JUMPFILE")
            if [ -z "$match" ]
                echo 'No such bookmark' >&2
                return 1
            else
                set -l updated (awk -F '\t' -v name="$argv[2]" "$__JUMP_AWK_REMOVE_BOOKMARAK" "$JUMPFILE" | string split0)
                printf 'Name\tPath\n%s\n' "$updated" > "$JUMPFILE"
                echo 'Bookmark deleted'
            end
        case '-g'
            if [ (count $argv) -gt 2 ]; then
                printf 'Too many arguments\n' >&2
                return 1
            end
            if [ -n "$1" ]
                set match (awk -F "\t" -v name="$1" '
                    NR > 1 && tolower(name) == tolower($1) {
                        print $2
                        exit
                    }
                ' "$JUMPFILE")
                if [ -z "$match" ]
                    echo 'No such bookmark' >&2
                    return 1
                end
                __jump_path_from_native "$match"
            else
                __jump_list_bookmarks_script
            end

        case '--help' ''
            printf 'Jump: Bookmark directories in the terminal\n\n'
            printf 'usage: jump [options] BOOKMARK\n\n'
            printf 'Optional flags:\n'
            printf '  -d    Delete the specified bookmark\n'
            printf '  -c    Create a bookmark with the given name in the current directory\n'
            printf '  -l    List all available bookmarks\n'
        case '-?*'
            echo 'Unrecognized option. See "jump --help"'
        case '*'
            if [ (count $argv) -gt 1 ]; then
                printf 'Too many arguments\n' >&2
                return 1
            end
            set match (awk -F '\t' -v name="$argv[1]" "$__JUMP_AWK_GET_BOOKMARK" "$JUMPFILE")
            set -l result_count (printf '%s' "$match" | wc -l)
            if [ -z "$match" ]
                echo 'No such bookmark' >&2
                return 1
            else if [ "$result_count" -gt 1 ]
                printf 'Jumpfile invalid: Duplicate entries of bookmark %s\n. Please delete this bookmark and then recreate it, or edit the jumpfile manually to remove the duplicate.\n' "$1" >&2
                return 1
            end
            cd ( __jump_path_from_native "$match"); or return 1
    end
end

alias j=jump

complete -f -c jump -a '(awk -F "\t" \'NR > 1 {print $1}\' "$JUMPFILE")'
complete -c j -w jump
