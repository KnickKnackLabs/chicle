#Requires -Version 7.0
# chicle - PowerShell TUI library for delightful shell scripts

# Colors (ANSI escape sequences — identical to bash implementation)
$script:CHICLE_BOLD   = "`e[1m"
$script:CHICLE_DIM    = "`e[2m"
$script:CHICLE_RESET  = "`e[0m"
$script:CHICLE_CYAN   = "`e[36m"
$script:CHICLE_GREEN  = "`e[32m"
$script:CHICLE_YELLOW = "`e[33m"
$script:CHICLE_RED    = "`e[31m"

# Repeat a string N times
function _chicle_repeat {
    param([string]$Char, [int]$Count)
    if ($Count -le 0) { return "" }
    $Char * $Count
}

# Style text with formatting
# Usage: Chicle-Style [-Bold] [-Dim] [-Cyan|-Green|-Yellow|-Red] "TEXT"
function Chicle-Style {
    [CmdletBinding()]
    param(
        [switch]$Bold,
        [switch]$Dim,
        [switch]$Cyan,
        [switch]$Green,
        [switch]$Yellow,
        [switch]$Red,
        [Parameter(Position = 0)]
        [string]$Text = ""
    )

    $prefix = ""
    if ($Bold)   { $prefix += $script:CHICLE_BOLD }
    if ($Dim)    { $prefix += $script:CHICLE_DIM }
    if ($Cyan)   { $prefix += $script:CHICLE_CYAN }
    elseif ($Green)  { $prefix += $script:CHICLE_GREEN }
    elseif ($Yellow) { $prefix += $script:CHICLE_YELLOW }
    elseif ($Red)    { $prefix += $script:CHICLE_RED }

    "${prefix}${Text}${script:CHICLE_RESET}"
}

# Prompt for text input
# Usage: Chicle-Input [-Placeholder TEXT] [-Prompt TEXT] [-Password] [-Mask [CHAR]]
function Chicle-Input {
    [CmdletBinding()]
    param(
        [string]$Placeholder = "",
        [string]$Prompt = "> ",
        [switch]$Password,
        [string]$Mask = ""
    )

    # If -Mask is provided without a value, default to bullet
    if ($PSBoundParameters.ContainsKey('Mask') -and $Mask -eq "") {
        $Mask = [char]0x2022  # •
        $Password = $true
    }
    if ($Mask -ne "") { $Password = $true }

    $value = ""

    if ($Password -or $Placeholder) {
        if ($Placeholder -and -not $Password) {
            Write-Host -NoNewline "${Prompt}${script:CHICLE_DIM}${Placeholder}${script:CHICLE_RESET}"
            Write-Host -NoNewline "`r$(' ' * 0)"
            # Move cursor to after prompt
            [Console]::SetCursorPosition($Prompt.Length, [Console]::CursorTop)
        } else {
            Write-Host -NoNewline $Prompt
        }

        while ($true) {
            $keyInfo = [Console]::ReadKey($true)
            $char = $keyInfo.KeyChar

            if ($keyInfo.Key -eq 'Enter') {
                break
            } elseif ($keyInfo.Key -eq 'Backspace') {
                if ($value.Length -gt 0) {
                    $value = $value.Substring(0, $value.Length - 1)
                    if ($Placeholder -and $value.Length -eq 0) {
                        Write-Host -NoNewline "`r$(' ' * ([Console]::WindowWidth - 1))"
                        Write-Host -NoNewline "`r${Prompt}${script:CHICLE_DIM}${Placeholder}${script:CHICLE_RESET}"
                        [Console]::SetCursorPosition($Prompt.Length, [Console]::CursorTop)
                    } elseif ($Mask) {
                        $masked = _chicle_repeat $Mask $value.Length
                        Write-Host -NoNewline "`r$(' ' * ([Console]::WindowWidth - 1))"
                        Write-Host -NoNewline "`r${Prompt}${masked}"
                    } elseif (-not $Password) {
                        Write-Host -NoNewline "`r$(' ' * ([Console]::WindowWidth - 1))"
                        Write-Host -NoNewline "`r${Prompt}${value}"
                    } else {
                        Write-Host -NoNewline "`b `b"
                    }
                }
            } else {
                if ($char -ne [char]0) {
                    if ($Placeholder -and $value.Length -eq 0) {
                        Write-Host -NoNewline "`r$(' ' * ([Console]::WindowWidth - 1))"
                        Write-Host -NoNewline "`r${Prompt}"
                    }
                    $value += $char
                    if ($Mask) {
                        Write-Host -NoNewline $Mask
                    } elseif (-not $Password) {
                        Write-Host -NoNewline $char
                    }
                }
            }
        }
        Write-Host ""  # Final newline
    } else {
        Write-Host -NoNewline $Prompt
        $value = Read-Host
    }

    $value
}

