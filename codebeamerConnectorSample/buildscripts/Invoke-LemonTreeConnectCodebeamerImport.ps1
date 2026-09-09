<#
.SYNOPSIS
    Runs a LemonTree Connect Codebeamer import for each exported mapping file.

.DESCRIPTION
    Reads codebeamer-import-metadata.json produced by Export-LemonTreePackageMappings.ps1
    and executes 'LemonTree.Connect.Codebeamer.Automation Import' once per package.
    The import output is written back into the metadata file.

.PARAMETER ModelPath
    Path to the model file that is imported into.

.PARAMETER MappingDirectory
    Directory containing the mapping XML files and the metadata JSON.

.PARAMETER MetadataFilePath
    Optional explicit metadata file path.
    Defaults to codebeamer-import-metadata.json inside the mapping directory.

.PARAMETER ToolPath
    Path to LemonTree.Connect.Codebeamer.Automation.exe. Resolved from ./tools when omitted.

.PARAMETER ServerUrl
    Codebeamer server URL.

.PARAMETER Username
    Codebeamer user name.

.PARAMETER Password
    Codebeamer password.

.PARAMETER LicensePath
    Path to the LemonTree license file.

.PARAMETER TrackerId
    Optional tracker id override. Read from the model metadata when omitted.

.NOTES
    Copyright (c) LieberLieber Software GmbH
    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.

.EXAMPLE
    ./buildscripts/Invoke-LemonTreeConnectCodebeamerImport.ps1 -ModelPath "copy_model.qeax" -MappingDirectory "./.tmp/packagemappings" -ServerUrl $url -Username $user -Password $pw -LicensePath "./.tmp/lta.lic"
#>

param(
    [parameter(Mandatory = $true)]
    [string]$ModelPath,

    [parameter(Mandatory = $true)]
    [string]$MappingDirectory,

    [parameter(Mandatory = $false)]
    [string]$MetadataFilePath,

    [parameter(Mandatory = $false)]
    [string]$ToolPath,

    [parameter(Mandatory = $true)]
    [string]$ServerUrl,

    [parameter(Mandatory = $true)]
    [string]$Username,

    [parameter(Mandatory = $true)]
    [string]$Password,

    [parameter(Mandatory = $true)]
    [string]$LicensePath,

    [parameter(Mandatory = $false)]
    [string]$TrackerId
)

. (Join-Path $PSScriptRoot 'Common.ps1')

if ([string]::IsNullOrWhiteSpace($ToolPath)) {
    $ToolPath = Find-ToolExecutable `
        -SearchRoot (Join-Path (Get-SampleRoot) '.tools\LemonTree.Connect.Codebeamer.Automation') `
        -Executable 'LemonTree.Connect.Codebeamer.Automation.exe'
}

Write-Host "========================================="
Write-Host "Running LemonTree Connect Codebeamer imports..."
Write-Host "========================================="
Write-Host "Model Path: $ModelPath"
Write-Host "Mapping Directory: $MappingDirectory"
Write-Host "Tool Path: $ToolPath"
Write-Host "Server URL: $ServerUrl"
Write-Host "Username: $Username"
Write-Host "License Path: $LicensePath"

if ([string]::IsNullOrWhiteSpace($ToolPath) -or -not (Test-Path -LiteralPath $ToolPath -PathType Leaf)) {
    Write-Error "LemonTree.Connect.Codebeamer.Automation.exe not found. Run ./buildscripts/Install-Tools.ps1 first."
    exit 1
}

if (-not (Test-Path -LiteralPath $ModelPath -PathType Leaf)) {
    Write-Error "Model file not found: $ModelPath"
    exit 1
}

if (-not (Test-Path -LiteralPath $MappingDirectory -PathType Container)) {
    Write-Error "Mapping directory not found: $MappingDirectory"
    exit 1
}

if (-not (Test-Path -LiteralPath $LicensePath -PathType Leaf)) {
    Write-Error "License file not found: $LicensePath"
    exit 1
}

if ([string]::IsNullOrWhiteSpace($Password)) {
    Write-Error "Password must not be empty."
    exit 1
}

if ([string]::IsNullOrWhiteSpace($MetadataFilePath)) {
    $MetadataFilePath = Join-Path $MappingDirectory "codebeamer-import-metadata.json"
}

