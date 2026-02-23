#!/usr/bin/env bats
# chicle bash test suite (BATS)
# Requires: expect + perl for interactive tests, zsh for zsh compat tests

FIXTURES="$BATS_TEST_DIRNAME/../fixtures"

setup() {
  source "$BATS_TEST_DIRNAME/../../chicle.sh"
}

# Helper: strip ANSI escape codes and carriage returns
clean_output() {
  perl -pe 's/\e\[[0-9;?]*[a-zA-Z]//g' | tr -d '\r'
}

# ============================================================================
# chicle_style — golden fixture tests
# ============================================================================

@test "style: --bold" {
  run chicle_style --bold "hello"
  expected=$(<"$FIXTURES/style_bold.golden")
  [ "$output" = "$expected" ]
}

@test "style: --dim" {
  run chicle_style --dim "hello"
  expected=$(<"$FIXTURES/style_dim.golden")
  [ "$output" = "$expected" ]
}

@test "style: --cyan" {
  run chicle_style --cyan "hello"
  expected=$(<"$FIXTURES/style_cyan.golden")
  [ "$output" = "$expected" ]
}

@test "style: --green" {
  run chicle_style --green "hello"
  expected=$(<"$FIXTURES/style_green.golden")
  [ "$output" = "$expected" ]
}

@test "style: --yellow" {
  run chicle_style --yellow "hello"
  expected=$(<"$FIXTURES/style_yellow.golden")
  [ "$output" = "$expected" ]
}

@test "style: --red" {
  run chicle_style --red "hello"
  expected=$(<"$FIXTURES/style_red.golden")
  [ "$output" = "$expected" ]
}

@test "style: --bold --cyan" {
  run chicle_style --bold --cyan "hello"
  expected=$(<"$FIXTURES/style_bold_cyan.golden")
  [ "$output" = "$expected" ]
}

@test "style: empty text" {
  run chicle_style --bold ""
  expected=$(<"$FIXTURES/style_bold_empty.golden")
  [ "$output" = "$expected" ]
}

@test "style: text only (no flags)" {
  run chicle_style "plain"
  expected=$(<"$FIXTURES/style_plain.golden")
  [ "$output" = "$expected" ]
}

@test "style: --bold --dim --red" {
  run chicle_style --bold --dim --red "alert"
  expected=$(<"$FIXTURES/style_bold_dim_red.golden")
  [ "$output" = "$expected" ]
}

# ============================================================================
# chicle_log — golden fixture tests
# ============================================================================

@test "log: --info" {
  run chicle_log --info "test"
  expected=$(<"$FIXTURES/log_info.golden")
  [ "$output" = "$expected" ]
}

@test "log: --success" {
  run chicle_log --success "test"
  expected=$(<"$FIXTURES/log_success.golden")
  [ "$output" = "$expected" ]
}

@test "log: --warn" {
  run chicle_log --warn "test"
  expected=$(<"$FIXTURES/log_warn.golden")
  [ "$output" = "$expected" ]
}

@test "log: --error" {
  run chicle_log --error "test"
  expected=$(<"$FIXTURES/log_error.golden")
  [ "$output" = "$expected" ]
}

@test "log: --debug" {
  run chicle_log --debug "test"
  expected=$(<"$FIXTURES/log_debug.golden")
  [ "$output" = "$expected" ]
}

@test "log: --step" {
  run chicle_log --step "test"
  expected=$(<"$FIXTURES/log_step.golden")
  [ "$output" = "$expected" ]
}

@test "log: no level defaults to plain" {
  run chicle_log "just text"
  expected=$(<"$FIXTURES/log_plain.golden")
  [ "$output" = "$expected" ]
}

# ============================================================================
# chicle_rule
# ============================================================================

@test "rule: contains line char" {
  run chicle_rule
  [[ "$output" == *"─"* ]]
}

@test "rule: --char =" {
  run chicle_rule --char "="
  [[ "$output" == *"="* ]]
}

@test "rule: default only contains ─" {
  run chicle_rule
  cleaned=$(echo "$output" | tr -d '─' | tr -d '\n')
  [ -z "$cleaned" ]
}

# ============================================================================
# chicle_steps — golden fixture tests
# ============================================================================

@test "steps: numeric style" {
  run chicle_steps --current 2 --total 5 --title "Installing"
  expected=$(<"$FIXTURES/steps_numeric.golden")
  [ "$output" = "$expected" ]
}

@test "steps: dots style" {
  run chicle_steps --current 2 --total 5 --title "Installing" --style dots
  expected=$(<"$FIXTURES/steps_dots.golden")
  [ "$output" = "$expected" ]
}

@test "steps: progress style" {
  run chicle_steps --current 3 --total 5 --title "Installing" --style progress
  expected=$(<"$FIXTURES/steps_progress.golden")
  [ "$output" = "$expected" ]
}

@test "steps: progress 100%" {
  run chicle_steps --current 5 --total 5 --title "Done" --style progress
  expected=$(<"$FIXTURES/steps_progress_full.golden")
  [ "$output" = "$expected" ]
}

