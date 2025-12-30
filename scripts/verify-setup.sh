#!/bin/bash

# Script to verify Kora mainnet setup
# Usage: ./scripts/verify-setup.sh

set -e

# Get the project root directory (parent of scripts directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project root
cd "$PROJECT_ROOT"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kora Mainnet Setup Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ .env file not found"
    echo "   Please create it from env.example:"
    echo "   cp env.example .env"
    echo "   Then edit .env and add your private key"
    exit 1
else
    echo "✅ .env file found"
fi

# Load environment variables
export $(cat .env | grep -v '^#' | xargs)

# Check RPC_URL
if [ -z "$RPC_URL" ]; then
    echo "❌ RPC_URL not set in .env"
    exit 1
else
    echo "✅ RPC_URL is set: ${RPC_URL:0:50}..."
fi

# Check KORA_MAINNET_PRIVATE_KEY
if [ -z "$KORA_MAINNET_PRIVATE_KEY" ]; then
    echo "❌ KORA_MAINNET_PRIVATE_KEY not set in .env"
    exit 1
else
    echo "✅ KORA_MAINNET_PRIVATE_KEY is set (length: ${#KORA_MAINNET_PRIVATE_KEY} chars)"
fi

# Check if kora binary exists
if ! command -v kora &> /dev/null; then
    echo "⚠️  kora command not found in PATH"
    echo "   Building kora..."
    cargo build --release
    echo "   You may need to add the binary to your PATH or use:"
    echo "   cargo run --release -- rpc start ..."
else
    echo "✅ kora command found"
fi

# Check config files
if [ ! -f "kora.mainnet.toml" ]; then
    echo "❌ kora.mainnet.toml not found"
    exit 1
else
    echo "✅ kora.mainnet.toml found"
fi

if [ ! -f "signers.mainnet.toml" ]; then
    echo "❌ signers.mainnet.toml not found"
    exit 1
else
    echo "✅ signers.mainnet.toml found"
fi

# Check if Redis is needed and running (if usage_limit is enabled)
if grep -q "enabled = true" kora.mainnet.toml 2>/dev/null | grep -q "usage_limit"; then
    if command -v redis-cli &> /dev/null; then
        if redis-cli ping &> /dev/null; then
            echo "✅ Redis is running"
        else
            echo "⚠️  Redis is not running (but may be needed for usage_limit)"
            echo "   Start Redis with: docker run -d -p 6379:6379 redis:latest"
        fi
    else
        echo "⚠️  Redis CLI not found (but may be needed for usage_limit)"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup verification complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To start the server, run:"
echo "  ./scripts/run-mainnet.sh"
echo ""
echo "Or manually:"
echo "  kora --config kora.mainnet.toml --rpc-url \"\$RPC_URL\" rpc start --signers-config signers.mainnet.toml --port 8080"
echo ""

