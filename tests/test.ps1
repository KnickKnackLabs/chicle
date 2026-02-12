#!/usr/bin/env pwsh
# chicle PowerShell test suite
# Requires: PowerShell 7+

param(
    [switch]$Update
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$GoldenDir = Join-Path $ScriptDir "golden"

# Import the module
Import-Module (Join-Path $RootDir "chicle.psm1") -Force

# Check for update mode
$UpdateGoldens = $Update -or ($env:UPDATE_GOLDENS -eq "1")

# Test counters
$script:Pass = 0
$script:Fail = 0

function Pass($Name) {
    Write-Host "  `u{2713} $Name"
    $script:Pass++
}

function Fail($Name, $Expected, $Got) {
    Write-Host "  `u{2717} $Name"
    if ($Expected) {
        Write-Host "    Expected: $Expected"
        Write-Host "    Got:      $Got"
    }
    $script:Fail++
}

function Strip-Ansi($Text) {
    # Strip ANSI escape codes and carriage returns
    $Text -replace "`e\[[0-9;?]*[a-zA-Z]", "" -replace "`r", ""
}

function Check-Golden($Name, $Actual, $GoldenFile) {
    $cleaned = Strip-Ansi $Actual

    if ($UpdateGoldens) {
        $dir = Split-Path -Parent $GoldenFile
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        # Write with Unix line endings
        [System.IO.File]::WriteAllText($GoldenFile, "$cleaned`n")
        Pass "$Name (golden updated)"
        return
    }

    if (-not (Test-Path $GoldenFile)) {
        Fail $Name "(golden file: $GoldenFile)" "(file missing - run with -Update to create)"
        return
    }

    $expected = (Get-Content $GoldenFile -Raw).TrimEnd("`n").TrimEnd("`r")
    if ($cleaned -eq $expected) {
        Pass $Name
    } else {
        Fail $Name
        Write-Host "    --- expected (golden) ---"
        Write-Host "    $expected"
        Write-Host "    --- got ---"
        Write-Host "    $cleaned"
    }
}

# ============================================================================
# Golden file tests
# ============================================================================

Write-Host "Testing Invoke-ChicleStyle..."

Check-Golden "style: bold" `
    (Invoke-ChicleStyle -Bold "hello") `
    (Join-Path $GoldenDir "chicle_style/bold.txt")

Check-Golden "style: dim" `
    (Invoke-ChicleStyle -Dim "hello") `
    (Join-Path $GoldenDir "chicle_style/dim.txt")

Check-Golden "style: cyan" `
    (Invoke-ChicleStyle -Cyan "hello") `
    (Join-Path $GoldenDir "chicle_style/cyan.txt")

Check-Golden "style: green" `
    (Invoke-ChicleStyle -Green "hello") `
    (Join-Path $GoldenDir "chicle_style/green.txt")

Check-Golden "style: yellow" `
    (Invoke-ChicleStyle -Yellow "hello") `
    (Join-Path $GoldenDir "chicle_style/yellow.txt")

Check-Golden "style: red" `
    (Invoke-ChicleStyle -Red "hello") `
    (Join-Path $GoldenDir "chicle_style/red.txt")

Check-Golden "style: bold+cyan" `
    (Invoke-ChicleStyle -Bold -Cyan "hello") `
    (Join-Path $GoldenDir "chicle_style/bold-cyan.txt")


Write-Host "Testing Invoke-ChicleRule..."

Check-Golden "rule: default" `
    (Invoke-ChicleRule -Width 40) `
    (Join-Path $GoldenDir "chicle_rule/default.txt")

Check-Golden "rule: char =" `
    (Invoke-ChicleRule -Char "=" -Width 40) `
    (Join-Path $GoldenDir "chicle_rule/char-equals.txt")


Write-Host "Testing Invoke-ChicleLog..."

Check-Golden "log: info" `
    (Invoke-ChicleLog -Level info "test") `
    (Join-Path $GoldenDir "chicle_log/info.txt")

Check-Golden "log: success" `
    (Invoke-ChicleLog -Level success "test") `
    (Join-Path $GoldenDir "chicle_log/success.txt")

Check-Golden "log: warn" `
    (Invoke-ChicleLog -Level warn "test") `
    (Join-Path $GoldenDir "chicle_log/warn.txt")

Check-Golden "log: error" `
    (Invoke-ChicleLog -Level error "test") `
    (Join-Path $GoldenDir "chicle_log/error.txt")

Check-Golden "log: debug" `
    (Invoke-ChicleLog -Level debug "test") `
    (Join-Path $GoldenDir "chicle_log/debug.txt")

Check-Golden "log: step" `
    (Invoke-ChicleLog -Level step "test") `
    (Join-Path $GoldenDir "chicle_log/step.txt")


Write-Host "Testing Invoke-ChicleSteps..."

Check-Golden "steps: numeric" `
    (Invoke-ChicleSteps -Current 2 -Total 5 -Title "Installing") `
    (Join-Path $GoldenDir "chicle_steps/numeric.txt")

Check-Golden "steps: dots" `
    (Invoke-ChicleSteps -Current 2 -Total 5 -Title "Installing" -Style dots) `
    (Join-Path $GoldenDir "chicle_steps/dots.txt")

Check-Golden "steps: progress" `
    (Invoke-ChicleSteps -Current 3 -Total 5 -Title "Installing" -Style progress) `
    (Join-Path $GoldenDir "chicle_steps/progress.txt")

Check-Golden "steps: progress 100%" `
    (Invoke-ChicleSteps -Current 5 -Total 5 -Title "Done" -Style progress) `
    (Join-Path $GoldenDir "chicle_steps/progress-100.txt")


Write-Host "Testing Invoke-ChicleProgress..."

Check-Golden "progress: 50%" `
    (Invoke-ChicleProgress -Percent 50 -Title "Test" -Width 10) `
    (Join-Path $GoldenDir "chicle_progress/percent-50.txt")

Check-Golden "progress: 100%" `
    (Invoke-ChicleProgress -Percent 100 -Title "Test" -Width 10) `
    (Join-Path $GoldenDir "chicle_progress/percent-100.txt")

Check-Golden "progress: current/total" `
    (Invoke-ChicleProgress -Current 3 -Total 10 -Title "Test" -Width 10) `
    (Join-Path $GoldenDir "chicle_progress/current-total.txt")

Check-Golden "progress: 0%" `
    (Invoke-ChicleProgress -Percent 0 -Title "Test" -Width 10) `
    (Join-Path $GoldenDir "chicle_progress/percent-0.txt")


# ============================================================================
# Summary
# ============================================================================

Write-Host ""
Write-Host ([char]0x2501).ToString() * 51
Write-Host "Results: $($script:Pass) passed, $($script:Fail) failed"
Write-Host ([char]0x2501).ToString() * 51

if ($script:Fail -gt 0) { exit 1 } else { exit 0 }
