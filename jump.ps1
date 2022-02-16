# Jump - Bookmark directories in the terminal (PowerShell version)
# https://github.com/morganfogg/jump

if (!(Test-Path "$HOME/jumppoints")) {
    New-Item -Path $HOME -Name "jumppoints" -Type Directory
}

function Open-Bookmark {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    process {
        try {
            if (!(Test-Path "$HOME/jumppoints/$Name")) {
                throw [Exception]::new("No such bookmark exists");
            }

            Set-Location $(Get-Content "$HOME/jumppoints/$Name")
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_);
        }
    }
}

function Remove-Bookmark {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    process {
        try {
            if (!(Test-Path "$HOME/jumppoints/$Name")) {
                throw [Exception]::new("No such bookmark to remove");
            }

            Remove-Item "$HOME/jumppoints/$Name"
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_);
        }
    }
}

function Get-Bookmark {
    [CmdletBinding()]
    param (
        [string] $Name
    )

    process {
        try {
            if (![string]::IsNullOrWhiteSpace($Name)) {
                if (!(Test-Path "$HOME/jumppoints/$Name")) {
                    throw [Exception]::new("No such bookmark.");
                }

                $data = [PSCustomObject]@{
                    Name     =$Name;
                    Location =$(Get-Content "$HOME/jumppoints/$Name");
                }
            }
            else {
                $data = Get-ChildItem -Path "$HOME/jumppoints" | ForEach-Object {
                    [PSCustomObject]@{
                        Name     =$_.BaseName;
                        Location =$(Get-Content $_);
                    }
                }
            }

            return $data;
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_);
        }
    }
}

function Update-Bookmark {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    process {
        try {
            if (!(Test-Path "$HOME/jumppoints/$Name")) {
                throw [Exception]::new("No such bookmark to update");
            }

            Get-Location | Out-File "$HOME/jumppoints/$Name"
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_);
        }
    }
}

function Add-Bookmark {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    process {
        try {
            if (Test-Path "$HOME/jumppoints/$Name") {
                throw [Exception]::new("Bookmark already exists");
            }

            Get-Location | Out-File "$HOME/jumppoints/$Name"

            Write-Host ("Created bookmark '$Name' to folder '$(Get-Location)'");
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_);
        }
    }
}

$bookmarkCompleter = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

  (Get-Bookmark).Name | Where-Object { $_ -like "$wordToComplete*" }
}

Register-ArgumentCompleter -CommandName Open-Bookmark -ParameterName Name -ScriptBlock $bookmarkCompleter;
Register-ArgumentCompleter -CommandName Remove-Bookmark -ParameterName Name -ScriptBlock $bookmarkCompleter;
Register-ArgumentCompleter -CommandName Get-Bookmark -ParameterName Name -ScriptBlock $bookmarkCompleter;
Register-ArgumentCompleter -CommandName Update-Bookmark -ParameterName Name -ScriptBlock $bookmarkCompleter;

Set-Alias j Open-Bookmark;
Set-Alias jr Remove-Bookmark;
Set-Alias jg Get-Bookmark;
Set-Alias jc Add-Bookmark;
Set-Alias ju Update-Bookmark

