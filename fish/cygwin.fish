# Jump - Bookmark directories in the terminal (Fish for Cygwin version).
# https://github.com/morganfogg/jump

set JUMPFILE "$HOME/jump.tsv"

function jump
    if  [ ! -e "$JUMPFILE" ]
        printf "Name\tPath\n" > "$JUMPFILE"
    end
    set -l MATCH
    switch "$argv[1]"
        case "-c"
            if [ -z "$argv[2]" ]
                echo "Specify the name of the bookmark"
                return 1
            end
            set MATCH (awk -F "\t" -v name="$argv[2]" 'BEGIN {IGNORECASE = 1;} NF > 1 && NR > 1 && name == $1 {print $2}' "$JUMPFILE")
            if [ -z "$MATCH" ]
                printf "%s\t%s\n" "$argv[2]" (cygpath -w (pwd)) >> "$JUMPFILE"
                printf "Created bookmark %s to %s\n" "$argv[2]" (pwd)
            else
                echo "You already have a bookmark with that name. Do you want to replace it? (y/N): "
                read -P "Choose> " REPLY
                switch "$REPLY"
                    case y Y yes Yes YES
                        set -l UPDATED (awk -F "\t" -v name="$argv[2]" 'BEGIN {IGNORECASE = 1;} NF > 1 && NR > 1 && name != $1 {print $0}' "$JUMPFILE" | string split0)
                        printf "Name\tPath\n" > "$JUMPFILE"
                        printf "%s\n" "$UPDATED" >> "$JUMPFILE"
                        printf "%s\t%s\n" "$argv[2]" (cygpath -w (pwd)) >> "$JUMPFILE"
                        printf "Updated bookmark %s to %s\n" "$argv[2]" (pwd)
                    case "*"
                        echo "Canceled"
                        return 1
                end
            end
        case "-d"
            if [ -z "$argv[2]" ]
                echo "Specify the name of the bookmark"
                return 1
            end
            set MATCH (awk -F "\t" -v name="$argv[2]" 'BEGIN {IGNORECASE = 1;} NF > 1 && name == $1 {print $2}' "$JUMPFILE")
            if [ -z "$MATCH" ]
                echo "No such bookmark"
                return 1
            else
                set -l UPDATED (awk -F "\t" -v name="$argv[2]" 'BEGIN {IGNORECASE = 1;} NF > 1 && NR > 1 && name != $1 {print $0}' "$JUMPFILE" | string split0)
                printf "Name\tPath\n%s\n" "$UPDATED" > "$JUMPFILE"
                echo "Bookmark deleted"
            end
        case "-l"
            awk -F "\t" '{print $1, "->", $2}' "$JUMPFILE"
        case "--help" ""
            echo "Jump: Bookmark directories in the terminal"
            echo ""
            echo "usage: jump [options] BOOKMARK"
            echo ""
            echo "Optional flags:"
            echo "  -d    Delete the specified bookmark"
            echo "  -c    Create a bookmark with the given name in the current directory"
            echo "  -l    List all available bookmarks"
            echo ""
        case "-?*"
            echo "Unrecognized option. See 'jump --help'"
        case "*"
            set MATCH (awk -F "\t" -v name="$argv[1]" 'BEGIN {IGNORECASE = 1;} NF > 1 && NR > 1 && name == $1 {print $2}' "$JUMPFILE")
            set -l RESULT_COUNT (printf "%s" "$MATCH" | wc -l)
            if [ -z "$MATCH" ]
                echo "No such bookmark"
                return 1
            else if [ "$RESULT_COUNT" -gt 1 ]
                printf "Jumpfile invalid: Duplicate entries of bookmark %s\n. Please delete this bookmark and then recreate it, or edit the jumpfile manually to remove the duplicate.\n" "$1"
            else
                cd (printf "%s" (cygpath -u "$MATCH") | tr -d '\r'); or return 1;
            end
    end
end

alias j=jump

complete -f -c jump -a '(awk -F "\t" \'BEGIN {IGNORECASE = 1;} NR > 1 {print $1}\' "$JUMPFILE")'
complete -c j -w jump
