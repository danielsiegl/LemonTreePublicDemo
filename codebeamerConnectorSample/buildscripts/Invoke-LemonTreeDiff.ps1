<#
.SYNOPSIS
    Generates a LemonTree diff report between two qeax models.

.DESCRIPTION
    Runs 'LemonTree.Automation diff' and writes a diff report, a session file
    and a changes count file.

.PARAMETER BaseModel
    The model to compare against ("theirs").

.PARAMETER HeadModel
    The changed model ("mine").

.PARAMETER LTAExecutable
    Path to LemonTree.Automation.exe. Resolved from ./tools when omitted.

.PARAMETER LicensePath
    Path to the LemonTree license file.

.PARAMETER SessionFile
    Optional path for the LemonTree session file (.ltsfs).

.PARAMETER DiffReportFilename
    Path of the generated XML diff report.

.PARAMETER ChangesCountFile
    File that receives the "Found n different elements" line.

.NOTES
    Copyright (c) LieberLieber Software GmbH
    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.

.EXAMPLE
    ./buildscripts/Invoke-LemonTreeDiff.ps1 -BaseModel "model.qeax" -HeadModel "copy_model.qeax" -LicensePath "./.tmp/lta.lic"
#>

param(
    [parameter(Mandatory = $true)]
    [string]$BaseModel,

    [parameter(Mandatory = $true)]
    [string]$HeadModel,

    [parameter(Mandatory = $false)]
    [string]$LTAExecutable,

    [parameter(Mandatory = $true)]
    [string]$LicensePath,

    [parameter(Mandatory = $false)]
    [string]$SessionFile,

    [parameter(Mandatory = $false)]
    [string]$DiffReportFilename = "./.tmp/DiffReport.xml",

    [parameter(Mandatory = $false)]
    [string]$ChangesCountFile = "./.tmp/changes-count.txt"
)

. (Join-Path $PSScriptRoot 'Common.ps1')

if ([string]::IsNullOrWhiteSpace($LTAExecutable)) {
    $LTAExecutable = Find-ToolExecutable `
        -SearchRoot (Join-Path (Get-SampleRoot) '.tools\LemonTree.Automation') `
        -Executable 'LemonTree.Automation.exe'
}

Write-Host "========================================="
Write-Host "Generating diff report..."
Write-Host "========================================="
Write-Host "Base Model: $BaseModel"
Write-Host "Head Model: $HeadModel"
Write-Host "LTA Executable: $LTAExecutable"

if ([string]::IsNullOrWhiteSpace($LTAExecutable) -or -not (Test-Path -LiteralPath $LTAExecutable -PathType Leaf)) {
    Write-Error "LemonTree.Automation.exe not found. Run ./buildscripts/Install-Tools.ps1 first."
    exit 1
}

if (-not (Test-Path -LiteralPath $BaseModel -PathType Leaf)) {
    Write-Error "Base model not found: $BaseModel"
    exit 1
}

if (-not (Test-Path -LiteralPath $HeadModel -PathType Leaf)) {
    Write-Error "Head model not found: $HeadModel"
    exit 1
}

if (-not (Test-Path -LiteralPath $LicensePath -PathType Leaf)) {
    Write-Error "License file not found: $LicensePath"
    exit 1
}

New-ParentDirectory -Path $DiffReportFilename
New-ParentDirectory -Path $ChangesCountFile
New-ParentDirectory -Path $SessionFile

$diffArgs = @(
    "diff",
    "--theirs", $BaseModel,
    "--mine", $HeadModel,
    "--license", $LicensePath,
    "--DiffReportFilename", $DiffReportFilename,
    "--ReportIncludeDiagrams"
)

if (-not [string]::IsNullOrWhiteSpace($SessionFile)) {
    $diffArgs += @("--sfs", $SessionFile)
}

$output = & $LTAExecutable $diffArgs
$diffExitCode = $LASTEXITCODE
Write-Output $output

if ($diffExitCode -ne 0) {
    Write-Error "Diff command failed with exit code $diffExitCode."
    exit $diffExitCode
}

foreach ($line in $output) {
    if ($line -match 'Found (\d+) different elements') {
        $changesLine = ([string]$line).Trim()
        Write-Host "Found changes: $changesLine"
        $changesLine | Out-File -FilePath $ChangesCountFile -Encoding UTF8
        break
    }
}

Write-Host "Diff report: $DiffReportFilename"
exit 0
