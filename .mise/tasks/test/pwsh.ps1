#!/usr/bin/env pwsh
#MISE description="Run Pester tests"
#Requires -Version 7.0

$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name Pester | Where-Object Version -ge '5.0')) {
    Write-Error "Pester 5+ not found. Run: mise run setup"
    exit 1
}

Import-Module Pester -MinimumVersion 5.0

$config = New-PesterConfiguration
$config.Run.Path = "test/powershell"
$config.Output.Verbosity = 'Detailed'
$config.Run.Exit = $true

Invoke-Pester -Configuration $config
