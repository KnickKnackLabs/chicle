#!/usr/bin/env bash
# chicle bash test runner
# Requires bats: mise install, or apt install bats / brew install bats-core

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v bats &>/dev/null; then
  echo "Error: bats not found. Install it:"
  echo "  mise:   mise install"
  echo "  Linux:  sudo apt install bats"
  echo "  macOS:  brew install bats-core"
  exit 1
fi

bats "$SCRIPT_DIR/test/bash/"