@test "steps: 1 of 1" {
  run chicle_steps --current 1 --total 1 --title "Only step"
  expected=$(<"$FIXTURES/steps_one_of_one.golden")
  [ "$output" = "$expected" ]
}

@test "steps: total 0 returns error" {
  run chicle_steps --current 1 --total 0
  [ "$status" -ne 0 ]
}

@test "steps: dots 0/3" {
  run chicle_steps --current 0 --total 3 --style dots
  expected=$(<"$FIXTURES/steps_dots_zero.golden")
  [ "$output" = "$expected" ]
}

@test "steps: dots 3/3" {
  run chicle_steps --current 3 --total 3 --style dots
  expected=$(<"$FIXTURES/steps_dots_full.golden")
  [ "$output" = "$expected" ]
}

# ============================================================================
# chicle_progress — golden fixture tests
# ============================================================================

@test "progress: --percent 50" {
  run chicle_progress --percent 50 --title "Test" --width 10
  expected=$(<"$FIXTURES/progress_50.golden")
  [ "$output" = "$expected" ]
}

@test "progress: --percent 100" {
  run chicle_progress --percent 100 --title "Test" --width 10
  expected=$(<"$FIXTURES/progress_100.golden")
  [ "$output" = "$expected" ]
}

@test "progress: --current/--total" {
  run chicle_progress --current 3 --total 10 --title "Test" --width 10
  expected=$(<"$FIXTURES/progress_current_total.golden")
  [ "$output" = "$expected" ]
}

@test "progress: --percent 0" {
  run chicle_progress --percent 0 --title "Test" --width 10
  expected=$(<"$FIXTURES/progress_0.golden")
  [ "$output" = "$expected" ]
}

@test "progress: clamp >100" {
  run chicle_progress --percent 150 --width 10
  expected=$(<"$FIXTURES/progress_clamp_above.golden")
  [ "$output" = "$expected" ]
}

@test "progress: clamp <0" {
  run chicle_progress --percent -10 --width 10
  expected=$(<"$FIXTURES/progress_clamp_below.golden")
  [ "$output" = "$expected" ]
}

# ============================================================================
# chicle_spin
# ============================================================================

@test "spin: success shows checkmark" {
  run chicle_spin --title "Working" -- true
  [[ "$output" == *"✓"*"Working"* ]]
}

@test "spin: success returns 0" {
  chicle_spin --title "OK" -- true >/dev/null 2>&1
}

@test "spin: failure shows X" {
  run chicle_spin --title "Failing" -- false
  [ "$status" -ne 0 ]
  [[ "$output" == *"✗"*"Failing"* ]]
}

@test "spin: failure returns non-zero" {
  run chicle_spin --title "Fail" -- false
  [ "$status" -ne 0 ]
}

@test "spin: no title" {
  run chicle_spin -- true
  [[ "$output" == *"✓"* ]]
}

@test "spin: preserves exit code 42" {
  run chicle_spin -- bash -c "exit 42"
  [ "$status" -eq 42 ]
}

# ============================================================================
# chicle_table — golden fixture tests
# ============================================================================

@test "table: basic box style" {
  run chicle_table --header "Name,Value" "foo,bar" "baz,qux"
  expected=$(<"$FIXTURES/table_basic_box.golden")
  [ "$output" = "$expected" ]
}

@test "table: no header" {
  run chicle_table "a,b" "c,d"
  expected=$(<"$FIXTURES/table_no_header.golden")
  [ "$output" = "$expected" ]
}

@test "table: simple style" {
  run chicle_table --style simple --header "A,B" "1,2"
  expected=$(<"$FIXTURES/table_simple.golden")
  [ "$output" = "$expected" ]
}

@test "table: custom separator" {
  run chicle_table --sep "|" --header "A|B" "1|2"
  expected=$(<"$FIXTURES/table_custom_sep.golden")
  [ "$output" = "$expected" ]
}

@test "table: column alignment" {
  run chicle_table --header "X,Y" "hello,w" "hi,world"
  expected=$(<"$FIXTURES/table_alignment.golden")
  [ "$output" = "$expected" ]
}

@test "table: three columns" {
  run chicle_table --header "Package,Version,Status" "chicle,1.0,ok" "bash,5.2,ok"
  expected=$(<"$FIXTURES/table_three_cols.golden")
  [ "$output" = "$expected" ]
}

@test "table: fewer cols than header" {
  run chicle_table --header "A,B,C" "1,2"
  expected=$(<"$FIXTURES/table_fewer_cols.golden")
  [ "$output" = "$expected" ]
}

@test "table: header-only" {
  run chicle_table --header "Name,Value"
  expected=$(<"$FIXTURES/table_header_only.golden")
  [ "$output" = "$expected" ]
}

@test "table: single column" {
  run chicle_table --header "Name" "alice" "bob"
  expected=$(<"$FIXTURES/table_single_col.golden")
  [ "$output" = "$expected" ]
}

@test "table: stdin pipe" {
  run bash -c 'source '"$BATS_TEST_DIRNAME"'/../../chicle.sh; printf "foo,bar\nbaz,qux\n" | chicle_table --header "Name,Value"'
  expected=$(<"$FIXTURES/table_stdin.golden")
  [ "$output" = "$expected" ]
}

