#!/usr/bin/env pwsh
#Requires -Version 7.0
# chicle PowerShell test runner
# Runs Pester tests. Install Pester: Install-Module Pester -Force

$ErrorActionPreference = 'Stop'

# Check for Pester
if (-not (Get-Module -ListAvailable -Name Pester | Where-Object Version -ge '5.0')) {
    Write-Error "Pester 5+ not found. Install it: Install-Module Pester -MinimumVersion 5.0 -Force"
    exit 1
}

Import-Module Pester -MinimumVersion 5.0

$config = New-PesterConfiguration
$config.Run.Path = "$PSScriptRoot/test/powershell"
$config.Output.Verbosity = 'Detailed'
$config.Run.Exit = $true

Invoke-Pester -Configuration $config
