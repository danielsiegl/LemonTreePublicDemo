<#
.SYNOPSIS
    Invokes a SQL query against an EA QEAX model file using sqlite.

.DESCRIPTION
    Runs sqlite against a QEAX model file and returns the raw query output.

.PARAMETER ModelPath
    Path to the SQLite-backed model file (.qeax).
    Defaults to the sample model 'LT.Connect Codebeamer Demo.qeax'.

.PARAMETER SqlQuery
    SQL query to execute.

.PARAMETER SqliteExecutable
    Name or path of the sqlite executable. When omitted the locally installed
    tool from ./tools is used, falling back to 'sqlite3' from PATH.

.NOTES
    Copyright (c) LieberLieber Software GmbH
    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.

.EXAMPLE
    ./buildscripts/Invoke-EAqeaxSqliteQuery.ps1 -SqlQuery "SELECT name FROM sqlite_master;"
    Runs a query against the sample model and outputs resulting rows.
#>

param(
    [parameter(Mandatory = $false)]
    [string]$ModelPath,

    [parameter(Mandatory = $true)]
    [string]$SqlQuery,

    [parameter(Mandatory = $false)]
    [string]$SqliteExecutable
)

. (Join-Path $PSScriptRoot 'Common.ps1')

if ([string]::IsNullOrWhiteSpace($ModelPath)) {
    $ModelPath = Get-DefaultModelPath
}

if ([string]::IsNullOrWhiteSpace($SqliteExecutable)) {
    $localSqlite = Find-ToolExecutable -SearchRoot (Join-Path (Get-SampleRoot) '.tools\sqlite') -Executable 'sqlite3.exe'
    $SqliteExecutable = if ($localSqlite) { $localSqlite } else { 'sqlite3' }
}

if (-not (Test-Path -LiteralPath $ModelPath -PathType Leaf)) {
    Write-Error "Model file not found: $ModelPath"
    exit 1
}

if (-not (Test-Path -LiteralPath $SqliteExecutable -PathType Leaf) -and
    -not (Get-Command -Name $SqliteExecutable -ErrorAction SilentlyContinue)) {
    Write-Error "SQLite executable not found: $SqliteExecutable. Run ./buildscripts/Install-Tools.ps1 first."
    exit 1
}

$output = & $SqliteExecutable "$ModelPath" "$SqlQuery"

if ($LASTEXITCODE -ne 0) {
    Write-Error "SQLite query failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Output $output
exit 0
