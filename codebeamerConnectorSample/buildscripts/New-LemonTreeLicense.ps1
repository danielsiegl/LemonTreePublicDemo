<#
.SYNOPSIS
    Creates and verifies a LemonTree license file from a license string.

.DESCRIPTION
    Writes the license string to a file, replacing pipe delimiters with spaces.
    Verifies that the license file has sufficient content before returning the path.
    Note: The file must not be BOM encoded, otherwise the tools fail with an
    error about an invalid license.

.PARAMETER LicenseContent
    The license content string. Falls back to $env:LEMONTREE_LICENSE.

.PARAMETER OutputPath
    The output file path for the license file. Defaults to "./.tmp/lta.lic".

.PARAMETER MinimumSize
    Minimum file size in bytes to consider valid. Defaults to 10 bytes.

.OUTPUTS
    Returns the full path to the created license file.

.NOTES
    Copyright (c) LieberLieber Software GmbH
    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.

.EXAMPLE
    $licensePath = ./buildscripts/New-LemonTreeLicense.ps1 -LicenseContent $licenseString
    Creates the license file and returns its path.
#>

param(
    [parameter(Mandatory = $false)]
    [string]$LicenseContent = $env:LEMONTREE_LICENSE,

    [parameter(Mandatory = $false)]
    [string]$OutputPath = "./.tmp/lta.lic",

    [parameter(Mandatory = $false)]
    [int]$MinimumSize = 10
)

. (Join-Path $PSScriptRoot 'Common.ps1')

if ([string]::IsNullOrWhiteSpace($LicenseContent)) {
    Write-Error "License content is empty. Provide -LicenseContent or set LEMONTREE_LICENSE."
    exit 1
}

$resolvedOutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
New-ParentDirectory -Path $resolvedOutputPath

# The tools reject licenses with newlines, so pipes act as space placeholders.
$licenseProcessed = $LicenseContent.Trim()
if ($licenseProcessed.StartsWith('LieberLieberRLM=', [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Warning "License content includes a leading 'LieberLieberRLM=' prefix. Writing only the value after the prefix."
    $licenseProcessed = $licenseProcessed.Substring('LieberLieberRLM='.Length).Trim()
}
$licenseProcessed = $licenseProcessed -replace '\|', ' '
[System.IO.File]::WriteAllText($resolvedOutputPath, $licenseProcessed, [System.Text.UTF8Encoding]::new($false))

if (-not (Test-Path -LiteralPath $resolvedOutputPath)) {
    Write-Error "Failed to create license file: $resolvedOutputPath"
    exit 1
}

$fileSize = (Get-Item -LiteralPath $resolvedOutputPath).Length
if ($fileSize -lt $MinimumSize) {
    Write-Error "License file is too small ($fileSize bytes). License may not have been written correctly."
    exit 1
}

Write-Host "License file verified ($fileSize bytes)"

return (Get-Item -LiteralPath $resolvedOutputPath).FullName
