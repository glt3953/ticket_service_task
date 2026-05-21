#!/bin/bash
set -e

swift build

for i in {1..100}; do
  echo "=== Round $i ==="
  if ./.build/debug/TicketService 2>&1 | grep -E "DUPLICATE_TICKET|TIMEOUT_CALLED"; then
    echo "Detected bug, exiting with failure"
    exit 1
  fi
done

echo "1.0" > /logs/verifier/reward.txt