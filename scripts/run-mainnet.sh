#!/bin/bash

# Script to run Kora server on mainnet
# Usage: ./scripts/run-mainnet.sh

set -e

# Get the project root directory (parent of scripts directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project root
cd "$PROJECT_ROOT"

# Load environment variables from .env file
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "Error: .env file not found. Please create it from env.example"
    exit 1
fi

# Check if required environment variables are set
if [ -z "$RPC_URL" ]; then
    echo "Error: RPC_URL not set in .env file"
    exit 1
fi

if [ -z "$KORA_MAINNET_PRIVATE_KEY" ]; then
    echo "Error: KORA_MAINNET_PRIVATE_KEY not set in .env file"
    exit 1
fi

# Check if config files exist
if [ ! -f "kora.mainnet.toml" ]; then
    echo "Error: kora.mainnet.toml not found"
    exit 1
fi

if [ ! -f "signers.mainnet.toml" ]; then
    echo "Error: signers.mainnet.toml not found"
    exit 1
fi

# Default port
PORT=${PORT:-8080}

echo "Starting Kora server on mainnet..."
echo "RPC URL: $RPC_URL"
echo "Port: $PORT"
echo ""

# Run the server
# Note: --config and --rpc-url are global arguments, so they come before 'rpc start'
kora --config kora.mainnet.toml --rpc-url "$RPC_URL" rpc start --signers-config signers.mainnet.toml --port "$PORT"

