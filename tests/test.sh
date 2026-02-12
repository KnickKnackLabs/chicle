#!/usr/bin/env bash
# chicle test suite
# Requires: expect (for interactive tests)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
GOLDEN_DIR="$SCRIPT_DIR/golden"

source "$ROOT_DIR/chicle.sh"
source "$SCRIPT_DIR/helpers.sh"

# Report which shell is running
SHELL_VERSION=$("${BASH:-bash}" --version 2>&1 | head -1)
echo "Testing with: $SHELL_VERSION"
echo ""

# Support --update flag
[[ "${1:-}" == "--update" ]] && UPDATE_GOLDENS=1

# ============================================================================
# Golden file tests (non-interactive)
# ============================================================================

echo "Testing chicle_style..."

# Golden file tests (text content contract)
check_golden "style: bold" \
  "$(chicle_style --bold "hello")" \
  "$GOLDEN_DIR/chicle_style/bold.txt"

check_golden "style: dim" \
  "$(chicle_style --dim "hello")" \
  "$GOLDEN_DIR/chicle_style/dim.txt"

check_golden "style: cyan" \
  "$(chicle_style --cyan "hello")" \
  "$GOLDEN_DIR/chicle_style/cyan.txt"

check_golden "style: green" \
  "$(chicle_style --green "hello")" \
  "$GOLDEN_DIR/chicle_style/green.txt"

check_golden "style: yellow" \
  "$(chicle_style --yellow "hello")" \
  "$GOLDEN_DIR/chicle_style/yellow.txt"

check_golden "style: red" \
  "$(chicle_style --red "hello")" \
  "$GOLDEN_DIR/chicle_style/red.txt"

check_golden "style: bold+cyan" \
  "$(chicle_style --bold --cyan "hello")" \
  "$GOLDEN_DIR/chicle_style/bold-cyan.txt"

# Inline ANSI assertions (verify correct escape codes)
output=$(chicle_style --bold "hello")
expected=$'\033[1mhello\033[0m'
[[ "$output" == "$expected" ]] && pass "style: bold (ansi)" || fail "style: bold (ansi)" "$expected" "$output"

output=$(chicle_style --dim "hello")
expected=$'\033[2mhello\033[0m'
[[ "$output" == "$expected" ]] && pass "style: dim (ansi)" || fail "style: dim (ansi)" "$expected" "$output"

output=$(chicle_style --cyan "hello")
expected=$'\033[36mhello\033[0m'
[[ "$output" == "$expected" ]] && pass "style: cyan (ansi)" || fail "style: cyan (ansi)" "$expected" "$output"

output=$(chicle_style --green "hello")
expected=$'\033[32mhello\033[0m'
[[ "$output" == "$expected" ]] && pass "style: green (ansi)" || fail "style: green (ansi)" "$expected" "$output"

output=$(chicle_style --yellow "hello")
expected=$'\033[33mhello\033[0m'
[[ "$output" == "$expected" ]] && pass "style: yellow (ansi)" || fail "style: yellow (ansi)" "$expected" "$output"

output=$(chicle_style --red "hello")
expected=$'\033[31mhello\033[0m'
[[ "$output" == "$expected" ]] && pass "style: red (ansi)" || fail "style: red (ansi)" "$expected" "$output"

output=$(chicle_style --bold --cyan "hello")
expected=$'\033[1m\033[36mhello\033[0m'
[[ "$output" == "$expected" ]] && pass "style: bold+cyan (ansi)" || fail "style: bold+cyan (ansi)" "$expected" "$output"


echo "Testing chicle_rule..."

check_golden "rule: default" \
  "$(chicle_rule --width 40)" \
  "$GOLDEN_DIR/chicle_rule/default.txt"

check_golden "rule: char =" \
  "$(chicle_rule --char "=" --width 40)" \
  "$GOLDEN_DIR/chicle_rule/char-equals.txt"


echo "Testing chicle_log..."

check_golden "log: info" \
  "$(chicle_log --info "test")" \
  "$GOLDEN_DIR/chicle_log/info.txt"

check_golden "log: success" \
  "$(chicle_log --success "test")" \
  "$GOLDEN_DIR/chicle_log/success.txt"

check_golden "log: warn" \
  "$(chicle_log --warn "test")" \
  "$GOLDEN_DIR/chicle_log/warn.txt"

check_golden "log: error" \
  "$(chicle_log --error "test")" \
  "$GOLDEN_DIR/chicle_log/error.txt"

check_golden "log: debug" \
  "$(chicle_log --debug "test")" \
  "$GOLDEN_DIR/chicle_log/debug.txt"

check_golden "log: step" \
  "$(chicle_log --step "test")" \
  "$GOLDEN_DIR/chicle_log/step.txt"


echo "Testing chicle_steps..."

check_golden "steps: numeric" \
  "$(chicle_steps --current 2 --total 5 --title "Installing")" \
  "$GOLDEN_DIR/chicle_steps/numeric.txt"

check_golden "steps: dots" \
  "$(chicle_steps --current 2 --total 5 --title "Installing" --style dots)" \
  "$GOLDEN_DIR/chicle_steps/dots.txt"

check_golden "steps: progress" \
  "$(chicle_steps --current 3 --total 5 --title "Installing" --style progress)" \
  "$GOLDEN_DIR/chicle_steps/progress.txt"

check_golden "steps: progress 100%" \
  "$(chicle_steps --current 5 --total 5 --title "Done" --style progress)" \
  "$GOLDEN_DIR/chicle_steps/progress-100.txt"


echo "Testing chicle_progress..."