# Yes/no confirmation
# Usage: Chicle-Confirm [-Default "yes"|"no"] "PROMPT"
function Chicle-Confirm {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Prompt,
        [ValidateSet("yes", "no")]
        [string]$Default = "no"
    )

    $hint = if ($Default -eq "yes") { "[Y/n]" } else { "[y/N]" }
    Write-Host -NoNewline "${script:CHICLE_BOLD}${Prompt}${script:CHICLE_RESET} ${hint} "
    $reply = Read-Host

    if ([string]::IsNullOrEmpty($reply)) {
        return ($Default -eq "yes")
    }
    return ($reply -match '^[Yy]')
}

# Spinner while command runs
# Note: The scriptblock runs in a separate pwsh process, so it does not have
# access to the caller's variables, modules, or working directory.
# Usage: Chicle-Spin [-Title TEXT] -ScriptBlock { ... }
function Chicle-Spin {
    [CmdletBinding()]
    param(
        [string]$Title = "",
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock
    )

    $frames = @([char]0x280B, [char]0x2819, [char]0x2839, [char]0x2838,
                 [char]0x283C, [char]0x2834, [char]0x2826, [char]0x2827,
                 [char]0x2807, [char]0x280F)

    # Write scriptblock to a temp file and run as a subprocess so we can
    # capture the exact exit code. Start-Job loses non-zero exit codes
    # because PowerShell marks jobs as "Completed" even when the child
    # process exits with a non-zero code.
    $tempScript = Join-Path ([System.IO.Path]::GetTempPath()) "chicle_spin_$([guid]::NewGuid().ToString('N')).ps1"
    $ScriptBlock.ToString() | Set-Content $tempScript -Encoding UTF8

    # Hide cursor
    Write-Host -NoNewline "`e[?25l"

    $exitCode = 0
    try {
        $psi = [System.Diagnostics.ProcessStartInfo]::new()
        $psi.FileName = (Get-Command pwsh -ErrorAction Stop).Source
        $psi.Arguments = "-NoProfile -NonInteractive -File `"$tempScript`""
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.CreateNoWindow = $true

        $proc = [System.Diagnostics.Process]::Start($psi)

        $i = 0
        while (-not $proc.HasExited) {
            $frame = $frames[$i % $frames.Count]
            Write-Host -NoNewline "`r${script:CHICLE_CYAN}${frame}${script:CHICLE_RESET} ${Title}"
            $i++
            Start-Sleep -Milliseconds 100
        }

        $proc.WaitForExit()
        $exitCode = $proc.ExitCode
    } finally {
        Remove-Item $tempScript -ErrorAction SilentlyContinue
        # Show cursor
        Write-Host -NoNewline "`e[?25h"
    }

    if ($exitCode -eq 0) {
        Write-Host "`r${script:CHICLE_GREEN}$([char]0x2713)${script:CHICLE_RESET} ${Title}"
    } else {
        Write-Host "`r${script:CHICLE_RED}$([char]0x2717)${script:CHICLE_RESET} ${Title}"
    }

    return $exitCode
}