@test "table: empty input returns error" {
  run chicle_table
  [ "$status" -ne 0 ]
}

# ============================================================================
# chicle_choose — error cases (non-interactive)
# ============================================================================

@test "choose: no options returns error" {
  run chicle_choose
  [ "$status" -ne 0 ]
}

# ============================================================================
# Interactive tests (expect) — chicle_choose
# ============================================================================

expect_available() {
  command -v expect &>/dev/null && command -v perl &>/dev/null
}

@test "choose: select first (enter)" {
  if ! expect_available; then skip "expect or perl not found"; fi
  output=$(expect -c '
    spawn bash -c "source '"$BATS_TEST_DIRNAME"'/../../chicle.sh; chicle_choose A B C"
    expect "❯"
    send "\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [ "$output" = "A" ]
}

@test "choose: select second (down+enter)" {
  if ! expect_available; then skip "expect or perl not found"; fi
  output=$(expect -c '
    spawn bash -c "source '"$BATS_TEST_DIRNAME"'/../../chicle.sh; chicle_choose A B C"
    expect "❯"
    send "\033\[B\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [ "$output" = "B" ]
}

@test "choose: select third (down+down+enter)" {
  if ! expect_available; then skip "expect or perl not found"; fi
  output=$(expect -c '
    spawn bash -c "source '"$BATS_TEST_DIRNAME"'/../../chicle.sh; chicle_choose A B C"
    expect "❯"
    send "\033\[B\033\[B\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [ "$output" = "C" ]
}

@test "choose: multi-select A,B" {
  if ! expect_available; then skip "expect or perl not found"; fi
  output=$(expect -c '
    spawn bash -c "source '"$BATS_TEST_DIRNAME"'/../../chicle.sh; chicle_choose --multi A B C"
    expect "❯"
    send " \033\[B \r"
    expect eof
  ' 2>&1 | clean_output | grep -E "^(A|B|C)$" | tr '\n' ',')
  [ "$output" = "A,B," ]
}

# ============================================================================
# Interactive tests (expect) — chicle_confirm
# ============================================================================

@test "confirm: y -> yes" {
  if ! expect_available; then skip "expect or perl not found"; fi
  output=$(expect -c '
    spawn bash -c "source '"$BATS_TEST_DIRNAME"'/../../chicle.sh; chicle_confirm \"Continue?\" && echo YES || echo NO"
    expect "?"
    send "y\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [ "$output" = "YES" ]
}

@test "confirm: n -> no" {
  if ! expect_available; then skip "expect or perl not found"; fi
  output=$(expect -c '
    spawn bash -c "source '"$BATS_TEST_DIRNAME"'/../../chicle.sh; chicle_confirm \"Continue?\" && echo YES || echo NO"
    expect "?"
    send "n\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [ "$output" = "NO" ]
}

# ============================================================================
# Interactive tests (expect) — chicle_input
# ============================================================================

@test "input: basic input" {
  if ! expect_available; then skip "expect or perl not found"; fi
  output=$(expect -c '
    spawn bash -c "source '"$BATS_TEST_DIRNAME"'/../../chicle.sh; chicle_input --prompt \"Name: \""
    expect ":"
    send "alice\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [ "$output" = "alice" ]
}

@test "input: password input" {
  if ! expect_available; then skip "expect or perl not found"; fi
  output=$(expect -c '
    spawn bash -c "source '"$BATS_TEST_DIRNAME"'/../../chicle.sh; chicle_input --password --prompt \"Pass: \""
    expect ":"
    send "secret\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [ "$output" = "secret" ]
}

# ============================================================================
# Zsh interactive tests (expect)
# ============================================================================

zsh_expect_available() {
  command -v expect &>/dev/null && command -v perl &>/dev/null && command -v zsh &>/dev/null
}

@test "zsh: select second (down+enter)" {
  if ! zsh_expect_available; then skip "expect, perl, or zsh not found"; fi
  output=$(expect -c '
    spawn zsh -c "source '"$BATS_TEST_DIRNAME"'/../../chicle.sh; chicle_choose A B C"
    expect "❯"
    send "\033\[B\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [ "$output" = "B" ]
}

@test "zsh: multi-select A,B" {
  if ! zsh_expect_available; then skip "expect, perl, or zsh not found"; fi
  output=$(expect -c '
    spawn zsh -c "source '"$BATS_TEST_DIRNAME"'/../../chicle.sh; chicle_choose --multi A B C"
    expect "❯"
    send " \033\[B \r"
    expect eof
  ' 2>&1 | clean_output | grep -E "^(A|B|C)$" | tr '\n' ',')
  [ "$output" = "A,B," ]
}

@test "zsh: password input" {
  if ! zsh_expect_available; then skip "expect, perl, or zsh not found"; fi
  output=$(expect -c '
    spawn zsh -c "source '"$BATS_TEST_DIRNAME"'/../../chicle.sh; chicle_input --password --prompt \"Pass: \""
    expect ":"
    send "secret\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [ "$output" = "secret" ]
}