check_golden "progress: 50%" \
  "$(chicle_progress --percent 50 --title "Test" --width 10)" \
  "$GOLDEN_DIR/chicle_progress/percent-50.txt"

check_golden "progress: 100%" \
  "$(chicle_progress --percent 100 --title "Test" --width 10)" \
  "$GOLDEN_DIR/chicle_progress/percent-100.txt"

check_golden "progress: current/total" \
  "$(chicle_progress --current 3 --total 10 --title "Test" --width 10)" \
  "$GOLDEN_DIR/chicle_progress/current-total.txt"

check_golden "progress: 0%" \
  "$(chicle_progress --percent 0 --title "Test" --width 10)" \
  "$GOLDEN_DIR/chicle_progress/percent-0.txt"


# ============================================================================
# Interactive tests (expect)
# ============================================================================

if command -v expect &>/dev/null && command -v perl &>/dev/null; then
  # Reuse strip_ansi for cleaning expect output
  clean_output() {
    strip_ansi
  }

  echo "Testing chicle_choose (expect)..."

  # Test: select first item (just press enter)
  output=$(expect -c '
    spawn bash -c "source '"$ROOT_DIR"'/chicle.sh; chicle_choose A B C"
    expect "❯"
    send "\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [[ "$output" == "A" ]] && pass "choose: first (enter)" || fail "choose: first (enter)" "A" "$output"

  # Test: select second item (down + enter)
  output=$(expect -c '
    spawn bash -c "source '"$ROOT_DIR"'/chicle.sh; chicle_choose A B C"
    expect "❯"
    send "\033\[B\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [[ "$output" == "B" ]] && pass "choose: second (down+enter)" || fail "choose: second (down+enter)" "B" "$output"

  # Test: select third item (down + down + enter)
  output=$(expect -c '
    spawn bash -c "source '"$ROOT_DIR"'/chicle.sh; chicle_choose A B C"
    expect "❯"
    send "\033\[B\033\[B\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [[ "$output" == "C" ]] && pass "choose: third (down+down+enter)" || fail "choose: third (down+down+enter)" "C" "$output"


  echo "Testing chicle_choose --multi (expect)..."

  # Test: multi-select first two items (space, down, space, enter)
  output=$(expect -c '
    spawn bash -c "source '"$ROOT_DIR"'/chicle.sh; chicle_choose --multi A B C"
    expect "❯"
    send " \033\[B \r"
    expect eof
  ' 2>&1 | clean_output | grep -E "^(A|B|C)$" | tr '\n' ',')
  [[ "$output" == "A,B," ]] && pass "choose: multi A,B" || fail "choose: multi A,B" "A,B," "$output"


  echo "Testing chicle_confirm (expect)..."

  # Test: confirm yes
  output=$(expect -c '
    spawn bash -c "source '"$ROOT_DIR"'/chicle.sh; chicle_confirm \"Continue?\" && echo YES || echo NO"
    expect "?"
    send "y\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [[ "$output" == "YES" ]] && pass "confirm: y -> yes" || fail "confirm: y -> yes" "YES" "$output"

  # Test: confirm no
  output=$(expect -c '
    spawn bash -c "source '"$ROOT_DIR"'/chicle.sh; chicle_confirm \"Continue?\" && echo YES || echo NO"
    expect "?"
    send "n\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [[ "$output" == "NO" ]] && pass "confirm: n -> no" || fail "confirm: n -> no" "NO" "$output"


  echo "Testing chicle_input (expect)..."

  # Test: basic input
  output=$(expect -c '
    spawn bash -c "source '"$ROOT_DIR"'/chicle.sh; chicle_input --prompt \"Name: \""
    expect ":"
    send "alice\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [[ "$output" == "alice" ]] && pass "input: basic" || fail "input: basic" "alice" "$output"

  # Test: password input (value captured even though not displayed)
  output=$(expect -c '
    spawn bash -c "source '"$ROOT_DIR"'/chicle.sh; chicle_input --password --prompt \"Pass: \""
    expect ":"
    send "secret\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [[ "$output" == "secret" ]] && pass "input: password" || fail "input: password" "secret" "$output"

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
    spawn zsh -c "source '"$ROOT_DIR"'/chicle.sh; chicle_choose A B C"
    expect "❯"
    send "\033\[B\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [[ "$output" == "B" ]] && pass "zsh choose: second (down+enter)" || fail "zsh choose: second (down+enter)" "B" "$output"


  echo "Testing chicle_choose --multi in zsh (expect)..."

  # Test: multi-select in zsh
  output=$(expect -c '
    spawn zsh -c "source '"$ROOT_DIR"'/chicle.sh; chicle_choose --multi A B C"
    expect "❯"
    send " \033\[B \r"
    expect eof
  ' 2>&1 | clean_output | grep -E "^(A|B|C)$" | tr '\n' ',')
  [[ "$output" == "A,B," ]] && pass "zsh choose: multi A,B" || fail "zsh choose: multi A,B" "A,B," "$output"


  echo "Testing chicle_input in zsh (expect)..."

  # Test: password input in zsh
  output=$(expect -c '
    spawn zsh -c "source '"$ROOT_DIR"'/chicle.sh; chicle_input --password --prompt \"Pass: \""
    expect ":"
    send "secret\r"
    expect eof
  ' 2>&1 | clean_output | tail -1)
  [[ "$output" == "secret" ]] && pass "zsh input: password" || fail "zsh input: password" "secret" "$output"

else
  echo "Skipping zsh tests (expect, perl, or zsh not found)"
fi


# ============================================================================
# Summary
# ============================================================================

test_summary
