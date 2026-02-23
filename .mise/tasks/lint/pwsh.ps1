#!/usr/bin/env pwsh
#MISE description="Run PSScriptAnalyzer on chicle.psm1"
#Requires -Version 7.0

$ErrorActionPreference = 'Stop'

$results = Invoke-ScriptAnalyzer -Path chicle.psm1 -Settings PSScriptAnalyzerSettings.psd1 -ReportSummary

if ($results) {
    $results | Format-List
    exit 1
}
