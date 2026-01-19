#!/usr/bin/env bash
# chicle test suite
# Requires: expect (for interactive tests)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
