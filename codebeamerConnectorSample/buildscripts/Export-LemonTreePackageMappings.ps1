<#
.SYNOPSIS
    Exports the Codebeamer package mapping XML files stored inside a model.

.DESCRIPTION
    Reads the LemonTree Connect configuration of every package that is configured
    for import (direction = ToEa), writes one mapping XML per package and persists
    the Codebeamer metadata (projectId, trackerId) into codebeamer-import-metadata.json.

.PARAMETER ModelPath
    Path to the source model file (.qeax).
    Defaults to the sample model 'LT.Connect Codebeamer Demo.qeax'.

.PARAMETER OutputDirectory
    Directory the mapping files and the metadata JSON are written to.

.PARAMETER PackageGuids
    Optional explicit list of package GUIDs. Resolved from the model when omitted.

.PARAMETER QueryScriptPath
    Path to the SQLite query wrapper script.

.PARAMETER GetGuidsScriptPath
    Path to the Get-LemonTreeImportPackageGuids script.

.NOTES
    Copyright (c) LieberLieber Software GmbH
    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.

.EXAMPLE
    ./buildscripts/Export-LemonTreePackageMappings.ps1
    Exports mapping XML for all import package GUIDs of the sample model.
#>

param(
    [parameter(Mandatory = $false)]
    [string]$ModelPath,

    [parameter(Mandatory = $false)]
    [string]$OutputDirectory = "./.tmp/packagemappings",

    [parameter(Mandatory = $false)]
    [string[]]$PackageGuids,

    [parameter(Mandatory = $false)]
    [string]$QueryScriptPath,

    [parameter(Mandatory = $false)]
    [string]$GetGuidsScriptPath
)

. (Join-Path $PSScriptRoot 'Common.ps1')

if ([string]::IsNullOrWhiteSpace($ModelPath)) {
    $ModelPath = Get-DefaultModelPath
}

if ([string]::IsNullOrWhiteSpace($QueryScriptPath)) {
    $QueryScriptPath = Join-Path $PSScriptRoot 'Invoke-EAqeaxSqliteQuery.ps1'
}

if ([string]::IsNullOrWhiteSpace($GetGuidsScriptPath)) {
    $GetGuidsScriptPath = Join-Path $PSScriptRoot 'Get-LemonTreeImportPackageGuids.ps1'
}

function Get-PackagePropertyValue {
    param(
        [Parameter(Mandatory = $true)][string]$ModelPath,
        [Parameter(Mandatory = $true)][string]$PackageGuid,
        [Parameter(Mandatory = $true)][string]$PropertyName,
        [Parameter(Mandatory = $true)][string]$QueryScriptPath
    )

    $propertyQuery = "select [value] from t_objectproperties where property = '$PropertyName' and object_id in (select object_id from t_object where ea_guid = '$PackageGuid')"
    $propertyResult = & $QueryScriptPath -ModelPath $ModelPath -SqlQuery $propertyQuery

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Query failed while reading '$PropertyName' for package GUID $PackageGuid"
        exit $LASTEXITCODE
    }

    $value = ($propertyResult | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Last 1)
    if ($null -eq $value) {
        return $null
    }

    return $value.Trim()
}

function Get-PackageName {
    param(
        [Parameter(Mandatory = $true)][string]$ModelPath,
        [Parameter(Mandatory = $true)][string]$PackageGuid,
        [Parameter(Mandatory = $true)][string]$QueryScriptPath
    )

    $nameQuery = "select Name from t_object where ea_guid = '$PackageGuid'"
    $nameResult = & $QueryScriptPath -ModelPath $ModelPath -SqlQuery $nameQuery

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Query failed while reading package name for GUID $PackageGuid"
        exit $LASTEXITCODE
    }

    $packageName = ($nameResult | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Last 1)
    if ($null -eq $packageName) {
        return $null
    }

    return $packageName.Trim()
}

Write-Host "========================================="
Write-Host "Exporting package mapping XML files..."
Write-Host "========================================="
Write-Host "Model Path: $ModelPath"
Write-Host "Output Directory: $OutputDirectory"

