#!/usr/bin/env pwsh
#MISE description="Install PowerShell modules (Pester, PSScriptAnalyzer)"

$ErrorActionPreference = 'Stop'

Write-Host "Installing Pester..."
Install-Module -Name Pester -MinimumVersion 5.0 -Force -Scope CurrentUser

Write-Host "Installing PSScriptAnalyzer..."
Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser

Write-Host "Done."