# Interactive chooser with arrow keys
# Usage: Chicle-Choose [-Header TEXT] [-Multi] -Options @("A", "B", "C")
function Chicle-Choose {
    [CmdletBinding()]
    param(
        [string]$Header = "",
        [switch]$Multi,
        [Parameter(Position = 0, Mandatory)]
        [string[]]$Options
    )

    $count = $Options.Count
    if ($count -eq 0) { return $null }

    $cursor = 0
    $selections = @($false) * $count

    # Save cursor position and hide cursor
    Write-Host -NoNewline "`e[s`e[?25l"

    function _draw_menu {
        # Restore cursor to saved position
        Write-Host -NoNewline "`e[u"

        if ($Header) {
            Write-Host "${script:CHICLE_BOLD}${Header}${script:CHICLE_RESET}"
        }

        for ($i = 0; $i -lt $count; $i++) {
            $opt = $Options[$i]
            if ($Multi) {
                $checkbox = if ($selections[$i]) { "[x]" } else { "[ ]" }
                if ($i -eq $cursor) {
                    Write-Host "${script:CHICLE_CYAN}$([char]0x276F) ${checkbox} ${opt}${script:CHICLE_RESET}"
                } else {
                    Write-Host "  ${checkbox} ${opt}"
                }
            } else {
                if ($i -eq $cursor) {
                    Write-Host "${script:CHICLE_CYAN}$([char]0x276F) ${opt}${script:CHICLE_RESET}"
                } else {
                    Write-Host "  ${opt}"
                }
            }
        }
    }

    _draw_menu

    try {
        # Use a flag to exit the loop — in PowerShell, `break` inside a
        # `switch` only exits the switch, not the enclosing while loop.
        $done = $false
        while (-not $done) {
            $key = [Console]::ReadKey($true)

            switch ($key.Key) {
                'UpArrow'   { if ($cursor -gt 0) { $cursor-- }; _draw_menu }
                'DownArrow' { if ($cursor -lt $count - 1) { $cursor++ }; _draw_menu }
                'Spacebar'  {
                    if ($Multi) {
                        $selections[$cursor] = -not $selections[$cursor]
                        _draw_menu
                    }
                }
                'Enter'     { $done = $true }
                'Q'         {
                    # Show cursor
                    Write-Host -NoNewline "`e[?25h"
                    return $null
                }
            }
        }
    } finally {
        # Show cursor
        Write-Host -NoNewline "`e[?25h"
    }

    if ($Multi) {
        $result = @()
        for ($i = 0; $i -lt $count; $i++) {
            if ($selections[$i]) {
                $result += $Options[$i]
            }
        }
        $result
    } else {
        $Options[$cursor]
    }
}

# Print a horizontal rule
# Usage: Chicle-Rule [-Char CHAR]
function Chicle-Rule {
    [CmdletBinding()]
    param(
        [string]$Char = [string][char]0x2500  # ─
    )

    $cols = try { $Host.UI.RawUI.WindowSize.Width } catch { 80 }
    (_chicle_repeat $Char $cols)
}

# Styled log output with icons
# Usage: Chicle-Log [-Info|-Success|-Warn|-Error|-Debug|-Step] "MESSAGE"
# Note: -Error and -Debug conflict with PowerShell common parameters, so we
# use a simple function (no CmdletBinding) and parse level flags manually.
function Chicle-Log {
    $level = ""
    $message = ""

    foreach ($arg in $args) {
        switch ($arg) {
            '-Info'    { $level = "info" }
            '-Success' { $level = "success" }
            '-Warn'    { $level = "warn" }
            '-Error'   { $level = "error" }
            '-Debug'   { $level = "debug" }
            '-Step'    { $level = "step" }
            default    { $message = $arg }
        }
    }

    switch ($level) {
        "info"    { "${script:CHICLE_CYAN}$([char]0x2139)${script:CHICLE_RESET} ${message}" }
        "success" { "${script:CHICLE_GREEN}$([char]0x2713)${script:CHICLE_RESET} ${message}" }
        "warn"    { "${script:CHICLE_YELLOW}$([char]0x26A0)${script:CHICLE_RESET} ${message}" }
        "error"   { "${script:CHICLE_RED}$([char]0x2717)${script:CHICLE_RESET} ${message}" }
        "debug"   { "${script:CHICLE_DIM}$([char]0x00B7) ${message}${script:CHICLE_RESET}" }
        "step"    { "${script:CHICLE_BOLD}$([char]0x2192) ${message}${script:CHICLE_RESET}" }
        default   { $message }
    }
}

