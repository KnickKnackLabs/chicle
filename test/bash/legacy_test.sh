#!/usr/bin/env bash
# chicle test suite
# Requires: expect (for interactive tests)

# shellcheck disable=SC2015  # A && B || C pattern is intentional for test assertions
# shellcheck source=chicle.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/chicle.sh"

PASS=0
FAIL=0

pass() {
  echo "  ✓ $1"
  ((++PASS))
}

fail() {
  echo "  ✗ $1"
  echo "    Expected: $2"
  echo "    Got:      $3"
  ((++FAIL))
}

# Strip ANSI escape codes and carriage returns from expect output
clean_output() {
  perl -pe 's/\e\[[0-9;?]*[a-zA-Z]//g' | tr -d '\r'
}

# ============================================================================
# Non-interactive tests (output capture)
# ============================================================================

echo "Testing chicle_style..."

output=$(chicle_style --bold "hello")
expected=$'\033[1mhello\033[0m'
[[ "$output" == "$expected" ]] && pass "--bold" || fail "--bold" "$expected" "$output"

output=$(chicle_style --dim "hello")
expected=$'\033[2mhello\033[0m'
[[ "$output" == "$expected" ]] && pass "--dim" || fail "--dim" "$expected" "$output"

output=$(chicle_style --cyan "hello")
expected=$'\033[36mhello\033[0m'
[[ "$output" == "$expected" ]] && pass "--cyan" || fail "--cyan" "$expected" "$output"

output=$(chicle_style --green "hello")
expected=$'\033[32mhello\033[0m'
[[ "$output" == "$expected" ]] && pass "--green" || fail "--green" "$expected" "$output"

output=$(chicle_style --yellow "hello")
expected=$'\033[33mhello\033[0m'
[[ "$output" == "$expected" ]] && pass "--yellow" || fail "--yellow" "$expected" "$output"

output=$(chicle_style --red "hello")
expected=$'\033[31mhello\033[0m'
[[ "$output" == "$expected" ]] && pass "--red" || fail "--red" "$expected" "$output"

output=$(chicle_style --bold --cyan "hello")
expected=$'\033[1m\033[36mhello\033[0m'
[[ "$output" == "$expected" ]] && pass "--bold --cyan" || fail "--bold --cyan" "$expected" "$output"


echo "Testing chicle_rule..."

# Mock tput cols to return 10
output=$(COLUMNS=10 chicle_rule 2>/dev/null || chicle_rule)
# chicle_rule uses tput cols, so we check it contains the right char
[[ "$output" == *"─"* ]] && pass "contains line char" || fail "contains line char" "─" "$output"

output=$(chicle_rule --char "=")
[[ "$output" == *"="* ]] && pass "--char =" || fail "--char =" "=" "$output"


echo "Testing chicle_log..."

output=$(chicle_log --info "test")
[[ "$output" == *"ℹ"*"test"* ]] && pass "--info" || fail "--info" "ℹ test" "$output"

output=$(chicle_log --success "test")
[[ "$output" == *"✓"*"test"* ]] && pass "--success" || fail "--success" "✓ test" "$output"

output=$(chicle_log --warn "test")
[[ "$output" == *"⚠"*"test"* ]] && pass "--warn" || fail "--warn" "⚠ test" "$output"

output=$(chicle_log --error "test")
[[ "$output" == *"✗"*"test"* ]] && pass "--error" || fail "--error" "✗ test" "$output"

output=$(chicle_log --debug "test")
[[ "$output" == *"·"*"test"* ]] && pass "--debug" || fail "--debug" "· test" "$output"

output=$(chicle_log --step "test")
[[ "$output" == *"→"*"test"* ]] && pass "--step" || fail "--step" "→ test" "$output"


echo "Testing chicle_steps..."

output=$(chicle_steps --current 2 --total 5 --title "Installing")
[[ "$output" == *"[2/5]"*"Installing"* ]] && pass "numeric style" || fail "numeric style" "[2/5] Installing" "$output"

output=$(chicle_steps --current 2 --total 5 --title "Installing" --style dots)
[[ "$output" == *"● ●"*"○"*"Installing"* ]] && pass "dots style" || fail "dots style" "● ● ○ Installing" "$output"

output=$(chicle_steps --current 3 --total 5 --title "Installing" --style progress)
[[ "$output" == *"███"*"░░"*"Installing"* ]] && pass "progress style" || fail "progress style" "[███░░] Installing" "$output"

output=$(chicle_steps --current 5 --total 5 --title "Done" --style progress)
[[ "$output" == *"█████"* ]] && pass "progress 100%" || fail "progress 100%" "[█████]" "$output"


echo "Testing chicle_progress..."

