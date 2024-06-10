# Jump - Bookmark Directories in the Terminal

This is a set of scripts that let you create "bookmarks" of commonly used folders in your shell and instantly navigate
to them with a single, short command. Your bookmarks are persisted to a file on your computer, so bookmarks created in
one shell are instantly available on all other shell instances and even across different shells. This means you can, for
instance, create a bookmark in Bash and load it in Fish or Powershell. On Windows, it also allows you to share bookmarks
between regular Powershell, WSL and Cygwin.

The following environments are supported:

- [Bash, Zsh and other `sh`-like shells](./jump.sh)
- [Fish](./jump.fish)
- [PowerShell](./jump.ps1)

## Setup

Clone the scripts into a folder on your computer, e.g.

```sh
git clone https://github.com/morganfogg/jump.git ~/.jumpscripts
```

Then load it from your profile:

#### Bash and Zsh

Add the following to the bottom of your `~/.bashrc` or `~/.zshrc`.

```sh
. ~/.jumpscripts/jump.sh
```

#### Fish

Add to the bottom of your `~/config/fish/config.fish`

```fish
source ~/.jumpscripts/jump.fish
```

#### PowerShell

Add this to the bottom of your `$PROFILE`

```powershell
. "$HOME/.jumpscripts/jump.ps1"
```

If this fails to load, you may need to first update your exection policy to allow script execution.

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Usage

In Bash, Zsh and Fish, Jump is used through the `jump` or `j` command.

```sh
j -c [name]   # Add a new bookmark which points to the working directory
j [name]      # Go to bookmark
j -r [name]   # Delete bookmark
j -g          # List all bookmarks, or print a bookmark's path if a name is provided
j --prune     # Delete any bookmark which no longer points to a valid location on the filesystem.
```

In Powershell, Jump follows the standard Verb-Noun naming convention. The commands are:

| Alias | Full Name          | Effect                                                         |
| ----- | ------------------ | -------------------------------------------------------------- |
| j     | Open-Bookmark      | Go to the bookmark                                             |
| jc    | Add-Bookmark       | Create a new bookmark to working directory                     |
| jr    | Remove-Bookmark    | Delete a bookmark                                              |
| jg    | Get-Bookmark       | Print all bookmarks, or a given bookmark if provided           |
| ju    | Update-Bookmark    | Updates an existing bookmark to point to the working directory |

## License

Copyright © 2021 Morgan Fogg

Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
THIS SOFTWARE.
