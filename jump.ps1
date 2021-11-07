# Jump - Bookmark directories in the terminal (PowerShell version)
# https://github.com/morganfogg/jump

if (!(Test-Path "$HOME/jump.tsv")) {
  New-Item -Path $HOME -Name "jump.tsv" -Type "file" -Value "Name`tPath"
}

function Open-Bookmark {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [string] $Name
  )

  process {
    try {
      $result = @(Import-Csv -Header 'Name', 'Path' -Delimiter "`t" "$HOME/jump.tsv") | Where-Object -Property "Name" -Like $Name;
      if ($result.Count -eq 0) {
        throw [Exception]::new("No such bookmark exists");
      }

      Set-Location $result[0].Path;
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
      $oldData = @(Import-Csv -Header 'Name', 'Path' -Delimiter "`t" "$HOME/jump.tsv");
      $newData = $oldData | Where-Object -Property "Name" -NotLike $Name;

      if ($oldData.length -eq $newData.length) {
        throw [Exception]::new("No such bookmark to remove");
      }

      $newData | Select-Object "Name", "Path" | ConvertTo-Csv -Delimiter "`t" -UseQuotes Never | Select-Object -skip 1 | Set-Content "$HOME/jump.tsv"
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
      $data = @(Import-Csv -Header 'Name', 'Path' -Delimiter "`t" "$HOME/jump.tsv");

      if (![string]::IsNullOrWhiteSpace($name)) {
        $data = $data | Where-Object -Property "Name" -Like $Name;
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
      $data = @(Import-Csv -Header 'Name', 'Path' -Delimiter "`t" "$HOME/jump.tsv");
      $results = $data | Where-Object -Property "Name" -Like $Name;
      if ($results.length -eq 0) {
        throw [Exception]::new("No such bookmark to update");
      }
      $results[0].Path = Get-Location;
      $data | Select-Object "Name", "Path" | ConvertTo-Csv -Delimiter "`t" -UseQuotes Never | Select-Object -skip 1 | Set-Content "$HOME/jump.tsv"
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
      $data = @(Import-Csv -Header 'Name', 'Path' -Delimiter "`t" "$HOME/jump.tsv");
      $results = $data | Where-Object -Property "Name" -Like $Name;
      if ($results.length -ne 0) {
        throw [Exception]::new("A bookmark with that name already exists");
      }

      $data += New-Object PsObject -Property @{
        Name = $name
        Path = Get-Location
      };

      Write-Host ("Created bookmark '$Name' to folder '$(Get-Location)'");

      $data | Select-Object "Name", "Path" | ConvertTo-Csv -Delimiter "`t" -UseQuotes Never | Select-Object -skip 1 | Set-Content "$HOME/jump.tsv"
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
