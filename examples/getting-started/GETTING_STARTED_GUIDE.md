# Getting Started Example Guide

This guide explains what's in the getting-started example and how to test it with your mainnet Kora server.

## What's in the Getting-Started Example

The getting-started example contains three main files:

### 1. `quick-start.ts` - Simple Connection Test
**Purpose**: Quick test to verify your Kora server is working

**What it does**:
- Connects to your Kora server
- Gets the server configuration
- Gets a recent blockhash

**Use case**: First thing to run to verify your server is accessible

### 2. `full-demo.ts` - Complete Gasless Transaction Demo
**Purpose**: Full end-to-end demonstration of gasless transactions

**What it does** (6 steps):
1. **Initialize clients**: Connects to Kora and Solana RPC
2. **Setup keypairs**: Loads test sender, destination, and gets Kora fee payer address
3. **Create instructions**: Creates token transfer, SOL transfer, and memo instructions
4. **Get payment instruction**: Estimates fee and gets payment instruction from Kora
5. **Create final transaction**: Builds transaction with payment + user instructions
6. **Submit transaction**: Signs with Kora, sends to Solana network, and waits for confirmation

**Use case**: Complete example showing how to use Kora for gasless transactions

### 3. `setup.ts` - Local Development Setup
**Purpose**: Sets up test environment for local development (devnet/localnet)

**What it does**:
- Creates test keypairs
- Airdrops SOL to test accounts
- Creates a test USDC mint
- Mints test tokens

**Use case**: Only needed for local development/testing, not for mainnet

## How to Test with Mainnet

### Prerequisites

1. **Kora server running** on `http://localhost:8080`
2. **Node.js and pnpm** installed
3. **Environment variables** set up (see below)

### Step 1: Install Dependencies

```bash
cd examples/getting-started/demo/client
pnpm install
```

### Step 2: Set Up Environment Variables

The examples need some environment variables. Create a `.env` file in the `demo` directory:

```bash
cd examples/getting-started/demo
cat > .env << EOF
# Test sender keypair (base58 private key)
# Generate one: solana-keygen new -o test-sender.json
# Then: cat test-sender.json | jq -r '.[:64]' | base58
TEST_SENDER_KEYPAIR=your_test_sender_private_key_base58

# Destination keypair (base58 private key)
DESTINATION_KEYPAIR=your_destination_private_key_base58

# Optional: Kora API key if authentication is enabled
# KORA_API_KEY=your_api_key

# Optional: Kora HMAC secret if authentication is enabled
# KORA_HMAC_SECRET=your_hmac_secret
EOF
```

**Note**: For mainnet testing, you'll need:
- Real keypairs with SOL/USDC on mainnet
- The test sender needs USDC to pay fees
- The destination can be any address

### Step 3: Update Configuration for Mainnet

The `full-demo.ts` currently uses localhost Solana RPC. For mainnet, you need to update it:

Edit `examples/getting-started/demo/client/src/full-demo.ts`:

```typescript
const CONFIG = {
  computeUnitLimit: 200_000,
  computeUnitPrice: 1_000_000n as MicroLamports,
  transactionVersion: 0,
  solanaRpcUrl: process.env.SOLANA_RPC_URL || "https://mainnet.helius-rpc.com/?api-key=d9b6d595-1feb-4741-8958-484ad55afdab",
  solanaWsUrl: process.env.SOLANA_WS_URL || "wss://mainnet.helius-rpc.com/?api-key=d9b6d595-1feb-4741-8958-484ad55afdab",
  koraRpcUrl: "http://localhost:8080/",
};
```

### Step 4: Run the Examples

#### Quick Start (Simple Test)
```bash
cd examples/getting-started/demo/client
pnpm start
```

This will:
- Connect to your Kora server
- Print the server configuration
- Print a recent blockhash

**Expected output**:
```
Kora Config: { ... }
Blockhash:  ...
```

#### Full Demo (Complete Transaction)
```bash
cd examples/getting-started/demo/client
pnpm full-demo
```

This will:
- Walk through all 6 steps
- Create a real transaction on mainnet
- Pay fees in USDC
- Submit to Solana network

**Expected output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
KORA GASLESS TRANSACTION DEMO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1/6] Initializing clients
  → Kora RPC: http://localhost:8080/
  → Solana RPC: https://mainnet.helius-rpc.com/...

[2/6] Setting up keypairs
  → Sender: ...
  → Destination: ...
  → Kora signer address: ...

[3/6] Creating demonstration instructions
  → Payment token: EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v
  ✓ Token transfer instruction created
  ✓ SOL transfer instruction created
  ✓ Memo instruction created
  → Total: X instructions

[4/6] Estimating Kora fee and assembling payment instruction
  → Fee payer: ...
  → Blockhash: ...
  ✓ Estimate transaction built
  ✓ Payment instruction received from Kora

[5/6] Creating and signing final transaction (with payment)
  ✓ Final transaction built with payment
  ✓ Transaction signed by user

[6/6] Signing transaction with Kora and sending to Solana cluster
  ✓ Transaction co-signed by Kora
  ✓ Transaction submitted to network
  ⏳ Awaiting confirmation...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SUCCESS: Transaction confirmed on Solana
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Transaction signature:
...
```

## Troubleshooting

### "Environment variable not set"
- Make sure you created the `.env` file in `examples/getting-started/demo/`
- Check that `TEST_SENDER_KEYPAIR` and `DESTINATION_KEYPAIR` are set

### "Failed to connect to Kora server"
- Verify your Kora server is running: `curl http://localhost:8080`
- Check the server logs for errors

### "Insufficient funds"
- For mainnet, ensure your test sender has:
  - SOL for transaction fees (if not using gasless)
  - USDC for payment (if using gasless with USDC)

### "Transaction failed"
- Check that the payment token (USDC) is in the allowed list
- Verify the fee payer account has sufficient SOL
- Check transaction size limits in `kora.mainnet.toml`

## What Each Example Demonstrates

### quick-start.ts
- ✅ Basic Kora client connection
- ✅ Reading server configuration
- ✅ Getting blockhash from Kora

### full-demo.ts
- ✅ Creating complex transactions with multiple instructions
- ✅ Getting fee estimates from Kora
- ✅ Getting payment instructions for gasless transactions
- ✅ Building and signing transactions
- ✅ Submitting transactions to Solana network
- ✅ Waiting for transaction confirmation

## Next Steps

After running these examples, you can:
1. Modify the examples to create your own transactions
2. Integrate Kora into your own application
3. Test different payment tokens
4. Experiment with different fee payer policies

