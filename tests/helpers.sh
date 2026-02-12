#!/usr/bin/env bash
# chicle test helpers — golden file testing infrastructure

PASS=0
FAIL=0

pass() {
  echo "  ✓ $1"
  ((++PASS))
}

fail() {
  echo "  ✗ $1"
  if [[ -n "${2:-}" ]]; then
    echo "    Expected: $2"
    echo "    Got:      $3"
  fi
  ((++FAIL))
}

# Strip ANSI escape codes and carriage returns
strip_ansi() {
  perl -pe 's/\e\[[0-9;?]*[a-zA-Z]//g' | tr -d '\r'
}

# Compare output against a golden file
# Usage: check_golden "test name" "actual output" "path/to/golden/file"
check_golden() {
  local name="$1" actual="$2" golden_file="$3"
  local cleaned
  cleaned=$(printf '%s' "$actual" | strip_ansi)

  if [[ "${UPDATE_GOLDENS:-}" == "1" ]]; then
    mkdir -p "$(dirname "$golden_file")"
    printf '%s\n' "$cleaned" > "$golden_file"
    pass "$name (golden updated)"
    return
  fi

  if [[ ! -f "$golden_file" ]]; then
    fail "$name" "(golden file: $golden_file)" "(file missing — run with --update to create)"
    return
  fi

  local expected
  expected=$(cat "$golden_file")
  if [[ "$cleaned" == "$expected" ]]; then
    pass "$name"
  else
    fail "$name"
    echo "    --- expected (golden) ---"
    echo "    $expected"
    echo "    --- got ---"
    echo "    $cleaned"
  fi
}

# Print test summary and exit with appropriate code
test_summary() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Results: $PASS passed, $FAIL failed"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  [[ $FAIL -eq 0 ]] && exit 0 || exit 1
}
