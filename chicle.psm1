# chicle - Pure PowerShell TUI library for delightful shell scripts
# Requires: PowerShell 7+

# ANSI escape character
$script:ESC = [char]27

# Colors
$script:CHICLE_BOLD = "$script:ESC[1m"
$script:CHICLE_DIM = "$script:ESC[2m"
$script:CHICLE_RESET = "$script:ESC[0m"
$script:CHICLE_CYAN = "$script:ESC[36m"
$script:CHICLE_GREEN = "$script:ESC[32m"
$script:CHICLE_YELLOW = "$script:ESC[33m"
$script:CHICLE_RED = "$script:ESC[31m"

<#
.SYNOPSIS
    Style text with formatting and colors.
.EXAMPLE
    Invoke-ChicleStyle -Bold -Cyan "hello"
#>
function Invoke-ChicleStyle {
    param(
        [switch]$Bold,
        [switch]$Dim,
        [switch]$Cyan,
        [switch]$Green,
        [switch]$Yellow,
        [switch]$Red,
        [Parameter(Position = 0, Mandatory)]
        [string]$Text
    )

    $prefix = ""
    if ($Bold) { $prefix += $script:CHICLE_BOLD }
    if ($Dim) { $prefix += $script:CHICLE_DIM }
    if ($Cyan) { $prefix += $script:CHICLE_CYAN }
    if ($Green) { $prefix += $script:CHICLE_GREEN }
    if ($Yellow) { $prefix += $script:CHICLE_YELLOW }
    if ($Red) { $prefix += $script:CHICLE_RED }

    "$prefix$Text$($script:CHICLE_RESET)"
}

<#
.SYNOPSIS
    Print a horizontal rule spanning the terminal width.
.EXAMPLE
    Invoke-ChicleRule -Char "=" -Width 40
#>
function Invoke-ChicleRule {
    param(
        [string]$Char = [char]0x2500,  # ─
        [int]$Width = 0
    )

    if ($Width -le 0) {
        $Width = $Host.UI.RawUI.WindowSize.Width
    }

    $Char[0].ToString() * $Width
}

<#
.SYNOPSIS
    Styled log output with icons.
.EXAMPLE
    Invoke-ChicleLog -Level info "Operation complete"
    Invoke-ChicleLog -Level error "Something went wrong"
#>
function Invoke-ChicleLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("info", "success", "warn", "error", "debug", "step")]
        [string]$Level,
        [Parameter(Position = 0, Mandatory)]
        [string]$Message
    )

    switch ($Level) {
        "info"    { "$($script:CHICLE_CYAN)`u{2139}$($script:CHICLE_RESET) $Message" }
        "success" { "$($script:CHICLE_GREEN)`u{2713}$($script:CHICLE_RESET) $Message" }
        "warn"    { "$($script:CHICLE_YELLOW)`u{26A0}$($script:CHICLE_RESET) $Message" }
        "error"   { "$($script:CHICLE_RED)`u{2717}$($script:CHICLE_RESET) $Message" }
        "debug"   { "$($script:CHICLE_DIM)`u{00B7} $Message$($script:CHICLE_RESET)" }
        "step"    { "$($script:CHICLE_BOLD)`u{2192} $Message$($script:CHICLE_RESET)" }
        default   { $Message }
    }
}

<#
.SYNOPSIS
    Step indicator for multi-step processes.
.EXAMPLE
    Invoke-ChicleSteps -Current 2 -Total 5 -Title "Installing" -Style dots
#>
function Invoke-ChicleSteps {
    param(
        [Parameter(Mandatory)]
        [int]$Current,
        [Parameter(Mandatory)]
        [int]$Total,
        [string]$Title = "",
        [ValidateSet("numeric", "dots", "progress")]
        [string]$Style = "numeric"
    )

    if ($Total -eq 0) { return }

    switch ($Style) {
        "numeric" {
            "$($script:CHICLE_BOLD)[$Current/$Total]$($script:CHICLE_RESET) $Title"
        }
        "dots" {
            $filled = ([char]0x25CF).ToString()   # ●
            $empty = ([char]0x25CB).ToString()     # ○
            $dots = @()
            for ($i = 1; $i -le $Total; $i++) {
                if ($i -le $Current) { $dots += $filled }
                else { $dots += $empty }
            }
            "$($script:CHICLE_CYAN)$($dots -join ' ')$($script:CHICLE_RESET)  $Title"
        }
        "progress" {
            $filledCount = [math]::Floor($Current * 5 / $Total)
            $emptyCount = 5 - $filledCount
            $bar = ([char]0x2588).ToString() * $filledCount   # █
            $bar += ([char]0x2591).ToString() * $emptyCount   # ░
            "$($script:CHICLE_CYAN)[$bar]$($script:CHICLE_RESET) $Title"
        }
    }
}

<#
.SYNOPSIS
    Progress bar with in-place updating.
.EXAMPLE
    Invoke-ChicleProgress -Percent 50 -Title "Test" -Width 10
#>
function Invoke-ChicleProgress {
    param(
        [int]$Percent = -1,
        [int]$Current = -1,
        [int]$Total = -1,
        [string]$Title = "",
        [int]$Width = 0
    )

    # Calculate percent from current/total if not given directly
    if ($Percent -lt 0 -and $Current -ge 0 -and $Total -gt 0) {
        $Percent = [math]::Floor($Current * 100 / $Total)
    }

    if ($Percent -lt 0) { $Percent = 0 }
    if ($Percent -gt 100) { $Percent = 100 }

    # Auto-calculate bar width
    if ($Width -le 0) {
        $cols = $Host.UI.RawUI.WindowSize.Width
        $reserved = $Title.Length + 8
        $Width = $cols - $reserved
        if ($Width -lt 10) { $Width = 10 }
        if ($Width -gt 50) { $Width = 50 }
    }

    $filledCount = [math]::Floor($Percent * $Width / 100)
    $emptyCount = $Width - $filledCount

    $bar = ([char]0x2588).ToString() * $filledCount    # █
    $bar += ([char]0x2591).ToString() * $emptyCount    # ░

    $color = $script:CHICLE_CYAN
    if ($Percent -eq 100) { $color = $script:CHICLE_GREEN }

    $percentStr = $Percent.ToString().PadLeft(3)

    # Output without trailing newline (for in-place updates)
    # When captured in a variable, this is just the string
    "`r$Title $color[$bar]$($script:CHICLE_RESET) $percentStr%"
}

Export-ModuleMember -Function Invoke-ChicleStyle, Invoke-ChicleRule, Invoke-ChicleLog, Invoke-ChicleSteps, Invoke-ChicleProgress
