<#
.SYNOPSIS
    Checks that a .secrets file exists in this folder and contains all required settings.

.DESCRIPTION
    The .secrets file must provide the Codebeamer server URL, the Codebeamer user name,
    the Codebeamer password and the LemonTree Connect Automation Codebeamer license string.
    See README.md for the expected format.

.PARAMETER Path
    Path to the .secrets file. Defaults to '.secrets' next to this script.

.EXAMPLE
    .\Check-Secrets.ps1

.EXAMPLE
    .\Check-Secrets.ps1 -Path 'C:\temp\.secrets'
#>
[CmdletBinding()]
param(
    [string]$Path
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Path)) {
    $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
    if ([string]::IsNullOrWhiteSpace($scriptRoot)) { $scriptRoot = (Get-Location).Path }
    $Path = Join-Path $scriptRoot '.secrets'
}

$requiredKeys = @(
    'CodebeamerServer',
    'CodebeamerUser',
    'CodebeamerPassword',
    'LieberLieberRLM'
)

if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    $template = $requiredKeys | ForEach-Object { "$_=" }
    Set-Content -LiteralPath $Path -Value $template
    Write-Warning "No .secrets file found at '$Path'. Created a template; add the required values (see README.md)."
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

$missing = $requiredKeys | Where-Object { [string]::IsNullOrWhiteSpace($values[$_]) }

if ($missing) {
    Write-Error "The file '$Path' is missing a value for: $($missing -join ', '). See README.md."
    exit 1
}

Write-Host "OK: '$Path' exists and contains all required entries:" -ForegroundColor Green
foreach ($key in $requiredKeys) {
    Write-Host " - $key"
}
exit 0
