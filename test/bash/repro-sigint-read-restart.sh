#!/usr/bin/env bash
# Reproduction attempts for ctrl-c + read -n1 interaction
# See: https://github.com/KnickKnackLabs/chicle/issues/27

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/chicle.sh"

case "${1:-}" in
  # Case 1: Bare read loop — echo in trap handler
  bare)
    interrupted=""
    trap 'echo "[trap fired]" >/dev/tty; interrupted=1' INT
    stty -echo -icanon </dev/tty
    echo "Press ctrl-c..." >/dev/tty
    while true; do
      IFS= read -rsn1 key </dev/tty
      if [[ -n "$interrupted" ]]; then
        echo "[interrupted]" >/dev/tty
        break
      fi
      echo "[key: $(printf '%q' "$key")]" >/dev/tty
    done
    stty echo icanon </dev/tty
    echo "exited cleanly"
    ;;

  # Case 2: Bare read loop — flag only in trap (no echo)
  bare-quiet)
    interrupted=""
    trap 'interrupted=1' INT
    stty -echo -icanon </dev/tty
    echo "Press ctrl-c..." >/dev/tty
    while true; do
      IFS= read -rsn1 key </dev/tty
      if [[ -n "$interrupted" ]]; then
        echo "[interrupted]" >/dev/tty
        break
      fi
      echo "[key: $(printf '%q' "$key")]" >/dev/tty
    done
    stty echo icanon </dev/tty
    echo "exited cleanly"
    ;;

  # Case 3: Read via function call (like chicle_choose uses)
  bare-func)
    _read_one() {
      IFS= read -rsn1 "$1"
    }
    interrupted=""
    trap 'interrupted=1' INT
    stty -echo -icanon </dev/tty
    echo "Press ctrl-c..." >/dev/tty
    while true; do
      _read_one key </dev/tty
      if [[ -n "$interrupted" ]]; then
        echo "[interrupted]" >/dev/tty
        break
      fi
      echo "[key: $(printf '%q' "$key")]" >/dev/tty
    done
    stty echo icanon </dev/tty
    echo "exited cleanly"
    ;;

  # Case 4: chicle_choose called directly
  direct)
    echo "Calling chicle_choose directly..."
    chicle_choose --header "Pick one" "Alpha" "Beta" "Gamma"
    echo "returned: $?"
    ;;

  # Case 5: chicle_choose inside $(...) — the real calling pattern
  subshell)
    echo "Calling chicle_choose inside \$(...)..."
    CHOICE=$(chicle_choose --header "Pick one" "Alpha" "Beta" "Gamma") || true
    echo "returned: '$CHOICE'"
    ;;

  # Case 6: chicle_choose with --var (no subshell)
  var)
    echo "Calling chicle_choose with --var..."
    chicle_choose --var CHOICE --header "Pick one" "Alpha" "Beta" "Gamma"
    echo "returned: '$CHOICE'"
    ;;

  *)
    echo "Usage: $0 {bare|bare-quiet|bare-func|direct|subshell|var}"
    echo ""
    echo "  bare       - raw read loop, echo in trap"
    echo "  bare-quiet - raw read loop, flag-only trap (no echo)"
    echo "  bare-func  - raw read loop via function call (like _chicle_read_char)"
    echo "  direct     - chicle_choose called directly"
    echo "  subshell   - chicle_choose inside \$(...)"
    echo "  var        - chicle_choose with --var (no subshell)"
    ;;
esac
