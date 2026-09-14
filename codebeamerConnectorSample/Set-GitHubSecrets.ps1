<#
.SYNOPSIS
    Sets GitHub Actions secrets from this sample's .secrets file.

.DESCRIPTION
    Reads the local Codebeamer connector .secrets file and uploads the values to
    GitHub repository secrets with the names expected by the PR workflow.
    Secret values are passed to the GitHub CLI through standard input and are not
    printed by this script.

.PARAMETER SecretsPath
    Path to the local .secrets file. Defaults to .secrets next to this script.

.PARAMETER Repository
    GitHub repository in owner/name format. When omitted, the origin remote is used.

.EXAMPLE
    .\Set-GitHubSecrets.ps1 -Repository danielsiegl/LemonTreePublicDemo

.EXAMPLE
    .\Set-GitHubSecrets.ps1 -WhatIf
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [string]$SecretsPath,

    [Parameter(Mandatory = $false)]
    [string]$Repository
)

$ErrorActionPreference = 'Stop'

$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$buildScripts = Join-Path $scriptRoot 'buildscripts'

. (Join-Path $buildScripts 'Common.ps1')

function Get-GitHubRepositoryFromOrigin {
    $originUrl = (& git remote get-url origin 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($originUrl)) {
        throw "Could not read git origin remote. Pass -Repository owner/name."
    }

    $trimmed = $originUrl.Trim()
    if ($trimmed -match 'github\.com[:/](?<repo>[^/]+/[^/]+?)(?:\.git)?$') {
        return $Matches['repo']
    }

    throw "Could not infer GitHub repository from origin remote '$trimmed'. Pass -Repository owner/name."
}

function Get-NormalizedSecretValue {
    param(
        [Parameter(Mandatory = $true)][string]$LocalKey,
        [Parameter(Mandatory = $true)][string]$Value
    )

    $normalized = $Value.Trim()
    $keyPrefix = "$LocalKey="
    if ($normalized.StartsWith($keyPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Warning "Value for '$LocalKey' includes a leading '$keyPrefix' prefix. Uploading only the value after the prefix."
        $normalized = $normalized.Substring($keyPrefix.Length).Trim()
    }

    return $normalized
}

if ([string]::IsNullOrWhiteSpace($SecretsPath)) {
    $SecretsPath = Join-Path $scriptRoot '.secrets'
}

if ([string]::IsNullOrWhiteSpace($Repository)) {
    $Repository = Get-GitHubRepositoryFromOrigin
}

if ($Repository -notmatch '^[^/]+/[^/]+$') {
    throw "Repository must be in owner/name format. Value: $Repository"
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "GitHub CLI 'gh' was not found on PATH. Install it and run 'gh auth login' first."
}

$secrets = Read-SecretsFile -Path $SecretsPath
$secretMappings = [ordered]@{
    CodebeamerServer   = 'CODEBEAMER_SERVER'
    CodebeamerUser     = 'CODEBEAMER_USER'
    CodebeamerPassword = 'CODEBEAMER_PASSWORD'
    LieberLieberRLM    = 'LEMONTREE_LICENSE'
    NexusAuthentication = 'NEXUSAUTHENTICATION'
}

$missing = @($secretMappings.Keys | Where-Object { [string]::IsNullOrWhiteSpace($secrets[$_]) })
if ($missing.Count -gt 0) {
    throw "The file '$SecretsPath' is missing a value for: $($missing -join ', ')."
}

foreach ($localKey in $secretMappings.Keys) {
    $githubSecretName = $secretMappings[$localKey]
    $secretValue = Get-NormalizedSecretValue -LocalKey $localKey -Value $secrets[$localKey]
    if ($PSCmdlet.ShouldProcess("$Repository/$githubSecretName", "set GitHub Actions secret from '$localKey'")) {
        $secretValue | & gh secret set $githubSecretName --repo $Repository
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to set GitHub secret '$githubSecretName'. Check 'gh auth status' and repository permissions."
        }
    }
}

Write-Host "GitHub Actions secrets are configured for $Repository."
exit 0