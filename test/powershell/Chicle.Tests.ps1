#Requires -Version 7.0
#Requires -Modules Pester

BeforeAll {
    Import-Module "$PSScriptRoot/../../chicle.psm1" -Force
    $script:FIXTURES = "$PSScriptRoot/../fixtures"
}

Describe "Chicle-Style" {
    It "applies bold" {
        $output = Chicle-Style -Bold "hello"
        $expected = Get-Content "$script:FIXTURES/style_bold.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "applies dim" {
        $output = Chicle-Style -Dim "hello"
        $expected = Get-Content "$script:FIXTURES/style_dim.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "applies cyan" {
        $output = Chicle-Style -Cyan "hello"
        $expected = Get-Content "$script:FIXTURES/style_cyan.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "applies green" {
        $output = Chicle-Style -Green "hello"
        $expected = Get-Content "$script:FIXTURES/style_green.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "applies yellow" {
        $output = Chicle-Style -Yellow "hello"
        $expected = Get-Content "$script:FIXTURES/style_yellow.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "applies red" {
        $output = Chicle-Style -Red "hello"
        $expected = Get-Content "$script:FIXTURES/style_red.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "combines bold and cyan" {
        $output = Chicle-Style -Bold -Cyan "hello"
        $expected = Get-Content "$script:FIXTURES/style_bold_cyan.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "handles empty text" {
        $output = Chicle-Style -Bold ""
        $expected = Get-Content "$script:FIXTURES/style_bold_empty.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "handles text only (no flags)" {
        $output = Chicle-Style "plain"
        $expected = Get-Content "$script:FIXTURES/style_plain.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "combines bold, dim, and red" {
        $output = Chicle-Style -Bold -Dim -Red "alert"
        $expected = Get-Content "$script:FIXTURES/style_bold_dim_red.golden" -Raw
        $output | Should -BeExactly $expected
    }
}

Describe "Chicle-Log" {
    It "logs info" {
        $output = Chicle-Log -Info "test"
        $expected = Get-Content "$script:FIXTURES/log_info.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "logs success" {
        $output = Chicle-Log -Success "test"
        $expected = Get-Content "$script:FIXTURES/log_success.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "logs warn" {
        $output = Chicle-Log -Warn "test"
        $expected = Get-Content "$script:FIXTURES/log_warn.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "logs error" {
        $output = Chicle-Log -Error "test"
        $expected = Get-Content "$script:FIXTURES/log_error.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "logs debug" {
        $output = Chicle-Log -Debug "test"
        $expected = Get-Content "$script:FIXTURES/log_debug.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "logs step" {
        $output = Chicle-Log -Step "test"
        $expected = Get-Content "$script:FIXTURES/log_step.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "defaults to plain with no level" {
        $output = Chicle-Log "just text"
        $expected = Get-Content "$script:FIXTURES/log_plain.golden" -Raw
        $output | Should -BeExactly $expected
    }
}

Describe "Chicle-Rule" {
    It "contains line char" {
        $output = Chicle-Rule
        $output | Should -Match ([char]0x2500)  # ─
    }

    It "uses custom char" {
        $output = Chicle-Rule -Char "="
        $output | Should -Match "="
    }
}

Describe "Chicle-Steps" {
    It "renders numeric style" {
        $output = Chicle-Steps -Current 2 -Total 5 -Title "Installing"
        $expected = Get-Content "$script:FIXTURES/steps_numeric.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "renders dots style" {
        $output = Chicle-Steps -Current 2 -Total 5 -Title "Installing" -Style dots
        $expected = Get-Content "$script:FIXTURES/steps_dots.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "renders progress style" {
        $output = Chicle-Steps -Current 3 -Total 5 -Title "Installing" -Style progress
        $expected = Get-Content "$script:FIXTURES/steps_progress.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "renders progress at 100%" {
        $output = Chicle-Steps -Current 5 -Total 5 -Title "Done" -Style progress
        $expected = Get-Content "$script:FIXTURES/steps_progress_full.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "renders 1 of 1" {
        $output = Chicle-Steps -Current 1 -Total 1 -Title "Only step"
        $expected = Get-Content "$script:FIXTURES/steps_one_of_one.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "throws on total 0" {
        { Chicle-Steps -Current 1 -Total 0 } | Should -Throw
    }

    It "renders dots 0/3" {
        $output = Chicle-Steps -Current 0 -Total 3 -Style dots
        $expected = Get-Content "$script:FIXTURES/steps_dots_zero.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "renders dots 3/3" {
        $output = Chicle-Steps -Current 3 -Total 3 -Style dots
        $expected = Get-Content "$script:FIXTURES/steps_dots_full.golden" -Raw
        $output | Should -BeExactly $expected
    }
}

