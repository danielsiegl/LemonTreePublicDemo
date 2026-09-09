<#
.SYNOPSIS
    Retrieves import package GUIDs from a LemonTree model file.

.DESCRIPTION
    Queries the SQLite database embedded in a LemonTree model (.qeax) and
    returns GUIDs of packages configured for import to Enterprise Architect
    where direction is set to "ToEa".

.PARAMETER ModelPath
    Path to the LemonTree model file (.qeax).
    Defaults to the sample model 'LT.Connect Codebeamer Demo.qeax'.

.PARAMETER QueryScriptPath
    Path to the SQLite query wrapper script.
    Defaults to the sibling script Invoke-EAqeaxSqliteQuery.ps1.

.NOTES
    Copyright (c) LieberLieber Software GmbH
    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.

.EXAMPLE
    ./buildscripts/Get-LemonTreeImportPackageGuids.ps1
    Returns all import package GUIDs from the sample model.
#>

param(
    [parameter(Mandatory = $false)]
    [string]$ModelPath,

    [parameter(Mandatory = $false)]
    [string]$QueryScriptPath
)

. (Join-Path $PSScriptRoot 'Common.ps1')

if ([string]::IsNullOrWhiteSpace($ModelPath)) {
    $ModelPath = Get-DefaultModelPath
}

if ([string]::IsNullOrWhiteSpace($QueryScriptPath)) {
    $QueryScriptPath = Join-Path $PSScriptRoot 'Invoke-EAqeaxSqliteQuery.ps1'
}

if (-not (Test-Path -LiteralPath $ModelPath -PathType Leaf)) {
    Write-Error "Model file not found: $ModelPath"
    exit 1
}

if (-not (Test-Path -LiteralPath $QueryScriptPath -PathType Leaf)) {
    Write-Error "Query script not found: $QueryScriptPath"
    exit 1
}

$query = @"
select ea_guid as importPackageGuids from t_object
where object_id in (select object_id from t_objectproperties where property = 'direction' and [value] = 'ToEa')
"@

$result = & $QueryScriptPath -ModelPath $ModelPath -SqlQuery $query
if ($LASTEXITCODE -ne 0) {
    Write-Error "Query script failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

$guids = @()
foreach ($line in $result) {
    if (-not [string]::IsNullOrWhiteSpace($line)) {
        $guids += $line.Trim()
    }
}

if ($guids.Count -eq 0) {
    Write-Host "No import package GUIDs found."
    exit 0
}

Write-Output $guids
exit 0
