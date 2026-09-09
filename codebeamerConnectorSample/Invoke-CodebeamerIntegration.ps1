<#
.SYNOPSIS
    Runs the complete Codebeamer connector demo flow on Windows via PowerShell.

.DESCRIPTION
    This is the PowerShell equivalent of the GitLab CI flow used by the
    lemontree-jama-devops sample, using the Codebeamer connector instead of Jama
    and running natively on Windows instead of a prebuilt Linux Docker image.

    Steps:
      1. Verify the .secrets file (see README.md).
      2. Install the required tools (only downloaded when missing, or with -UpdateTools).
      3. Write the LemonTree license file from the .secrets entry.
      4. Extract the package mappings and Codebeamer metadata from the model.
      5. Copy the model and run the Codebeamer import into the copy.
      6. Diff the original model against the imported copy.

.PARAMETER ModelPath
    Path to the model. Defaults to 'LT.Connect Codebeamer Demo.qeax' in this folder.

.PARAMETER SecretsPath
    Path to the .secrets file. Defaults to '.secrets' in this folder.

.PARAMETER WorkingDirectory
    Directory for all generated artifacts. Defaults to '.tmp' in this folder.

.PARAMETER UpdateTools
    Force a re-download of the tool binaries even if they already exist.

.PARAMETER SkipDiff
    Skip the post-import diff step.

.NOTES
    Copyright (c) LieberLieber Software GmbH
    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.

.EXAMPLE
    .\Invoke-CodebeamerIntegration.ps1
    Runs the full flow against the sample model.

.EXAMPLE
    .\Invoke-CodebeamerIntegration.ps1 -UpdateTools
    Re-downloads the tools and then runs the full flow.
#>

[CmdletBinding()]
param(
    [parameter(Mandatory = $false)]
    [string]$ModelPath,

    [parameter(Mandatory = $false)]
    [string]$SecretsPath,

    [parameter(Mandatory = $false)]
    [string]$WorkingDirectory,

    [parameter(Mandatory = $false)]
    [switch]$UpdateTools,

    [parameter(Mandatory = $false)]
    [switch]$SkipDiff
)

$ErrorActionPreference = 'Stop'

$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$buildScripts = Join-Path $scriptRoot 'buildscripts'

. (Join-Path $buildScripts 'Common.ps1')

if ([string]::IsNullOrWhiteSpace($ModelPath)) { $ModelPath = Get-DefaultModelPath }
if ([string]::IsNullOrWhiteSpace($SecretsPath)) { $SecretsPath = Join-Path $scriptRoot '.secrets' }
if ([string]::IsNullOrWhiteSpace($WorkingDirectory)) { $WorkingDirectory = Join-Path $scriptRoot '.tmp' }

Write-Host "========================================="
Write-Host "Codebeamer connector demo"
Write-Host "========================================="
Write-Host "Model Path: $ModelPath"
Write-Host "Secrets Path: $SecretsPath"
Write-Host "Working Directory: $WorkingDirectory"

if (-not (Test-Path -LiteralPath $ModelPath -PathType Leaf)) {
    Write-Error "Model file not found: $ModelPath"
    exit 1
}

New-Item -ItemType Directory -Path $WorkingDirectory -Force | Out-Null

Write-Host ""
Write-Host "Step 1/5: Checking secrets..."
& (Join-Path $scriptRoot 'Check-Secrets.ps1') -Path $SecretsPath
if ($LASTEXITCODE -ne 0) {
    Write-Error "Secrets check failed."
    exit $LASTEXITCODE
}

$secrets = Read-SecretsFile -Path $SecretsPath

Write-Host ""
Write-Host "Step 2/5: Installing tools..."
& (Join-Path $buildScripts 'Install-Tools.ps1') -UpdateTools:$UpdateTools | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Tool installation failed."
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Step 3/5: Creating license file..."
$licensePath = Join-Path $WorkingDirectory 'lta.lic'
& (Join-Path $buildScripts 'New-LemonTreeLicense.ps1') `
    -LicenseContent $secrets['LieberLieberRLM'] `
    -OutputPath $licensePath | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "License creation failed."
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Step 4/5: Extracting package mappings..."
$mappingDirectory = Join-Path $WorkingDirectory 'packagemappings'
& (Join-Path $buildScripts 'Export-LemonTreePackageMappings.ps1') `
    -ModelPath $ModelPath `
    -OutputDirectory $mappingDirectory
if ($LASTEXITCODE -ne 0) {
    Write-Error "Mapping export failed."
    exit $LASTEXITCODE
}

$metadataFilePath = Join-Path $mappingDirectory 'codebeamer-import-metadata.json'
Write-Host "Metadata file: $metadataFilePath"

Write-Host ""
Write-Host "Step 5/5: Running Codebeamer import..."
$modelCopyPath = Join-Path $WorkingDirectory ("copy_{0}" -f (Split-Path -Leaf $ModelPath))
Copy-Item -LiteralPath $ModelPath -Destination $modelCopyPath -Force
Write-Host "Model copy created: $modelCopyPath"

& (Join-Path $buildScripts 'Invoke-LemonTreeConnectCodebeamerImport.ps1') `
    -ModelPath $modelCopyPath `
    -MappingDirectory $mappingDirectory `
    -MetadataFilePath $metadataFilePath `
    -ServerUrl $secrets['CodebeamerServer'] `
    -Username $secrets['CodebeamerUser'] `
    -Password $secrets['CodebeamerPassword'] `
    -LicensePath $licensePath
if ($LASTEXITCODE -ne 0) {
    Write-Error "Codebeamer import failed."
    exit $LASTEXITCODE
}

if (-not $SkipDiff) {
    Write-Host ""
    Write-Host "Generating post-import diff..."
    & (Join-Path $buildScripts 'Invoke-LemonTreeDiff.ps1') `
        -BaseModel $ModelPath `
        -HeadModel $modelCopyPath `
        -LicensePath $licensePath `
        -SessionFile (Join-Path $WorkingDirectory 'session-codebeamer.ltsfs') `
        -DiffReportFilename (Join-Path $WorkingDirectory 'DiffReport-codebeamer.xml') `
        -ChangesCountFile (Join-Path $WorkingDirectory 'codebeamer-changes-count.txt')
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Post-import diff failed."
        exit $LASTEXITCODE
    }
}

Write-Host ""
Write-Host "Codebeamer integration completed successfully."
Write-Host "Artifacts: $WorkingDirectory"
exit 0
