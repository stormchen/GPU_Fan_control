#!/bin/bash
set -e

PIDS=$(pgrep -f "A10_Temp_Logger\.sh" 2>/dev/null || true)

if [ -z "$PIDS" ]; then
    echo "A10 Temperature Logger is not running."
    exit 0
fi

echo "Stopping A10 Temperature Logger (PID: $PIDS)..."
kill $PIDS 2>/dev/null
echo "Done."