if (-not (Test-Path -LiteralPath $ModelPath -PathType Leaf)) {
    Write-Error "Model file not found: $ModelPath"
    exit 1
}

if (-not (Test-Path -LiteralPath $QueryScriptPath -PathType Leaf)) {
    Write-Error "Query script not found: $QueryScriptPath"
    exit 1
}

if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

$resolvedGuids = @()
if ($PackageGuids -and $PackageGuids.Count -gt 0) {
    $resolvedGuids = $PackageGuids
    Write-Host "Using provided package GUIDs: $($resolvedGuids.Count)"
}
else {
    if (-not (Test-Path -LiteralPath $GetGuidsScriptPath -PathType Leaf)) {
        Write-Error "GUID script not found: $GetGuidsScriptPath"
        exit 1
    }

    Write-Host "Resolving package GUIDs from model..."
    $guidResult = & $GetGuidsScriptPath -ModelPath $ModelPath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to resolve package GUIDs."
        exit $LASTEXITCODE
    }

    foreach ($line in $guidResult) {
        if (-not [string]::IsNullOrWhiteSpace($line) -and $line.Trim().StartsWith("{")) {
            $resolvedGuids += $line.Trim()
        }
    }
}

if ($resolvedGuids.Count -eq 0) {
    Write-Host "No package GUIDs available."
    exit 0
}

$metadataRows = @()

foreach ($packageGuid in $resolvedGuids) {
    $guid = $packageGuid.Trim()
    Write-Host "Processing GUID: $guid"

    $query = "select notes from t_objectproperties where property = 'configuration' and object_id in (select object_id from t_object where ea_guid = '$guid')"
    $mappingXml = & $QueryScriptPath -ModelPath $ModelPath -SqlQuery $query

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Query failed for GUID $guid"
        exit $LASTEXITCODE
    }

    $xmlContent = ($mappingXml -join [Environment]::NewLine)

    if ([string]::IsNullOrWhiteSpace($xmlContent)) {
        Write-Warning "No mapping XML found for GUID $guid"
        continue
    }

    $safeGuid = ($guid -replace '[{}]', '') -replace '[^A-Za-z0-9_-]', '_'
    $outputFile = Join-Path $OutputDirectory ("packagemapping_{0}.xml" -f $safeGuid)

    [System.IO.File]::WriteAllText($outputFile, $xmlContent, [System.Text.UTF8Encoding]$false)

    $mappingPath = (Resolve-Path -LiteralPath $outputFile).Path

    $projectId = Get-PackagePropertyValue -ModelPath $ModelPath -PackageGuid $guid -PropertyName 'projectId' -QueryScriptPath $QueryScriptPath
    $trackerId = Get-PackagePropertyValue -ModelPath $ModelPath -PackageGuid $guid -PropertyName 'trackerId' -QueryScriptPath $QueryScriptPath
    $packageName = Get-PackageName -ModelPath $ModelPath -PackageGuid $guid -QueryScriptPath $QueryScriptPath

    if ([string]::IsNullOrWhiteSpace($trackerId)) {
        Write-Error "trackerId could not be resolved for GUID $guid"
        exit 1
    }

    $metadataRows += [pscustomobject]@{
        Guid        = $guid
        PackageName = $packageName
        ProjectId   = $projectId
        TrackerId   = $trackerId
        MappingPath = $mappingPath
    }

    Write-Host "  Package: $packageName (projectId=$projectId, trackerId=$trackerId)"
}

if ($metadataRows.Count -eq 0) {
    Write-Error "No mapping files were exported."
    exit 1
}

$metadataFilePath = Join-Path $OutputDirectory "codebeamer-import-metadata.json"
$jsonContent = $metadataRows | ConvertTo-Json -Depth 12
[System.IO.File]::WriteAllText($metadataFilePath, $jsonContent, [System.Text.UTF8Encoding]$false)

Write-Host "Exported $($metadataRows.Count) mapping file(s)."
Write-Host "Metadata file: $metadataFilePath"
exit 0
