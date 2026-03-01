#Requires -Version 7.0
#Requires -Modules Pester

BeforeAll {
    Import-Module "$PSScriptRoot/../../chicle.psm1" -Force
    $script:FIXTURES = "$PSScriptRoot/../fixtures"

    # Read golden fixture files with explicit UTF-8 encoding to avoid
    # platform-specific Get-Content quirks (BOM handling, line ending conversion)
    function Get-Golden([string]$Name) {
        $path = Join-Path $script:FIXTURES $Name
        [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    }
}

Describe "Chicle-Style" {
    It "applies bold" {
        Chicle-Style -Bold "hello" | Should -BeExactly (Get-Golden "style_bold.golden")
    }

    It "applies dim" {
        Chicle-Style -Dim "hello" | Should -BeExactly (Get-Golden "style_dim.golden")
    }

    It "applies cyan" {
        Chicle-Style -Cyan "hello" | Should -BeExactly (Get-Golden "style_cyan.golden")
    }

    It "applies green" {
        Chicle-Style -Green "hello" | Should -BeExactly (Get-Golden "style_green.golden")
    }

    It "applies yellow" {
        Chicle-Style -Yellow "hello" | Should -BeExactly (Get-Golden "style_yellow.golden")
    }

    It "applies red" {
        Chicle-Style -Red "hello" | Should -BeExactly (Get-Golden "style_red.golden")
    }

    It "combines bold and cyan" {
        Chicle-Style -Bold -Cyan "hello" | Should -BeExactly (Get-Golden "style_bold_cyan.golden")
    }

    It "handles empty text" {
        Chicle-Style -Bold "" | Should -BeExactly (Get-Golden "style_bold_empty.golden")
    }

    It "handles text only (no flags)" {
        Chicle-Style "plain" | Should -BeExactly (Get-Golden "style_plain.golden")
    }

    It "combines bold, dim, and red" {
        Chicle-Style -Bold -Dim -Red "alert" | Should -BeExactly (Get-Golden "style_bold_dim_red.golden")
    }
}

Describe "Chicle-Log" {
    It "logs info" {
        Chicle-Log -Info "test" | Should -BeExactly (Get-Golden "log_info.golden")
    }

    It "logs success" {
        Chicle-Log -Success "test" | Should -BeExactly (Get-Golden "log_success.golden")
    }

    It "logs warn" {
        Chicle-Log -Warn "test" | Should -BeExactly (Get-Golden "log_warn.golden")
    }

    It "logs error" {
        Chicle-Log -Error "test" | Should -BeExactly (Get-Golden "log_error.golden")
    }

    It "logs debug" {
        Chicle-Log -Debug "test" | Should -BeExactly (Get-Golden "log_debug.golden")
    }

    It "logs step" {
        Chicle-Log -Step "test" | Should -BeExactly (Get-Golden "log_step.golden")
    }

    It "defaults to plain with no level" {
        Chicle-Log "just text" | Should -BeExactly (Get-Golden "log_plain.golden")
    }
}

Describe "Chicle-Rule" {
    It "contains line char" {
        Chicle-Rule | Should -Match ([char]0x2500)  # ─
    }

    It "uses custom char" {
        Chicle-Rule -Char "=" | Should -Match "="
    }
}

Describe "Chicle-Steps" {
    It "renders numeric style" {
        Chicle-Steps -Current 2 -Total 5 -Title "Installing" | Should -BeExactly (Get-Golden "steps_numeric.golden")
    }

    It "renders dots style" {
        Chicle-Steps -Current 2 -Total 5 -Title "Installing" -Style dots | Should -BeExactly (Get-Golden "steps_dots.golden")
    }

    It "renders progress style" {
        Chicle-Steps -Current 3 -Total 5 -Title "Installing" -Style progress | Should -BeExactly (Get-Golden "steps_progress.golden")
    }

    It "renders progress at 100%" {
        Chicle-Steps -Current 5 -Total 5 -Title "Done" -Style progress | Should -BeExactly (Get-Golden "steps_progress_full.golden")
    }

    It "renders 1 of 1" {
        Chicle-Steps -Current 1 -Total 1 -Title "Only step" | Should -BeExactly (Get-Golden "steps_one_of_one.golden")
    }

    It "throws on total 0" {
        { Chicle-Steps -Current 1 -Total 0 } | Should -Throw
    }

    It "renders dots 0/3" {
        Chicle-Steps -Current 0 -Total 3 -Style dots | Should -BeExactly (Get-Golden "steps_dots_zero.golden")
    }

    It "renders dots 3/3" {
        Chicle-Steps -Current 3 -Total 3 -Style dots | Should -BeExactly (Get-Golden "steps_dots_full.golden")
    }
}

Describe "Chicle-Table" {
    It "renders basic box style" {
        $output = Chicle-Table -Header "Name,Value" -Rows "foo,bar", "baz,qux"
        $output | Should -BeExactly (Get-Golden "table_basic_box.golden")
    }

    It "renders without header" {
        $output = Chicle-Table -Rows "a,b", "c,d"
        $output | Should -BeExactly (Get-Golden "table_no_header.golden")
    }

    It "renders simple style" {
        $output = Chicle-Table -Style simple -Header "A,B" -Rows "1,2"
        $output | Should -BeExactly (Get-Golden "table_simple.golden")
    }

    It "uses custom separator" {
        $output = Chicle-Table -Sep "|" -Header "A|B" -Rows "1|2"
        $output | Should -BeExactly (Get-Golden "table_custom_sep.golden")
    }

    It "aligns columns" {
        $output = Chicle-Table -Header "X,Y" -Rows "hello,w", "hi,world"
        $output | Should -BeExactly (Get-Golden "table_alignment.golden")
    }

    It "renders three columns" {
        $output = Chicle-Table -Header "Package,Version,Status" -Rows "chicle,1.0,ok", "bash,5.2,ok"
        $output | Should -BeExactly (Get-Golden "table_three_cols.golden")
    }

    It "handles fewer cols than header" {
        $output = Chicle-Table -Header "A,B,C" -Rows "1,2"
        $output | Should -BeExactly (Get-Golden "table_fewer_cols.golden")
    }

    It "renders header-only table" {
        $output = Chicle-Table -Header "Name,Value"
        $output | Should -BeExactly (Get-Golden "table_header_only.golden")
    }

    It "renders single column" {
        $output = Chicle-Table -Header "Name" -Rows "alice", "bob"
        $output | Should -BeExactly (Get-Golden "table_single_col.golden")
    }

    It "accepts pipeline input" {
        $output = "foo,bar", "baz,qux" | Chicle-Table -Header "Name,Value"
        $output | Should -BeExactly (Get-Golden "table_stdin.golden")
    }

    It "throws on empty input" {
        { Chicle-Table } | Should -Throw
    }
}

Describe "Chicle-Spin" {
    It "returns 0 on success" {
        Mock Write-Host {} -ModuleName chicle
        Mock Start-Sleep {} -ModuleName chicle
        $result = Chicle-Spin -Title "OK" -ScriptBlock { $true }
        $result | Should -Be 0
    }

    It "returns non-zero on failure" {
        Mock Write-Host {} -ModuleName chicle
        Mock Start-Sleep {} -ModuleName chicle
        $result = Chicle-Spin -Title "Fail" -ScriptBlock { throw "error" }
        $result | Should -Not -Be 0
    }

    It "preserves failure from exit code" {
        Mock Write-Host {} -ModuleName chicle
        Mock Start-Sleep {} -ModuleName chicle
        $result = Chicle-Spin -Title "Fail" -ScriptBlock { exit 1 }
        $result | Should -Not -Be 0
    }
}

Describe "Chicle-Progress" {
    # Progress uses Write-Host internally — must mock inside the module scope
    It "calls Write-Host with correct bar at 50%" {
        Mock Write-Host {} -ModuleName chicle
        Chicle-Progress -Percent 50 -Title "Test" -Width 10
        Should -Invoke Write-Host -ModuleName chicle -ParameterFilter {
            $Object -match "$([char]0x2588){5}" -and $Object -match "$([char]0x2591){5}"
        }
    }

    It "calls Write-Host with full bar at 100%" {
        Mock Write-Host {} -ModuleName chicle
        Chicle-Progress -Percent 100 -Title "Test" -Width 10
        Should -Invoke Write-Host -ModuleName chicle -ParameterFilter {
            $Object -match "$([char]0x2588){10}" -and $Object -match "100%"
        }
    }

    It "clamps above 100" {
        Mock Write-Host {} -ModuleName chicle
        Chicle-Progress -Percent 150 -Width 10
        Should -Invoke Write-Host -ModuleName chicle -ParameterFilter {
            $Object -match "100%"
        }
    }

    It "clamps below 0" {
        Mock Write-Host {} -ModuleName chicle
        Chicle-Progress -Percent -10 -Width 10
        Should -Invoke Write-Host -ModuleName chicle -ParameterFilter {
            $Object -match "  0%"
        }
    }
}

Describe "Chicle-File" {
    BeforeEach {
        $script:testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "chicle_file_test_$([guid]::NewGuid().ToString('N'))"
        New-Item -ItemType Directory -Path $script:testRoot -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $script:testRoot "alpha") -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $script:testRoot "alpha" "nested") -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $script:testRoot "beta") -Force | Out-Null
        "x" | Set-Content (Join-Path $script:testRoot "file1.txt")
        "x" | Set-Content (Join-Path $script:testRoot "file2.sh")
        "x" | Set-Content (Join-Path $script:testRoot "alpha" "inner.txt")
        $global:chicleFileMockCount = 0
    }

    AfterEach {
        Remove-Item -Recurse -Force $script:testRoot -ErrorAction SilentlyContinue
    }

    It "selects a file" {
        Mock Chicle-Choose { "file1.txt" } -ModuleName chicle
        $result = Chicle-File -Path $script:testRoot
        $result | Should -BeExactly (Join-Path $script:testRoot "file1.txt")
    }

    It "navigates into directory and selects" {
        Mock Chicle-Choose {
            $global:chicleFileMockCount++
            if ($global:chicleFileMockCount -eq 1) { "alpha/" }
            else { "inner.txt" }
        } -ModuleName chicle
        $result = Chicle-File -Path $script:testRoot
        $result | Should -BeExactly (Join-Path $script:testRoot "alpha" "inner.txt")
    }

    It "navigates up with .." {
        Mock Chicle-Choose {
            $global:chicleFileMockCount++
            if ($global:chicleFileMockCount -eq 1) { ".." }
            else { "file1.txt" }
        } -ModuleName chicle
        $result = Chicle-File -Path (Join-Path $script:testRoot "alpha")
        $result | Should -BeExactly (Join-Path $script:testRoot "file1.txt")
    }

    It "returns null on quit" {
        Mock Chicle-Choose { $null } -ModuleName chicle
        $result = Chicle-File -Path $script:testRoot
        $result | Should -BeNullOrEmpty
    }

    It "filters files with -Filter" {
        Mock Chicle-Choose {
            param([string]$Header, [string[]]$Options)
            $Options | Should -Contain "file1.txt"
            $Options | Should -Not -Contain "file2.sh"
            "file1.txt"
        } -ModuleName chicle
        $result = Chicle-File -Path $script:testRoot -Filter "*.txt"
        $result | Should -BeExactly (Join-Path $script:testRoot "file1.txt")
    }

    It "dir mode shows . entry and no files" {
        Mock Chicle-Choose {
            param([string]$Header, [string[]]$Options)
            $Options | Should -Contain "."
            $Options | Should -Not -Contain "file1.txt"
            $Options | Should -Not -Contain "file2.sh"
            "."
        } -ModuleName chicle
        $result = Chicle-File -Path $script:testRoot -Dir
        $result | Should -BeExactly $script:testRoot
    }

    It "shows header in display" {
        Mock Chicle-Choose {
            param([string]$Header, [string[]]$Options)
            $Header | Should -Match "Pick"
            "file1.txt"
        } -ModuleName chicle
        Chicle-File -Path $script:testRoot -Header "Pick" | Out-Null
    }
}
