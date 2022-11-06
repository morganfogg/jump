# Jump - Bookmark directories in the terminal (Fish version).
# https://github.com/morganfogg/jump

switch (string lower </proc/version)
  case '*microsoft*' '*wsl*'
    set JUMP_DIR (wslpath -u (cmd.exe /c 'echo %USERPROFILE%\\jumppoints' 2>/dev/null) | tr -d '\r')
    function __jump_path_to_native; wslpath -w "$argv[1]"; end
    function __jump_path_from_native; wslpath -u "$argv[1]"; end
  case '*cygwin*' '*mingw*' '*msys*'
    set JUMP_DIR (cygpath -u (cmd.exe /c 'echo %USERPROFILE%\\jumppoints') | tr -d '\r')
    function __jump_path_to_native; cygpath -w "$argv[1]"; end
    function __jump_path_from_native; cygpath -u "$argv[1]"; end
  case '*'
    set JUMP_DIR "$HOME/jumppoints"
    function __jump_path_to_native; printf "%s\n" "$argv[1]"; end
    function __jump_path_from_native; printf "%s\n" "$argv[1]"; end
end

function jump
    if  [ ! -d "$JUMP_DIR" ]
        mkdir "$JUMP_DIR"
    end

    set -l match

    switch "$argv[1]"
        case '-c'
            if [ -z "$argv[2]" ]
                echo 'Specify the name of the bookmark' >&2
                return 1
            else if [ (count $argv) -gt 2 ]; then
                printf 'Too many arguments\n' >&2
                return 1
            end
            set match "$argv[2]"
            set -l native_wd (__jump_path_to_native (pwd))
            if [ -e "$JUMP_DIR"/"$argv[2]" ]
                echo 'You already have a bookmark with that name. Do you want to replace it? (y/N): '
                read -P 'Choose> ' REPLY
                switch "$REPLY"
                    case y Y yes Yes YES
                        :
                    case "*"
                        echo 'Canceled' >&2
                        return 1
                end
            end
            __jump_path_to_native (pwd) > "$JUMP_DIR"/"$match"
            printf 'Created bookmark %s to %s\n' "$match" (pwd)

        case '-d'
            if [ -z "$argv[2]" ]
                echo 'Specify the name of the bookmark' >&2
                return 1
            else if [ (count $argv) -gt 2 ]; then
                printf 'Too many arguments\n' >&2
                return 1
            end

            set match "$argv[2]"

            if [ ! -e "$JUMP_DIR"/"$match" ]
                echo 'No such bookmark' >&2
                return 1
            else
                rm -- "$JUMP_DIR"/"$match"
                echo 'Bookmark deleted'
            end
        case '-g'
            if [ (count $argv) -gt 2 ]; then
                printf 'Too many arguments\n' >&2
                return 1
            end
            if [ -n "$argv[2]" ]
                if [ -e "$argv[2]" ]
                    __jump_path_from_native (cat "$JUMP_DIR"/"$argv[2]")
                else
                    echo 'No such bookmark' >&2
                    return 1
                end
            else
                begin
                    for file in "$JUMP_DIR"/*
                        read -l contents < "$file"
                        printf "%s\t%s\n" (basename "$file") (__jump_path_from_native "$contents")
                    end
                end | column -t
            end
        case '--prune'
            set -l count 0
            for file in "$JUMP_DIR"/*
                read -l contents < "$file"
                if [ ! -d (__jump_path_from_native "$contents") ]
                    rm "$file"
                    set count (math $count + 1)
                end
            end
            printf 'Pruned %s bookmark(s)' "$count"
        case '--help' ''
            printf 'Jump: Bookmark directories in the terminal\n\n'
            printf 'usage: jump [options] BOOKMARK\n\n'
            printf 'Optional flags:\n'
            printf '  -d    Delete the specified bookmark\n'
            printf '  -c    Create a bookmark with the given name in the current directory\n'
            printf '  -l    List all available bookmarks\n'
            printf '  --prune  Delete any bookmarks that point to non-existant directories.\n'
        case '-?*'
            echo 'Unrecognized option. See "jump --help"'
        case '*'
            if [ (count $argv) -gt 1 ]; then
                printf 'Too many arguments\n' >&2
                return 1
            end

            if [ -e "$JUMP_DIR"/"$argv[1]" ]
                cd (__jump_path_from_native (cat "$JUMP_DIR"/"$argv[1]"))
            else
                printf "No such bookmark."
            end
    end
end

alias j=jump

complete -f -c jump -a '(find "$JUMP_DIR" -type f | awk -F/ \'{print $NF}\')'
complete -c j -w jump
