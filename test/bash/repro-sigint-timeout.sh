#!/usr/bin/env bash
# Test different read timeout values for ctrl-c responsiveness
# See: https://github.com/KnickKnackLabs/chicle/issues/27
#
# Usage: ./repro-sigint-timeout.sh <timeout>
# Examples:
#   ./repro-sigint-timeout.sh 1      # 1 second
#   ./repro-sigint-timeout.sh 0.5    # 500ms (bash 4+ only)
#   ./repro-sigint-timeout.sh 0.2    # 200ms (bash 4+ only)
#   ./repro-sigint-timeout.sh 0.1    # 100ms (bash 4+ only)
#   ./repro-sigint-timeout.sh 0.05   # 50ms  (bash 4+ only)

TIMEOUT="${1:-1}"

echo "bash: $(bash --version | head -1)"
echo "timeout: ${TIMEOUT}s"
echo ""
echo "Type keys to test responsiveness, then ctrl-c to test exit latency."

interrupted=""
trap 'interrupted=1' INT

stty -echo -icanon </dev/tty

while [[ -z "$interrupted" ]]; do
  key=""
  IFS= read -rsn1 -t "$TIMEOUT" key </dev/tty
  [[ $? -le 128 ]] && [[ -z "$interrupted" ]] && echo "[key: $(printf '%q' "$key")]" >/dev/tty
done

stty echo icanon </dev/tty
echo "" >/dev/tty
echo "exited cleanly" >/dev/tty
