<#
.SYNOPSIS
    Converts a LemonTree XML diff report to Markdown.

.DESCRIPTION
    Applies the Markdown XSLT transformer from the ReportTransformers folder to
    a LemonTree.Automation diff report. This script only transforms an existing
    report; it does not run LemonTree.Automation itself.

.PARAMETER InputPath
    Path to the LemonTree XML diff report.

.PARAMETER StylesheetPath
    Path to the XSLT stylesheet that produces Markdown.

.PARAMETER OutputPath
    Path to the Markdown file to write.

.EXAMPLE
    .\buildscripts\Convert-LemonTreeDiffReportToMarkdown.ps1 `
        -InputPath .\.tmp\DiffReport-codebeamer.xml `
        -StylesheetPath .\ReportTransformers\LemonTreeDiffDashboardMarkdown.xsl `
        -OutputPath .\.tmp\DiffReport-codebeamer.md
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter(Mandatory = $true)]
    [string]$StylesheetPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'Common.ps1')

if (-not (Test-Path -LiteralPath $InputPath -PathType Leaf)) {
    throw "Input report not found: $InputPath"
}

if (-not (Test-Path -LiteralPath $StylesheetPath -PathType Leaf)) {
    throw "XSLT stylesheet not found: $StylesheetPath"
}

New-ParentDirectory -Path $OutputPath

$transform = New-Object System.Xml.Xsl.XslCompiledTransform
$settings = New-Object System.Xml.Xsl.XsltSettings($false, $false)
$resolver = $null
$reader = $null
$writer = $null

try {
    $transform.Load($StylesheetPath, $settings, $resolver)
    $reader = [System.Xml.XmlReader]::Create($InputPath)
    $writer = [System.Xml.XmlWriter]::Create($OutputPath, $transform.OutputSettings)
    $transform.Transform($reader, $null, $writer, $resolver)
}
finally {
    if ($null -ne $reader) { $reader.Dispose() }
    if ($null -ne $writer) { $writer.Dispose() }
}

Write-Host "Markdown report: $OutputPath"
exit 0