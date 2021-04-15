# Jump - Bookmark Directories in the Terminal

This is a set of scripts that let you create "bookmarks" of commonly used folders in your shell and instantly navigate
to them with a single, short command. Your bookmarks are persisted to a file on your computer, so bookmarks created in
one shell are instantly available on all other shell instances and even across different shells. This means you can, for
instance, create a bookmark in Bash and load it in Fish or Powershell. On Windows, it also allows you to share bookmarks
between regular Powershell, WSL and Cygwin.

The following environments are supported:

- Bash, Zsh and other `sh`-like shells
  - [Regular (for Linux & Mac)](./sh/regular.sh)
  - [For Cygwin-based environments (MSYS2, Git Bash etc)](./sh/cygwin.sh)
  - [For Windows Subsystem for Linux (WSL)](./sh/wsl.sh)
- Fish
  - [Regular](./fish/regular.fish)
  - [Cygwin](./fish/cygwin.fish)
  - [WSL](./fish/wsl.fish)
- [PowerShell](./powershell/regular.ps1)

## Setup

Clone the scripts into a folder on your computer, e.g.

```sh
git clone https://github.com/morganfogg/jump.git ~/.jumpscripts
```

Then load it from your profile:

#### Bash, Zsh and Fish

Add the following to the bottom of your `~/.bashrc`, `~/.zshrc` or `~/config/fish/config.fish` respectively.

```sh
. ~/.jumpscripts/[jump-script-name]
```

Replacing `[jump-script-name]` with the name of the relevant script for your shell and environment.

#### Powershell

Add this to the bottom of your `$PROFILE`

```powershell
. "$HOME/.jumpscripts/powershell.ps1"
```

If this fails to load, you may need to first update your exection policy to allow script execution.

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Usage

In Bash, Zsh and Fish, Jump is used through the `jump` or `j` command.

```sh
j -c [name]   # Create a new bookmark which points to the working directory
j [name]      # Go to bookmark
j -d [name]   # Delete bookmark
j -l          # List all bookmarks
```

In Powershell, Jump follows the standard Verb-Noun naming convention. The commands are:

| Alias | Full Name       | Effect                                               |
| ----- | --------------- | ---------------------------------------------------- |
| j     | Open-Bookmark   | Go to the bookmark                                   |
| jc    | Add-Bookmark    | Create a new bookmark to working directory           |
| jr    | Remove-Bookmark | Delete a bookmark                                    |
| jg    | Get-Bookmark    | Print all bookmarks, or a given bookmark if provided |

## License

Copyright © 2021 Morgan Fogg

Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
THIS SOFTWARE.