output=$(chicle_progress --percent 50 --title "Test" --width 10)
[[ "$output" == *"█████"*"░░░░░"* ]] && pass "--percent 50" || fail "--percent 50" "█████░░░░░" "$output"

output=$(chicle_progress --percent 100 --title "Test" --width 10)
[[ "$output" == *"██████████"*"100%"* ]] && pass "--percent 100" || fail "--percent 100" "██████████ 100%" "$output"

output=$(chicle_progress --current 3 --total 10 --title "Test" --width 10)
[[ "$output" == *"███"*"░░░░░░░"*"30%"* ]] && pass "--current/--total" || fail "--current/--total" "███░░░░░░░ 30%" "$output"

output=$(chicle_progress --percent 0 --title "Test" --width 10)
[[ "$output" == *"░░░░░░░░░░"*"0%"* ]] && pass "--percent 0" || fail "--percent 0" "░░░░░░░░░░ 0%" "$output"


echo "Testing chicle_spin..."

# Test: successful command shows checkmark
output=$(chicle_spin --title "Working" -- true 2>&1)
[[ "$output" == *"✓"*"Working"* ]] && pass "success shows ✓" || fail "success shows ✓" "✓ Working" "$output"

# Test: successful command returns 0
if chicle_spin --title "OK" -- true >/dev/null 2>&1; then
  pass "success returns 0"
else
  fail "success returns 0" "0" "non-zero"
fi

# Test: failed command shows ✗
output=$(chicle_spin --title "Failing" -- false 2>&1 || true)
[[ "$output" == *"✗"*"Failing"* ]] && pass "failure shows ✗" || fail "failure shows ✗" "✗ Failing" "$output"

# Test: failed command returns non-zero
exit_code=0
chicle_spin --title "Fail" -- false >/dev/null 2>&1 || exit_code=$?
[[ $exit_code -ne 0 ]] && pass "failure returns non-zero" || fail "failure returns non-zero" "non-zero" "0"

# Test: spin without title
output=$(chicle_spin -- true 2>&1)
[[ "$output" == *"✓"* ]] && pass "no title" || fail "no title" "✓" "$output"

# Test: preserves command exit code
exit_code=0
chicle_spin -- bash -c "exit 42" >/dev/null 2>&1 || exit_code=$?
[[ "$exit_code" -eq 42 ]] && pass "preserves exit code 42" || fail "preserves exit code 42" "42" "$exit_code"


echo "Testing chicle_table..."

# Test: basic table with header (box style)
output=$(chicle_table --header "Name,Value" "foo,bar" "baz,qux")
[[ "$output" == *"┌"* && "$output" == *"┘"* ]] && pass "box style borders" || fail "box style borders" "box borders" "$output"
[[ "$output" == *"Name"* && "$output" == *"Value"* ]] && pass "header content" || fail "header content" "Name Value" "$output"
[[ "$output" == *"foo"* && "$output" == *"bar"* ]] && pass "row content" || fail "row content" "foo bar" "$output"
[[ "$output" == *"├"* && "$output" == *"┤"* ]] && pass "header separator" || fail "header separator" "├─┤" "$output"

# Test: table without header
output=$(chicle_table "a,b" "c,d")
[[ "$output" == *"a"* && "$output" == *"b"* ]] && pass "no header - data present" || fail "no header - data present" "a b" "$output"
# Should not contain header separator
[[ "$output" != *"├"* ]] && pass "no header - no separator" || fail "no header - no separator" "no ├" "$output"

# Test: simple style
output=$(chicle_table --style simple --header "A,B" "1,2")
[[ "$output" != *"┌"* && "$output" == *"A"* && "$output" == *"1"* ]] && pass "simple style" || fail "simple style" "no box chars" "$output"
[[ "$output" == *"─"* ]] && pass "simple style separator" || fail "simple style separator" "─" "$output"

# Test: custom separator
output=$(chicle_table --sep "|" --header "A|B" "1|2")
[[ "$output" == *"A"* && "$output" == *"B"* && "$output" == *"1"* && "$output" == *"2"* ]] && pass "custom separator" || fail "custom separator" "A B 1 2" "$output"

# Test: stdin pipe support
output=$(printf "foo,bar\nbaz,qux\n" | chicle_table --header "Name,Value")
[[ "$output" == *"foo"* && "$output" == *"baz"* ]] && pass "stdin pipe" || fail "stdin pipe" "foo baz" "$output"

# Test: column width alignment (wider data should expand column)
output=$(chicle_table --header "X,Y" "hello,w" "hi,world")
[[ "$output" == *"hello"* && "$output" == *"world"* ]] && pass "column alignment" || fail "column alignment" "hello world" "$output"

# Test: empty input returns error
if chicle_table 2>/dev/null; then
  fail "empty input returns error" "non-zero exit" "0"
else
  pass "empty input returns error"
fi

