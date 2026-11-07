#!/usr/bin/env bash
# Stops the host-run services started by scripts/dev-up.sh.
set -uo pipefail

cd "$(dirname "$0")/.."

if [[ ! -d .run ]]; then
  echo "Nothing to stop."
  exit 0
fi

for pidfile in .run/*.pid; do
  [[ -e "$pidfile" ]] || continue
  pid="$(cat "$pidfile" 2>/dev/null || true)"
  name="$(basename "$pidfile" .pid)"
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    echo "Stopping $name (pid $pid)"
    kill "$pid" 2>/dev/null || true
  fi
  rm -f "$pidfile"
done

sleep 1
for pidfile in .run/*.pid; do
  [[ -e "$pidfile" ]] || continue
done

echo "Done."
