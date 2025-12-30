#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# RPC URL must be set in .env file
if [ -z "$RPC_URL" ]; then
    echo "Error: RPC_URL not set in .env file"
    echo "Please set RPC_URL in your .env file"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Initializing Kora Fee Payer Token Accounts (ATAs)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This will create USDC token accounts for the Kora fee payer"
echo "so it can receive payments from users."
echo ""
echo "RPC URL: $RPC_URL"
echo "Config: kora.mainnet.toml"
echo "Signers: signers.mainnet.toml"
echo ""

# Run the initialize-atas command
kora \
  --config kora.mainnet.toml \
  --rpc-url "$RPC_URL" \
  rpc initialize-atas \
  --signers-config signers.mainnet.toml

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ ATA initialization complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "You can now run the full-demo again:"
echo "  cd examples/getting-started/demo/client"
echo "  pnpm full-demo"

