# Jump - Bookmark directories in the terminal (Fish version).
# NOTE: This particular version is intended for a regular Fish environment on *nix systems. If you are running a Fish
# environment on Windows (such as Git Bash, WSL or Cygwin), see instead either fish/wsl.sh or fish/cygwin.sh
# Get the latest version from https://github.com/morganfogg/jump

set JUMPFILE "$HOME/jump.tsv"

function jump
    set -l GET_BOOKMARK_PATH_SCRIPT 'NF > 1 && NR > 1 && tolower(name) == tolower($1) {print $2}'
    set -l REMOVE_BOOKMARK_SCRIPT 'NF > 1 && NR > 1 && tolower(name) != tolower($1) {print $0}'

    if  [ ! -e "$JUMPFILE" ]
        printf 'Name\tPath\n' > "$JUMPFILE"
    end

    set -l match
    set -l native_wd (pwd)

    switch "$argv[1]"
        case '-c'
            if [ -z "$argv[2]" ]
                echo 'Specify the name of the bookmark' >&2
                return 1
            else if [ (count $argv) -gt 2 ]; then
                printf 'Too many arguments\n' >&2
                return 1
            end
            set match (awk -F '\t' -v name="$argv[2]" "$GET_BOOKMARK_PATH_SCRIPT" "$JUMPFILE")
            if [ -z "$match" ]
                printf '%s\t%s\n' "$argv[2]" "$native_wd" >> "$JUMPFILE"
                printf 'Created bookmark %s to %s\n' "$argv[2]" (pwd)
            else
                echo 'You already have a bookmark with that name. Do you want to replace it? (y/N): '
                read -P 'Choose> ' REPLY
                switch "$REPLY"
                    case y Y yes Yes YES
                        set -l updated (awk -F '\t' -v name="$argv[2]" "$REMOVE_BOOKMARK_SCRIPT" "$JUMPFILE" | string split0)
                        printf 'Name\tPath\n' > "$JUMPFILE"
                        printf '%s\n' "$updated" >> "$JUMPFILE"
                        printf '%s\t%s\n' "$argv[2]" "$native_wd" >> "$JUMPFILE"
                        printf 'Updated bookmark %s to %s\n' "$argv[2]" (pwd)
                    case "*"
                        echo 'Canceled' >&2
                        return 1
                end
            end
        case "-d"
            if [ -z "$argv[2]" ]
                echo 'Specify the name of the bookmark' >&2
                return 1
            else if [ (count $argv) -gt 2 ]; then
                printf 'Too many arguments\n' >&2
                return 1
            end
            set match (awk -F '\t' -v name="$argv[2]" "$GET_BOOKMARK_PATH_SCRIPT" "$JUMPFILE")
            if [ -z "$match" ]
                echo 'No such bookmark' >&2
                return 1
            else
                set -l updated (awk -F '\t' -v name="$argv[2]" "$REMOVE_BOOKMARK_SCRIPT" "$JUMPFILE" | string split0)
                printf 'Name\tPath\n%s\n' "$updated" > "$JUMPFILE"
                echo 'Bookmark deleted'
            end
        case '-g'
            if [ (count $argv) -gt 2 ]; then
                printf 'Too many arguments\n' >&2
                return 1
            end
            if [ -n "$1" ]
                set match (awk -F "\t" -v name="$1" "$SHELL_QUOTE"'
                    NR > 1 && tolower(name) == tolower($1) {
                        print $2
                        exit
                    }
                ' "$JUMPFILE")
                if [ -z "$match" ]
                    echo 'No such bookmark' >&2
                    return 1
                end
                printf '%s\n' "$match"
            else
                awk -F "\t" "$SHELL_QUOTE"'
                    NR == 1 { next }
                    {
                        results[$1] = $2
                        if (length($1) > maxlength) {
                            maxlength = length($1);
                        }
                    }
                    END {
                        for (key in results) {
                            printf "%" maxlength "s | %s\n", key, results[key]
                        }
                    }
                ' "$JUMPFILE" | sort -b
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
            set match (awk -F '\t' -v name="$argv[1]" "$GET_BOOKMARK_PATH_SCRIPT" "$JUMPFILE")
            set -l result_count (printf '%s' "$match" | wc -l)
            if [ -z "$match" ]
                echo 'No such bookmark' >&2
                return 1
            else if [ "$result_count" -gt 1 ]
                printf 'Jumpfile invalid: Duplicate entries of bookmark %s\n. Please delete this bookmark and then recreate it, or edit the jumpfile manually to remove the duplicate.\n' "$1" >&2
                return 1
            end
            cd "$match"; or return 1
    end
end

alias j=jump

complete -f -c jump -a '(awk -F "\t" \'NR > 1 {print $1}\' "$JUMPFILE")'
complete -c j -w jump
