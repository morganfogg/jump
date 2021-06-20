# Jump - Bookmark directories in the terminal (Fish version).
{{note}}
# Get the latest version from https://github.com/morganfogg/jump

{% if isWSL %}
set JUMPFILE (wslpath -u (cmd.exe /c 'echo %USERPROFILE%\\jump.tsv') | tr -d '\r')
{% else %}
set JUMPFILE "$HOME/jump.tsv"
{% endif %}

function jump
    if  [ ! -e "$JUMPFILE" ]
        printf "Name\tPath\n" > "$JUMPFILE"
    end
    set -l match
    {% if pathToNativeConverter %}
    set -l native_wd ({{pathToNativeConverter}} (pwd))
    {% else %}
    set -l native_wd (pwd)
    {% endif %}

    {% if pathFromNativeConverter or pathToNativeConverter %}
    # From https://www.gnu.org/software/gawk/manual/html_node/Shell-Quoting.html
    set -l SHELL_QUOTE '
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
    {% endif %}
    switch "$argv[1]"
        case "-c"
            if [ -z "$argv[2]" ]
                echo "Specify the name of the bookmark"
                return 1
            end
            set match (awk -F "\t" -v name="$argv[2]" 'NF > 1 && NR > 1 && tolower(name) == tolower($1) {print $2}' "$JUMPFILE")
            if [ -z "$match" ]
                printf "%s\t%s\n" "$argv[2]" "$native_wd" >> "$JUMPFILE"
                printf "Created bookmark %s to %s\n" "$argv[2]" (pwd)
            else
                echo "You already have a bookmark with that name. Do you want to replace it? (y/N): "
                read -P "Choose> " REPLY
                switch "$REPLY"
                    case y Y yes Yes YES
                        set -l updated (awk -F "\t" -v name="$argv[2]" 'NF > 1 && NR > 1 && tolower(name) != tolower($1) {print}' "$JUMPFILE" | string split0)
                        printf "Name\tPath\n" > "$JUMPFILE"
                        printf "%s\n" "$updated" >> "$JUMPFILE"
                        printf "%s\t%s\n" "$argv[2]" "$native_wd" >> "$JUMPFILE"
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
            set match (awk -F "\t" -v name="$argv[2]" 'NF >  1&& tolower(name) == tolower($1) {print $2}' "$JUMPFILE")
            if [ -z "$match" ]
                echo "No such bookmark"
                return 1
            else
                set -l updated (awk -F "\t" -v name="$argv[2]" 'NF > 1 && NR > 1 && tolower(name) != tolower($1) {print}' "$JUMPFILE" | string split0)
                printf "Name\tPath\n%s\n" "$updated" > "$JUMPFILE"
                echo "Bookmark deleted"
            end
        case "-g"
            if [ -n "$1" ]
                set match (awk -F "\t" -v name="$1" "$SHELL_QUOTE"'
                    NR > 1 && tolower(name) == tolower($1) {
                        {% if pathFromNativeConverter %}
                        "{{ pathFromNativeConverter }} " shell_quote($2) | getline result
                        print result
                        {% else %}
                        print $2
                        {% endif %}
                        exit
                    }
                ' "$JUMPFILE")
                if [ -z "$match" ]
                    echo "No such bookmark"
                    return 1
                end
                printf "%s\n" "$match"
            else
                awk -F "\t" "$SHELL_QUOTE"'
                    NR == 1 { next }
                    {
                        {% if pathFromNativeConverter %}
                        "{{pathFromNativeConverter}} " shell_quote($2) | getline result
                        results[$1] = result
                        {% else %}
                        results[$1] = $2
                        {% endif %}
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

        case "--help" ""
            printf "Jump: Bookmark directories in the terminal\n\n"
            printf "usage: jump [options] BOOKMARK\n\n"
            printf "Optional flags:\n"
            printf "  -d    Delete the specified bookmark\n"
            printf "  -c    Create a bookmark with the given name in the current directory\n"
            printf "  -l    List all available bookmarks\n"
        case "-?*"
            echo "Unrecognized option. See 'jump --help'"
        case "*"
            set match (awk -F "\t" -v name="$argv[1]" 'NF > 1 && NR > 1 && tolower(name) == tolower($1) {print $2}' "$JUMPFILE")
            set -l result_count (printf "%s" "$match" | wc -l)
            if [ -z "$match" ]
                echo "No such bookmark"
                return 1
            else if [ "$result_count" -gt 1 ]
                printf "Jumpfile invalid: Duplicate entries of bookmark %s\n. Please delete this bookmark and then recreate it, or edit the jumpfile manually to remove the duplicate.\n" "$1"
            else
                {% if pathFromNativeConverter %}
                cd ({{pathFromNativeConverter}} "$match"); or return 1
                {% else %}
                cd "$match"; or return 1
                {%- endif %}
            end
    end
end

alias j=jump

complete -f -c jump -a '(awk -F "\t" \'NR > 1 {print $1}\' "$JUMPFILE")'
complete -c j -w jump