# Step indicator for multi-step processes
# Usage: Chicle-Steps -Current N -Total M [-Title TEXT] [-Style numeric|dots|progress]
function Chicle-Steps {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$Current,
        [Parameter(Mandatory)]
        [int]$Total,
        [string]$Title = "",
        [ValidateSet("numeric", "dots", "progress")]
        [string]$Style = "numeric"
    )

    if ($Total -eq 0) { throw "Total must be greater than 0" }

    switch ($Style) {
        "numeric" {
            "${script:CHICLE_BOLD}[${Current}/${Total}]${script:CHICLE_RESET} ${Title}"
        }
        "dots" {
            $dots = ""
            for ($i = 1; $i -le $Total; $i++) {
                $dots += if ($i -le $Current) { [char]0x25CF } else { [char]0x25CB }  # ● or ○
                if ($i -lt $Total) { $dots += " " }
            }
            "${script:CHICLE_CYAN}${dots}${script:CHICLE_RESET}  ${Title}"
        }
        "progress" {
            $filled = [math]::Floor($Current * 5 / $Total)
            $empty = 5 - $filled
            $bar = (_chicle_repeat ([string][char]0x2588) $filled) + (_chicle_repeat ([string][char]0x2591) $empty)
            "${script:CHICLE_CYAN}[${bar}]${script:CHICLE_RESET} ${Title}"
        }
    }
}

# Formatted table output
# Usage: Chicle-Table [-Header FIELDS] [-Sep CHAR] [-Style box|simple] [-Rows] ROW1,ROW2,...
#    or: ... | Chicle-Table [-Header FIELDS] [-Sep CHAR] [-Style box|simple]
function Chicle-Table {
    [CmdletBinding()]
    param(
        [string]$Header = "",
        [string]$Sep = ",",
        [ValidateSet("box", "simple")]
        [string]$Style = "box",
        [Parameter(Position = 0, ValueFromPipeline)]
        [string[]]$Rows = @()
    )

    begin {
        $allInputRows = [System.Collections.Generic.List[string]]::new()
    }

    process {
        foreach ($row in $Rows) {
            if ($row) { $allInputRows.Add($row) }
        }
    }

    end {
        if ($allInputRows.Count -eq 0 -and -not $Header) {
            throw "No data provided"
        }

        # Split helper — returns array. The leading comma forces PowerShell to
        # preserve single-element arrays instead of unwrapping to a scalar.
        function _split([string]$str, [string]$s) {
            $result = [System.Collections.Generic.List[string]]::new()
            while ($str.Contains($s)) {
                $idx = $str.IndexOf($s)
                $result.Add($str.Substring(0, $idx))
                $str = $str.Substring($idx + $s.Length)
            }
            $result.Add($str)
            , $result.ToArray()
        }

        # Build all data rows and calculate column widths
        $widths = @()
        $allRows = [System.Collections.Generic.List[object]]::new()
        $ncols = 0

        # Process header
        if ($Header) {
            $fields = _split $Header $Sep
            $ncols = $fields.Count
            $widths = @(0) * $ncols
            for ($c = 0; $c -lt $ncols; $c++) {
                $widths[$c] = $fields[$c].Length
            }
            $allRows.Add(@{ Type = "H"; Data = $Header })
        }

        # Process data rows
        foreach ($row in $allInputRows) {
            $fields = _split $row $Sep
            $rc = $fields.Count
            if ($rc -gt $ncols) {
                $oldWidths = $widths
                $widths = @(0) * $rc
                for ($c = 0; $c -lt $oldWidths.Count; $c++) {
                    $widths[$c] = $oldWidths[$c]
                }
                $ncols = $rc
            }
            for ($c = 0; $c -lt $rc; $c++) {
                $len = $fields[$c].Length
                if ($len -gt $widths[$c]) { $widths[$c] = $len }
            }
            $allRows.Add(@{ Type = "D"; Data = $row })
        }

        if ($ncols -eq 0) { throw "No columns" }

        # Render helpers
        function _box_line([string]$left, [string]$mid, [string]$right, [string]$fill) {
            $line = $left
            for ($c = 0; $c -lt $ncols; $c++) {
                $line += _chicle_repeat $fill ($widths[$c] + 2)
                if ($c -lt ($ncols - 1)) { $line += $mid }
            }
            $line += $right
            $line
        }

        function _box_row([string]$rowStr, [bool]$isHeader) {
            $fields = _split $rowStr $Sep
            $line = [string][char]0x2502  # │
            for ($c = 0; $c -lt $ncols; $c++) {
                $val = if ($c -lt $fields.Count) { $fields[$c] } else { "" }
                $w = $widths[$c]
                $padded = $val.PadRight($w)
                if ($isHeader) {
                    $line += " ${script:CHICLE_BOLD}${padded}${script:CHICLE_RESET} $([char]0x2502)"
                } else {
                    $line += " ${padded} $([char]0x2502)"
                }
            }
            $line
        }

        function _simple_row([string]$rowStr, [bool]$isHeader) {
            $fields = _split $rowStr $Sep
            $line = ""
            for ($c = 0; $c -lt $ncols; $c++) {
                $val = if ($c -lt $fields.Count) { $fields[$c] } else { "" }
                $w = $widths[$c]
                $padded = $val.PadRight($w)
                if ($isHeader) {
                    $line += "${script:CHICLE_BOLD}${padded}${script:CHICLE_RESET}"
                } else {
                    $line += $padded
                }
                if ($c -lt ($ncols - 1)) { $line += "  " }
            }
            $line
        }

        function _simple_separator {
            $line = ""
            for ($c = 0; $c -lt $ncols; $c++) {
                $line += _chicle_repeat ([string][char]0x2500) $widths[$c]  # ─
                if ($c -lt ($ncols - 1)) { $line += "  " }
            }
            $line
        }

        # Render table
        $output = [System.Collections.Generic.List[string]]::new()

        if ($Style -eq "box") {
            $output.Add((_box_line ([string][char]0x250C) ([string][char]0x252C) ([string][char]0x2510) ([string][char]0x2500)))
            foreach ($entry in $allRows) {
                if ($entry.Type -eq "H") {
                    $output.Add((_box_row $entry.Data $true))
                    $output.Add((_box_line ([string][char]0x251C) ([string][char]0x253C) ([string][char]0x2524) ([string][char]0x2500)))
                } else {
                    $output.Add((_box_row $entry.Data $false))
                }
            }
            $output.Add((_box_line ([string][char]0x2514) ([string][char]0x2534) ([string][char]0x2518) ([string][char]0x2500)))
        } else {
            foreach ($entry in $allRows) {
                if ($entry.Type -eq "H") {
                    $output.Add((_simple_row $entry.Data $true))
                    $output.Add((_simple_separator))
                } else {
                    $output.Add((_simple_row $entry.Data $false))
                }
            }
        }

        $output -join "`n"
    }
}

