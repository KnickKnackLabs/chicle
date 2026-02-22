#!/usr/bin/env bash
# chicle bash test runner
# Runs BATS tests. Install bats: apt install bats / brew install bats-core

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v bats &>/dev/null; then
  echo "Error: bats not found. Install it:"
  echo "  Linux:  sudo apt install bats"
  echo "  macOS:  brew install bats-core"
  echo ""
  echo "Falling back to legacy test runner..."
  bash "$SCRIPT_DIR/test/bash/legacy_test.sh"
  exit $?
fi

bats "$SCRIPT_DIR/test/bash/"
