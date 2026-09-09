<#
.SYNOPSIS
    Downloads the Windows binaries required by the Codebeamer connector sample.

.DESCRIPTION
    Downloads and extracts LemonTree.Automation, LemonTree.Connect.Codebeamer.Automation
    and the SQLite command line tool into a local tools directory.

    Binaries are only downloaded when they are missing. Pass -UpdateTools to force a
    re-download of everything, even if it is already present.

.PARAMETER ToolsDirectory
    Directory the tools are installed into. Defaults to '<sample>/.tools'.

.PARAMETER UpdateTools
    Force a re-download even if the binaries already exist.

.NOTES
    Copyright (c) LieberLieber Software GmbH
    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.

.EXAMPLE
    ./buildscripts/Install-Tools.ps1
    Downloads only the tools that are not installed yet.

.EXAMPLE
    ./buildscripts/Install-Tools.ps1 -UpdateTools
    Re-downloads all tools.
#>

[CmdletBinding()]
param(
    [parameter(Mandatory = $false)]
    [string]$ToolsDirectory,

    [parameter(Mandatory = $false)]
    [switch]$UpdateTools
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'Common.ps1')

if ([string]::IsNullOrWhiteSpace($ToolsDirectory)) {
    $ToolsDirectory = Join-Path (Get-SampleRoot) '.tools'
}

$tools = @(
    [pscustomobject]@{
        Name       = 'LemonTree.Automation'
        Url        = 'https://nexus.lieberlieber.com/repository/lemontree-release/LemonTree.Automation/LemonTree.Automation.Zip_Deploy.zip'
        Directory  = 'LemonTree.Automation'
        Executable = 'LemonTree.Automation.exe'
    },
    [pscustomobject]@{
        Name       = 'LemonTree.Connect.Codebeamer.Automation'
        Url        = 'https://nexus.lieberlieber.com/repository/lemontree-release/LemonTree.Automation/LemonTree.Connect.Automation.Codebeamer.Windows_latest.zip'
        Directory  = 'LemonTree.Connect.Codebeamer.Automation'
        Executable = 'LemonTree.Connect.Codebeamer.Automation.exe'
    },
    [pscustomobject]@{
        Name       = 'SQLite'
        Url        = 'https://www.sqlite.org/2024/sqlite-tools-win-x64-3460100.zip'
        Directory  = 'sqlite'
        Executable = 'sqlite3.exe'
    }
)

function Install-Tool {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$TargetDirectory,
        [Parameter(Mandatory = $true)][string]$Executable,
        [Parameter(Mandatory = $true)][bool]$Force
    )

    $existing = Find-ToolExecutable -SearchRoot $TargetDirectory -Executable $Executable

    if ($existing -and -not $Force) {
        Write-Host "$Name already installed: $existing"
        return $existing
    }

    if ($Force -and (Test-Path -LiteralPath $TargetDirectory)) {
        Remove-Item -LiteralPath $TargetDirectory -Recurse -Force
    }

    New-Item -ItemType Directory -Path $TargetDirectory -Force | Out-Null

    $archivePath = Join-Path ([System.IO.Path]::GetTempPath()) ("{0}-{1}.zip" -f $Name, [Guid]::NewGuid())

    Write-Host "Downloading $Name..."
    Write-Host "  $Url"

    $previousProgress = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try {
        Invoke-WebRequest -Uri $Url -OutFile $archivePath -UseBasicParsing
    }
    finally {
        $ProgressPreference = $previousProgress
    }

    try {
        Expand-Archive -LiteralPath $archivePath -DestinationPath $TargetDirectory -Force
    }
    finally {
        Remove-Item -LiteralPath $archivePath -Force -ErrorAction SilentlyContinue
    }

    $installed = Find-ToolExecutable -SearchRoot $TargetDirectory -Executable $Executable
    if (-not $installed) {
        Write-Error "$Executable was not found after extracting $Name to $TargetDirectory"
        exit 1
    }

    Write-Host "$Name installed: $installed"
    return $installed
}

Write-Host "========================================="
Write-Host "Installing tools..."
Write-Host "========================================="
Write-Host "Tools Directory: $ToolsDirectory"
Write-Host "Update Tools: $($UpdateTools.IsPresent)"

New-Item -ItemType Directory -Path $ToolsDirectory -Force | Out-Null

$result = [ordered]@{}
foreach ($tool in $tools) {
    $result[$tool.Name] = Install-Tool `
        -Name $tool.Name `
        -Url $tool.Url `
        -TargetDirectory (Join-Path $ToolsDirectory $tool.Directory) `
        -Executable $tool.Executable `
        -Force ([bool]$UpdateTools)
}

Write-Host "All tools are available."
[pscustomobject]$result
