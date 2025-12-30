#!/bin/bash

# Setup script for getting-started example on mainnet
# Usage: ./setup-mainnet.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Getting-Started Mainnet Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if .env exists
if [ -f .env ]; then
    echo "✅ .env file exists"
else
    echo "Creating .env file from example..."
    if [ -f .env.example ]; then
        cp .env.example .env
        echo "✅ Created .env file"
        echo ""
        echo "⚠️  IMPORTANT: Edit .env and add your keypairs:"
        echo "   - TEST_SENDER_KEYPAIR (needs USDC on mainnet!)"
        echo "   - DESTINATION_KEYPAIR"
        echo ""
        echo "   To generate keypairs:"
        echo "   solana-keygen new -o key.json"
        echo "   cat key.json | jq -r '.[:64]' | base58"
        echo ""
        read -p "Press Enter after you've edited .env..."
    else
        echo "❌ .env.example not found"
        exit 1
    fi
fi

# Check if keypairs are set
source .env 2>/dev/null || true

if [ -z "$TEST_SENDER_KEYPAIR" ] || [ "$TEST_SENDER_KEYPAIR" = "your_base58_private_key_here" ]; then
    echo "❌ TEST_SENDER_KEYPAIR not set in .env"
    echo "   Edit .env and add your test sender keypair"
    exit 1
fi

if [ -z "$DESTINATION_KEYPAIR" ] || [ "$DESTINATION_KEYPAIR" = "your_base58_private_key_here" ]; then
    echo "❌ DESTINATION_KEYPAIR not set in .env"
    echo "   Edit .env and add your destination keypair"
    exit 1
fi

echo "✅ Environment variables configured"
echo ""

# Install dependencies
echo "Installing dependencies..."
cd client
if [ ! -d "node_modules" ]; then
    pnpm install
    echo "✅ Dependencies installed"
else
    echo "✅ Dependencies already installed"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To test:"
echo "  cd client"
echo "  pnpm start        # Quick test (no transaction)"
echo "  pnpm full-demo    # Full demo (REAL transaction on mainnet!)"
echo ""
echo "⚠️  Make sure your TEST_SENDER_KEYPAIR has USDC on mainnet!"
echo ""

