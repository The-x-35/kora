# Step-by-Step: Testing Getting-Started on Mainnet

## ✅ Configuration Status

**Good news!** The client is already configured to use your local Kora server:
- `quick-start.ts`: Uses `http://localhost:8080/` ✅
- `full-demo.ts`: Uses `http://localhost:8080/` (or `KORA_RPC_URL` env var) ✅
- `full-demo.ts`: Uses mainnet RPC from environment variables ✅

## Step-by-Step Instructions

### Step 1: Verify Kora Server is Running

```bash
# Check if server is running
curl http://localhost:8080

# Should return something (even if it's an error, server is up)
```

If not running, start it:
```bash
cd /Users/arpitsingh/Projects/kora/kora
./scripts/run-mainnet.sh
```

### Step 2: Navigate to Getting-Started Directory

```bash
cd /Users/arpitsingh/Projects/kora/kora/examples/getting-started/demo
```

### Step 3: Create .env File

```bash
# Create .env file
cat > .env << 'EOF'
# Your test sender keypair (base58 private key)
# This wallet needs USDC on mainnet to pay for gasless transactions
TEST_SENDER_KEYPAIR=your_base58_private_key_here

# Destination keypair (base58 private key)
# This is where tokens will be sent in the demo
DESTINATION_KEYPAIR=your_base58_private_key_here

# Mainnet RPC URLs
SOLANA_RPC_URL=https://mainnet.helius-rpc.com/?api-key=d9b6d595-1feb-4741-8958-484ad55afdab
SOLANA_WS_URL=wss://mainnet.helius-rpc.com/?api-key=d9b6d595-1feb-4741-8958-484ad55afdab

# Optional: Kora API key if authentication is enabled
# KORA_API_KEY=your_api_key
EOF
```

### Step 4: Generate Keypairs (if you don't have them)

```bash
# Generate test sender keypair
solana-keygen new -o test-sender.json --no-bip39-passphrase

# Get base58 private key
cat test-sender.json | jq -r '.[:64]' | base58
# Copy this output and paste it as TEST_SENDER_KEYPAIR in .env

# Generate destination keypair
solana-keygen new -o test-dest.json --no-bip39-passphrase

# Get base58 private key
cat test-dest.json | jq -r '.[:64]' | base58
# Copy this output and paste it as DESTINATION_KEYPAIR in .env
```

**⚠️ IMPORTANT:** 
- Your `TEST_SENDER_KEYPAIR` needs **USDC on mainnet**!
- You can get USDC from a DEX or transfer it to that address
- Check balance: https://solscan.io/account/YOUR_ADDRESS

### Step 5: Edit .env File

```bash
# Open .env in your editor
nano .env
# or
code .env
# or
vim .env
```

Replace:
- `your_base58_private_key_here` for `TEST_SENDER_KEYPAIR` with your actual key
- `your_base58_private_key_here` for `DESTINATION_KEYPAIR` with your actual key

### Step 6: Install Dependencies

```bash
cd client
pnpm install
```

This will install all required packages.

### Step 7: Test Quick Start (No Transaction)

```bash
# Still in client directory
pnpm start
```

**Expected Output:**
```
Kora Config: {
  fee_payers: [ '62BxUvSU4wSdphY3DnhWcdTunDBhjJ53bbiup5wqi1Lp' ],
  validation_config: {
    allowed_spl_paid_tokens: [ 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v' ],
    ...
  },
  ...
}
Blockhash:  <some_blockhash>
```

**If this works:** ✅ Your Kora server is connected and working!

**If it fails:**
- Check Kora server is running: `curl http://localhost:8080`
- Check `.env` file exists and has correct paths
- Check server logs

### Step 8: Run Full Demo (REAL TRANSACTION!)

**⚠️ WARNING: This creates a REAL transaction on mainnet!**

It will:
- Transfer **10 USDC** from your `TEST_SENDER_KEYPAIR` to `DESTINATION_KEYPAIR`
- Transfer **0.01 SOL** from your `TEST_SENDER_KEYPAIR` to `DESTINATION_KEYPAIR`
- Add a memo "Hello, Kora!"
- Pay Kora in USDC for the transaction fees
- Submit to mainnet

