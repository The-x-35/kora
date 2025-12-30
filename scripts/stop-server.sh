#!/bin/bash

# Script to stop the Kora server running on port 8080
# Usage: ./scripts/stop-server.sh

set -e

PORT=${1:-8080}

echo "Stopping Kora server on port $PORT..."

# Find and kill process on the port
PID=$(lsof -ti:$PORT 2>/dev/null || echo "")

if [ -z "$PID" ]; then
    echo "No process found running on port $PORT"
    exit 0
fi

echo "Found process $PID on port $PORT"
kill $PID

# Wait a moment and verify it's stopped
sleep 1
if lsof -ti:$PORT >/dev/null 2>&1; then
    echo "⚠️  Process still running, forcing kill..."
    kill -9 $PID
    sleep 1
fi

if lsof -ti:$PORT >/dev/null 2>&1; then
    echo "❌ Failed to stop server on port $PORT"
    exit 1
else
    echo "✅ Server stopped successfully"
fi