# Progress bar with in-place updating
# Usage: Chicle-Progress -Percent N [-Title TEXT] [-Width W]
#    or: Chicle-Progress -Current N -Total M [-Title TEXT] [-Width W]
function Chicle-Progress {
    [CmdletBinding()]
    param(
        [int]$Percent = -1,
        [int]$Current = -1,
        [int]$Total = -1,
        [string]$Title = "",
        [int]$Width = 0
    )

    # Calculate percent from current/total if not given directly
    if ($Percent -eq -1 -and $Current -ge 0 -and $Total -gt 0) {
        $Percent = [math]::Floor($Current * 100 / $Total)
    }
    if ($Percent -lt 0) { $Percent = 0 }
    if ($Percent -gt 100) { $Percent = 100 }

    # Auto-calculate bar width
    if ($Width -eq 0) {
        $cols = try { $Host.UI.RawUI.WindowSize.Width } catch { 80 }
        $reserved = $Title.Length + 8
        $Width = $cols - $reserved
        if ($Width -lt 10) { $Width = 10 }
        if ($Width -gt 50) { $Width = 50 }
    }

    $filled = [math]::Floor($Percent * $Width / 100)
    $empty = $Width - $filled
    $bar = (_chicle_repeat ([string][char]0x2588) $filled) + (_chicle_repeat ([string][char]0x2591) $empty)

    $color = $script:CHICLE_CYAN
    if ($Percent -eq 100) { $color = $script:CHICLE_GREEN }

    $formatted = "`r${Title} ${color}[${bar}]${script:CHICLE_RESET} $($Percent.ToString().PadLeft(3))%"
    Write-Host -NoNewline $formatted
}

Export-ModuleMember -Function @(
    'Chicle-Style',
    'Chicle-Input',
    'Chicle-Confirm',
    'Chicle-Choose',
    'Chicle-Spin',
    'Chicle-Rule',
    'Chicle-Log',
    'Chicle-Steps',
    'Chicle-Table',
    'Chicle-Progress'
)
