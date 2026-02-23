#!/usr/bin/env pwsh
#MISE description="Run PSScriptAnalyzer on chicle.psm1"
#Requires -Version 7.0

$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Write-Error "PSScriptAnalyzer not found. Run: mise run setup"
    exit 1
}

$results = Invoke-ScriptAnalyzer -Path chicle.psm1 -Settings PSScriptAnalyzerSettings.psd1 -ReportSummary

if ($results) {
    $results | Format-List
    exit 1
}
