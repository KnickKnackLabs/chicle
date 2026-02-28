#!/usr/bin/env zsh
# Test whether zsh's read -k1 has the SA_RESTART issue
# See: https://github.com/KnickKnackLabs/chicle/issues/27

interrupted=""
trap 'interrupted=1' INT

stty -echo -icanon </dev/tty

echo "Press ctrl-c..." >/dev/tty
while true; do
  read -rsk1 key </dev/tty
  if [[ -n "$interrupted" ]]; then
    echo "[interrupted]" >/dev/tty
    break
  fi
  echo "[key: ${(q)key}]" >/dev/tty
done

stty echo icanon </dev/tty
echo "exited cleanly" >/dev/tty
