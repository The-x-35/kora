#!/bin/bash

# Script to extract base58 private key from Solana keypair JSON file
# Usage: ./scripts/get-private-key-base58.sh <path-to-keypair.json>

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-keypair.json>"
    echo "Example: $0 ~/.config/solana/mainnet-fee-payer.json"
    exit 1
fi

KEYPAIR_FILE="$1"

if [ ! -f "$KEYPAIR_FILE" ]; then
    echo "Error: Keypair file not found: $KEYPAIR_FILE"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install it first."
    echo "macOS: brew install jq"
    echo "Linux: sudo apt-get install jq"
    exit 1
fi

# Check if base58 is installed
if ! command -v base58 &> /dev/null; then
    echo "Error: base58 command not found."
    echo "Please install base58-cli:"
    echo "  npm install -g base58-cli"
    echo "  or"
    echo "  cargo install base58-cli"
    exit 1
fi

# Extract the first 64 bytes (private key + public key)
# The private key is the first 32 bytes, but Solana uses the full 64-byte secret key
PRIVATE_KEY_HEX=$(cat "$KEYPAIR_FILE" | jq -r '.[:64]')

# Convert to base58
BASE58_KEY=$(echo -n "$PRIVATE_KEY_HEX" | xxd -r -p | base58)

echo "Base58 Private Key:"
echo "$BASE58_KEY"
echo ""
echo "Add this to your .env file as:"
echo "KORA_MAINNET_PRIVATE_KEY=$BASE58_KEY"