# Test: three columns
output=$(chicle_table --header "Package,Version,Status" "chicle,1.0,ok" "bash,5.2,ok")
[[ "$output" == *"Package"* && "$output" == *"Version"* && "$output" == *"Status"* ]] && pass "three columns header" || fail "three columns header" "3 cols" "$output"
[[ "$output" == *"chicle"* && "$output" == *"1.0"* && "$output" == *"ok"* ]] && pass "three columns data" || fail "three columns data" "3 cols data" "$output"

# Test: row with fewer columns than header (uneven data)
output=$(chicle_table --header "A,B,C" "1,2")
[[ "$output" == *"A"* && "$output" == *"C"* && "$output" == *"1"* ]] && pass "fewer cols than header" || fail "fewer cols than header" "A C 1" "$output"

# Test: header-only table (no data rows)
output=$(chicle_table --header "Name,Value")
[[ "$output" == *"Name"* && "$output" == *"┌"* && "$output" == *"┘"* ]] && pass "header-only table" || fail "header-only table" "Name with borders" "$output"


# ============================================================================
# Edge case tests
# ============================================================================

echo "Testing edge cases..."

# chicle_style: empty text
output=$(chicle_style --bold "")
expected=$'\033[1m\033[0m'
[[ "$output" == "$expected" ]] && pass "style: empty text" || fail "style: empty text" "$expected" "$output"

# chicle_style: text only (no flags)
output=$(chicle_style "plain")
expected=$'plain\033[0m'
[[ "$output" == "$expected" ]] && pass "style: text only" || fail "style: text only" "$expected" "$output"

# chicle_style: all formatting combined
output=$(chicle_style --bold --dim --red "alert")
[[ "$output" == *$'\033[1m'*$'\033[2m'*$'\033[31m'*"alert"* ]] && pass "style: bold+dim+red" || fail "style: bold+dim+red" "combined formatting" "$output"

# chicle_log: no level defaults to plain
output=$(chicle_log "just text")
[[ "$output" == "just text" ]] && pass "log: no level" || fail "log: no level" "just text" "$output"

# chicle_steps: total 0 returns error
if chicle_steps --current 1 --total 0 2>/dev/null; then
  fail "steps: total 0 returns error" "non-zero exit" "0"
else
  pass "steps: total 0 returns error"
fi

# chicle_steps: step 1 of 1
output=$(chicle_steps --current 1 --total 1 --title "Only step")
[[ "$output" == *"[1/1]"*"Only step"* ]] && pass "steps: 1 of 1" || fail "steps: 1 of 1" "[1/1] Only step" "$output"

# chicle_progress: percent clamped above 100
output=$(chicle_progress --percent 150 --width 10)
[[ "$output" == *"100%"* ]] && pass "progress: clamp >100" || fail "progress: clamp >100" "100%" "$output"

# chicle_progress: negative percent clamped to 0
output=$(chicle_progress --percent -10 --width 10)
[[ "$output" == *"0%"* ]] && pass "progress: clamp <0" || fail "progress: clamp <0" "0%" "$output"

# chicle_choose: no options returns error
# shellcheck disable=SC2119  # intentionally calling with no args to test error case
if chicle_choose 2>/dev/null; then
  fail "choose: no options returns error" "non-zero exit" "0"
else
  pass "choose: no options returns error"
fi

# chicle_table: single column
output=$(chicle_table --header "Name" "alice" "bob")
[[ "$output" == *"alice"* && "$output" == *"bob"* ]] && pass "table: single column" || fail "table: single column" "alice bob" "$output"

# chicle_rule: default char is ─
output=$(chicle_rule)
# Should only contain ─ and newline
cleaned=$(echo "$output" | tr -d '─' | tr -d '\n')
[[ -z "$cleaned" ]] && pass "rule: default only ─" || fail "rule: default only ─" "only ─ chars" "$cleaned"

# chicle_steps: dots style at boundaries (0 of N and N of N)
output=$(chicle_steps --current 0 --total 3 --style dots)
[[ "$output" == *"○ ○ ○"* ]] && pass "steps: dots 0/3" || fail "steps: dots 0/3" "○ ○ ○" "$output"

output=$(chicle_steps --current 3 --total 3 --style dots)
[[ "$output" == *"● ● ●"* ]] && pass "steps: dots 3/3" || fail "steps: dots 3/3" "● ● ●" "$output"


# ============================================================================
# Interactive tests (expect)
# ============================================================================

