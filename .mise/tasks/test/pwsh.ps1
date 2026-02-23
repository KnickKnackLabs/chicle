#!/usr/bin/env pwsh
#MISE description="Run Pester tests"
#Requires -Version 7.0

$ErrorActionPreference = 'Stop'

Import-Module Pester -MinimumVersion 5.0

$config = New-PesterConfiguration
$config.Run.Path = "test/powershell"
$config.Output.Verbosity = 'Detailed'
$config.Run.Exit = $true

Invoke-Pester -Configuration $config