**Make sure:**
- ✅ Your `TEST_SENDER_KEYPAIR` has USDC (at least 10 USDC + fee)
- ✅ Your `TEST_SENDER_KEYPAIR` has some SOL (for the 0.01 SOL transfer)
- ✅ You understand this is a real transaction

```bash
# Still in client directory
pnpm full-demo
```

**Expected Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
KORA GASLESS TRANSACTION DEMO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1/6] Initializing clients
  → Kora RPC: http://localhost:8080/
  → Solana RPC: https://mainnet.helius-rpc.com/...

[2/6] Setting up keypairs
  → Sender: <your_sender_address>
  → Destination: <destination_address>
  → Kora signer address: 62BxUvSU4wSdphY3DnhWcdTunDBhjJ53bbiup5wqi1Lp

[3/6] Creating demonstration instructions
  → Payment token: EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v
  ✓ Token transfer instruction created
  ✓ SOL transfer instruction created
  ✓ Memo instruction created
  → Total: X instructions

[4/6] Estimating Kora fee and assembling payment instruction
  → Fee payer: 62BxUvSU4wSdphY3DnhWcdTunDBhjJ53bbiup5wqi1Lp
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
<transaction_signature>
```

**View transaction on Solana Explorer:**
```
https://solscan.io/tx/<transaction_signature>
```

## Troubleshooting

### "Cannot connect to Kora server"
```bash
# Check if server is running
curl http://localhost:8080

# If not, start it
cd /Users/arpitsingh/Projects/kora/kora
./scripts/run-mainnet.sh
```

### "Environment variable not set"
- Make sure `.env` file is in `examples/getting-started/demo/` (not in `client/`)
- Check file has correct variable names
- Restart terminal or source the file

### "Insufficient funds"
- Your `TEST_SENDER_KEYPAIR` needs USDC on mainnet
- Check balance: https://solscan.io/account/YOUR_SENDER_ADDRESS
- Transfer USDC to that address

### "Failed to get payment instruction"
- Check that USDC is in allowed payment tokens in `kora.mainnet.toml`
- Verify fee payer has SOL
- Check server logs

## Quick Reference

**All commands in order:**
```bash
# 1. Verify server running
curl http://localhost:8080

# 2. Navigate to demo
cd /Users/arpitsingh/Projects/kora/kora/examples/getting-started/demo

# 3. Create .env (if not exists)
cat > .env << 'EOF'
TEST_SENDER_KEYPAIR=your_key_here
DESTINATION_KEYPAIR=your_key_here
SOLANA_RPC_URL=https://mainnet.helius-rpc.com/?api-key=d9b6d595-1feb-4741-8958-484ad55afdab
SOLANA_WS_URL=wss://mainnet.helius-rpc.com/?api-key=d9b6d595-1feb-4741-8958-484ad55afdab
EOF

# 4. Edit .env with your keys
nano .env

# 5. Install dependencies
cd client
pnpm install

# 6. Quick test
pnpm start

# 7. Full demo (REAL TRANSACTION!)
pnpm full-demo
```

## What Each Step Does

1. **Quick Start (`pnpm start`)**: 
   - Tests connection to your Kora server
   - Gets server configuration
   - Gets a blockhash
   - **No transactions, just testing**

2. **Full Demo (`pnpm full-demo`)**:
   - Creates a real transaction on mainnet
   - Transfers USDC and SOL
   - Pays Kora in USDC for gas
   - Kora pays SOL for transaction fees
   - **This is a REAL transaction!**

## Summary

✅ **Client is configured** to use `http://localhost:8080/` (your Kora server)
✅ **Full demo uses mainnet** RPC from environment variables
✅ **Just need to:**
   1. Create `.env` with your keypairs
   2. Make sure test sender has USDC
   3. Run `pnpm start` (test) or `pnpm full-demo` (real transaction)