if (-not (Test-Path -LiteralPath $MetadataFilePath -PathType Leaf)) {
    Write-Error "Metadata file not found: $MetadataFilePath"
    exit 1
}

try {
    $metadataRows = Get-Content -LiteralPath $MetadataFilePath -Raw | ConvertFrom-Json
}
catch {
    Write-Error "Metadata file is not valid JSON: $MetadataFilePath"
    exit 1
}

if ($metadataRows -isnot [System.Array]) {
    $metadataRows = @($metadataRows)
}

if ($metadataRows.Count -eq 0) {
    Write-Error "Metadata file is empty: $MetadataFilePath"
    exit 1
}

function Save-MetadataJson {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][object]$Rows
    )

    $jsonContent = $Rows | ConvertTo-Json -Depth 12
    [System.IO.File]::WriteAllText($Path, $jsonContent, [System.Text.UTF8Encoding]$false)
}

$importedCount = 0

for ($index = 0; $index -lt $metadataRows.Count; $index++) {
    $row = $metadataRows[$index]

    if ([string]::IsNullOrWhiteSpace($row.Guid) -or [string]::IsNullOrWhiteSpace($row.MappingPath)) {
        Write-Error "Invalid metadata entry at index $index. Required properties: Guid, MappingPath"
        exit 1
    }

    $resolvedTrackerId = if (-not [string]::IsNullOrWhiteSpace($TrackerId)) { $TrackerId } else { $row.TrackerId }
    if ([string]::IsNullOrWhiteSpace($resolvedTrackerId)) {
        Write-Error "TrackerId could not be resolved for GUID $($row.Guid)"
        exit 1
    }

    $mappingPath = $row.MappingPath
    if (-not [System.IO.Path]::IsPathRooted($mappingPath)) {
        $candidate = Join-Path (Get-Location).Path $mappingPath
        $mappingPath = if (Test-Path -LiteralPath $candidate -PathType Leaf) { $candidate } else { Join-Path $MappingDirectory (Split-Path -Leaf $mappingPath) }
    }

    if (-not (Test-Path -LiteralPath $mappingPath -PathType Leaf)) {
        Write-Error "Mapping file from metadata not found: $mappingPath"
        exit 1
    }

    $mappingPath = (Resolve-Path -LiteralPath $mappingPath).Path

    Write-Host "Importing mapping: $(Split-Path -Leaf $mappingPath)"
    Write-Host "  Package GUID: $($row.Guid)"
    Write-Host "  Tracker ID: $resolvedTrackerId"

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $importCommandOutput = & $ToolPath Import `
        --Model "$ModelPath" `
        --PackageGuid "$($row.Guid)" `
        --TrackerId "$resolvedTrackerId" `
        --Mapping "$mappingPath" `
        --ServerUrl "$ServerUrl" `
        --Username "$Username" `
        --Password "$Password" `
        --License "$LicensePath" 2>&1
    $importExitCode = $LASTEXITCODE
    $stopwatch.Stop()

    $outputLines = @()
    foreach ($outputLine in $importCommandOutput) {
        $lineText = [string]$outputLine
        Write-Host $lineText
        $outputLines += $lineText
    }

    $importSummary = $null
    foreach ($lineText in $outputLines) {
        if ($lineText -match '^C:(\d+);U:(\d+);D:(\d+)$') {
            $importSummary = [pscustomobject]@{
                Created = [int]$Matches[1]
                Updated = [int]$Matches[2]
                Deleted = [int]$Matches[3]
            }
        }
    }

    $importRun = [pscustomobject]@{
        TimestampUtc    = (Get-Date).ToUniversalTime().ToString('o')
        ExitCode        = $importExitCode
        DurationSeconds = [Math]::Round($stopwatch.Elapsed.TotalSeconds, 2)
        Output          = $outputLines
        Summary         = $importSummary
    }

    $row | Add-Member -NotePropertyName LastImport -NotePropertyValue $importRun -Force

    if ($importExitCode -ne 0) {
        Save-MetadataJson -Path $MetadataFilePath -Rows $metadataRows
        Write-Error "Import failed for GUID $($row.Guid) with exit code $importExitCode"
        exit $importExitCode
    }

    $importedCount++
}

Save-MetadataJson -Path $MetadataFilePath -Rows $metadataRows

Write-Host "Imported $importedCount mapping file(s)."
Write-Host "Updated metadata: $MetadataFilePath"
exit 0