Describe "Chicle-Table" {
    It "renders basic box style" {
        $output = Chicle-Table -Header "Name,Value" -Rows "foo,bar", "baz,qux"
        $expected = Get-Content "$script:FIXTURES/table_basic_box.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "renders without header" {
        $output = Chicle-Table -Rows "a,b", "c,d"
        $expected = Get-Content "$script:FIXTURES/table_no_header.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "renders simple style" {
        $output = Chicle-Table -Style simple -Header "A,B" -Rows "1,2"
        $expected = Get-Content "$script:FIXTURES/table_simple.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "uses custom separator" {
        $output = Chicle-Table -Sep "|" -Header "A|B" -Rows "1|2"
        $expected = Get-Content "$script:FIXTURES/table_custom_sep.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "aligns columns" {
        $output = Chicle-Table -Header "X,Y" -Rows "hello,w", "hi,world"
        $expected = Get-Content "$script:FIXTURES/table_alignment.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "renders three columns" {
        $output = Chicle-Table -Header "Package,Version,Status" -Rows "chicle,1.0,ok", "bash,5.2,ok"
        $expected = Get-Content "$script:FIXTURES/table_three_cols.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "handles fewer cols than header" {
        $output = Chicle-Table -Header "A,B,C" -Rows "1,2"
        $expected = Get-Content "$script:FIXTURES/table_fewer_cols.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "renders header-only table" {
        $output = Chicle-Table -Header "Name,Value"
        $expected = Get-Content "$script:FIXTURES/table_header_only.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "renders single column" {
        $output = Chicle-Table -Header "Name" -Rows "alice", "bob"
        $expected = Get-Content "$script:FIXTURES/table_single_col.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "accepts pipeline input" {
        $output = "foo,bar", "baz,qux" | Chicle-Table -Header "Name,Value"
        $expected = Get-Content "$script:FIXTURES/table_stdin.golden" -Raw
        $output | Should -BeExactly $expected
    }

    It "throws on empty input" {
        { Chicle-Table } | Should -Throw
    }
}

Describe "Chicle-Progress" {
    # Progress uses Write-Host, so we test via mock
    It "calls Write-Host with correct bar at 50%" {
        Mock Write-Host {}
        Chicle-Progress -Percent 50 -Title "Test" -Width 10
        Should -Invoke Write-Host -ParameterFilter {
            $Object -match "$([char]0x2588){5}" -and $Object -match "$([char]0x2591){5}"
        }
    }

    It "calls Write-Host with full bar at 100%" {
        Mock Write-Host {}
        Chicle-Progress -Percent 100 -Title "Test" -Width 10
        Should -Invoke Write-Host -ParameterFilter {
            $Object -match "$([char]0x2588){10}" -and $Object -match "100%"
        }
    }

    It "clamps above 100" {
        Mock Write-Host {}
        Chicle-Progress -Percent 150 -Width 10
        Should -Invoke Write-Host -ParameterFilter {
            $Object -match "100%"
        }
    }

    It "clamps below 0" {
        Mock Write-Host {}
        Chicle-Progress -Percent -10 -Width 10
        Should -Invoke Write-Host -ParameterFilter {
            $Object -match "  0%"
        }
    }
}