if command -v expect &>/dev/null && command -v perl &>/dev/null; then
  echo "Testing chicle_choose (expect)..."

  # Test: select first item (just press enter)
  output=$(expect -c '
    spawn bash -c "source '"$SCRIPT_DIR"'/chicle.sh; chicle_choose A B C"
    expect "❯"
    send "\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [[ "$output" == "A" ]] && pass "select first (enter)" || fail "select first (enter)" "A" "$output"

  # Test: select second item (down + enter)
  output=$(expect -c '
    spawn bash -c "source '"$SCRIPT_DIR"'/chicle.sh; chicle_choose A B C"
    expect "❯"
    send "\033\[B\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [[ "$output" == "B" ]] && pass "select second (down+enter)" || fail "select second (down+enter)" "B" "$output"

  # Test: select third item (down + down + enter)
  output=$(expect -c '
    spawn bash -c "source '"$SCRIPT_DIR"'/chicle.sh; chicle_choose A B C"
    expect "❯"
    send "\033\[B\033\[B\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [[ "$output" == "C" ]] && pass "select third (down+down+enter)" || fail "select third (down+down+enter)" "C" "$output"


  echo "Testing chicle_choose --multi (expect)..."

  # Test: multi-select first two items (space, down, space, enter)
  output=$(expect -c '
    spawn bash -c "source '"$SCRIPT_DIR"'/chicle.sh; chicle_choose --multi A B C"
    expect "❯"
    send " \033\[B \r"
    expect eof
  ' 2>&1 | clean_output | grep -E "^(A|B|C)$" | tr '\n' ',')
  [[ "$output" == "A,B," ]] && pass "multi-select A,B" || fail "multi-select A,B" "A,B," "$output"


  echo "Testing chicle_confirm (expect)..."

  # Test: confirm yes
  output=$(expect -c '
    spawn bash -c "source '"$SCRIPT_DIR"'/chicle.sh; chicle_confirm \"Continue?\" && echo YES || echo NO"
    expect "?"
    send "y\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [[ "$output" == "YES" ]] && pass "confirm y -> yes" || fail "confirm y -> yes" "YES" "$output"

  # Test: confirm no
  output=$(expect -c '
    spawn bash -c "source '"$SCRIPT_DIR"'/chicle.sh; chicle_confirm \"Continue?\" && echo YES || echo NO"
    expect "?"
    send "n\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [[ "$output" == "NO" ]] && pass "confirm n -> no" || fail "confirm n -> no" "NO" "$output"


  echo "Testing chicle_input (expect)..."

  # Test: basic input
  output=$(expect -c '
    spawn bash -c "source '"$SCRIPT_DIR"'/chicle.sh; chicle_input --prompt \"Name: \""
    expect ":"
    send "alice\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [[ "$output" == "alice" ]] && pass "basic input" || fail "basic input" "alice" "$output"

  # Test: password input (value captured even though not displayed)
  output=$(expect -c '
    spawn bash -c "source '"$SCRIPT_DIR"'/chicle.sh; chicle_input --password --prompt \"Pass: \""
    expect ":"
    send "secret\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [[ "$output" == "secret" ]] && pass "password input" || fail "password input" "secret" "$output"

else
  echo "Skipping interactive tests (expect or perl not found)"
fi


# ============================================================================
# Zsh interactive tests (expect)
# ============================================================================

if command -v expect &>/dev/null && command -v perl &>/dev/null && command -v zsh &>/dev/null; then
  echo "Testing chicle_choose in zsh (expect)..."

  # Test: select second item (down + enter) in zsh
  output=$(expect -c '
    spawn zsh -c "source '"$SCRIPT_DIR"'/chicle.sh; chicle_choose A B C"
    expect "❯"
    send "\033\[B\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [[ "$output" == "B" ]] && pass "zsh: select second (down+enter)" || fail "zsh: select second (down+enter)" "B" "$output"


  echo "Testing chicle_choose --multi in zsh (expect)..."

  # Test: multi-select in zsh
  output=$(expect -c '
    spawn zsh -c "source '"$SCRIPT_DIR"'/chicle.sh; chicle_choose --multi A B C"
    expect "❯"
    send " \033\[B \r"
    expect eof
  ' 2>&1 | clean_output | grep -E "^(A|B|C)$" | tr '\n' ',')
  [[ "$output" == "A,B," ]] && pass "zsh: multi-select A,B" || fail "zsh: multi-select A,B" "A,B," "$output"


  echo "Testing chicle_input in zsh (expect)..."

  # Test: password input in zsh
  output=$(expect -c '
    spawn zsh -c "source '"$SCRIPT_DIR"'/chicle.sh; chicle_input --password --prompt \"Pass: \""
    expect ":"
    send "secret\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [[ "$output" == "secret" ]] && pass "zsh: password input" || fail "zsh: password input" "secret" "$output"

else
  echo "Skipping zsh tests (expect, perl, or zsh not found)"
fi


# ============================================================================
# Summary
# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results: $PASS passed, $FAIL failed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

[[ $FAIL -eq 0 ]] && exit 0 || exit 1
