<#
.SYNOPSIS
    Shared helper functions for the Codebeamer connector sample scripts.

.DESCRIPTION
    Dot-source this file to get access to the sample's common helpers for locating
    the sample root, resolving tool executables and reading the .secrets file.

.NOTES
    Copyright (c) LieberLieber Software GmbH
    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.
#>

function Get-SampleRoot {
    <#
    .SYNOPSIS
        Returns the root directory of the Codebeamer connector sample.
    #>
    $scriptRoot = $PSScriptRoot
    if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
        $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    }

    return (Split-Path -Parent $scriptRoot)
}

function Get-DefaultModelPath {
    <#
    .SYNOPSIS
        Returns the path of the sample model shipped with this folder.
    #>
    return (Join-Path (Get-SampleRoot) 'LT.Connect Codebeamer Demo.qeax')
}

function New-ParentDirectory {
    <#
    .SYNOPSIS
        Creates the parent directory of the given path when it does not exist.
    #>
    param(
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return
    }

    $parentDirectory = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($parentDirectory) -and -not (Test-Path -LiteralPath $parentDirectory)) {
        New-Item -ItemType Directory -Path $parentDirectory -Force | Out-Null
    }
}

function Find-ToolExecutable {
    <#
    .SYNOPSIS
        Finds an executable below a directory, or $null when it is not present.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$SearchRoot,
        [Parameter(Mandatory = $true)][string]$Executable
    )

    if (-not (Test-Path -LiteralPath $SearchRoot -PathType Container)) {
        return $null
    }

    $match = Get-ChildItem -LiteralPath $SearchRoot -Recurse -File -Filter $Executable -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($null -eq $match) {
        return $null
    }

    return $match.FullName
}

function Read-SecretsFile {
    <#
    .SYNOPSIS
        Reads a .secrets file into a hashtable of Key=Value pairs.

    .DESCRIPTION
        Blank lines and lines starting with '#' are ignored. Values may be quoted.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Secrets file not found: $Path"
    }

    $values = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        $trimmed = $line.Trim()
        if ($trimmed -eq '' -or $trimmed.StartsWith('#')) { continue }

        $separator = $trimmed.IndexOf('=')
        if ($separator -lt 1) { continue }

        $key = $trimmed.Substring(0, $separator).Trim()
        $value = $trimmed.Substring($separator + 1).Trim().Trim('"')
        $values[$key] = $value
    }

    return $values
}

function Get-RequiredSecretKeys {
    <#
    .SYNOPSIS
        Returns the keys that a valid .secrets file has to provide.
    #>
    return @(
        'CodebeamerServer',
        'CodebeamerUser',
        'CodebeamerPassword',
        'LieberLieberRLM'
    )
}
