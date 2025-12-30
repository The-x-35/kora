# Getting Started Example - Mainnet Guide

## What the Getting-Started Example Does

The getting-started example demonstrates how to use Kora for **gasless transactions** on Solana. Here's what each file does:

### 1. `quick-start.ts` - Simple Connection Test
**What it does:**
- Connects to your Kora server
- Gets the server configuration (shows allowed tokens, fee payer address, etc.)
- Gets a recent blockhash from Kora

**Purpose:** Quick test to verify your server is working

**Output:**
```
Kora Config: { fee_payers: [...], validation_config: {...} }
Blockhash:  <blockhash>
```

### 2. `full-demo.ts` - Complete Gasless Transaction Demo
**What it does (6 steps):**

1. **Initialize Clients**
   - Connects to Kora server (`http://localhost:8080`)
   - Connects to Solana RPC (mainnet)

2. **Setup Keypairs**
   - Loads your test sender keypair (needs USDC for payment)
   - Loads destination keypair
   - Gets Kora's fee payer address

3. **Create Instructions**
   - Creates a USDC token transfer instruction
   - Creates a SOL transfer instruction
   - Creates a memo instruction
   - These are the instructions you want to execute

4. **Get Payment Instruction**
   - Estimates the transaction fee
   - Gets a payment instruction from Kora
   - This instruction will transfer USDC from your wallet to Kora to pay for gas

5. **Create Final Transaction**
   - Builds the complete transaction with:
     - Your instructions (token transfer, SOL transfer, memo)
     - Payment instruction (to pay Kora in USDC)
   - Signs it with your wallet

6. **Submit Transaction**
   - Sends transaction to Kora for co-signing
   - Kora signs as fee payer (pays SOL for gas)
   - Submits to Solana network
   - Waits for confirmation

**Result:** You execute your transaction without spending SOL - you pay in USDC instead!

## How to Run on Mainnet

### Step 1: Install Dependencies

```bash
cd examples/getting-started/demo/client
pnpm install
```

### Step 2: Create Environment File

Create `.env` file in `examples/getting-started/demo/`:

```bash
cd examples/getting-started/demo
cat > .env << 'EOF'
# Your test sender keypair (base58 private key)
# This wallet needs USDC to pay for gasless transactions
TEST_SENDER_KEYPAIR=your_base58_private_key_here

# Destination keypair (base58 private key)
# This is where tokens will be sent
DESTINATION_KEYPAIR=your_base58_private_key_here

# Mainnet RPC URLs
SOLANA_RPC_URL=https://mainnet.helius-rpc.com/?api-key=d9b6d595-1feb-4741-8958-484ad55afdab
SOLANA_WS_URL=wss://mainnet.helius-rpc.com/?api-key=d9b6d595-1feb-4741-8958-484ad55afdab
EOF
```

**Important:** 
- Replace `your_base58_private_key_here` with actual base58 private keys
- Your `TEST_SENDER_KEYPAIR` needs USDC on mainnet to pay for transactions
- Generate keypairs: `solana-keygen new -o key.json && cat key.json | jq -r '.[:64]' | base58`

### Step 3: Run Quick Start (Simple Test)

```bash
cd examples/getting-started/demo/client
pnpm start
```

This will:
- Connect to your Kora server
- Print the server configuration
- Print a blockhash

**Expected output:**
```
Kora Config: {
  fee_payers: [ '62BxUvSU4wSdphY3DnhWcdTunDBhjJ53bbiup5wqi1Lp' ],
  validation_config: {
    allowed_spl_paid_tokens: [ 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v' ],
    ...
  }
}
Blockhash:  <blockhash_string>
```

### Step 4: Run Full Demo (Complete Transaction)

**⚠️ WARNING: This will create a REAL transaction on mainnet!**

Make sure:
- Your `TEST_SENDER_KEYPAIR` has USDC (for payment)
- Your Kora server is running
- You understand what the transaction does

```bash
cd examples/getting-started/demo/client
pnpm full-demo
```

**What happens:**
1. Creates a transaction that:
   - Transfers 10 USDC from your wallet to destination
   - Transfers 0.01 SOL from your wallet to destination
   - Adds a memo "Hello, Kora!"
2. Gets payment instruction from Kora (pays in USDC)
3. Signs with your wallet
4. Kora co-signs as fee payer
5. Submits to mainnet
6. Waits for confirmation

**Expected output:**
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

## Troubleshooting

### "Environment variable not set"
- Make sure `.env` file exists in `examples/getting-started/demo/`
- Check that `TEST_SENDER_KEYPAIR` and `DESTINATION_KEYPAIR` are set

### "Failed to connect to Kora server"
- Verify server is running: `curl http://localhost:8080`
- Check server logs

### "Insufficient funds"
- Your `TEST_SENDER_KEYPAIR` needs USDC on mainnet
- Check balance: Use Solana explorer or CLI

### "Transaction failed"
- Check that payment token (USDC) is in allowed list
- Verify fee payer has SOL
- Check transaction size limits

## Summary

**Getting-Started Example = Gasless Transactions Demo**

- **You pay in USDC** (or other tokens)
- **Kora pays SOL** for transaction fees
- **You execute transactions** without needing SOL in your wallet
- **Better UX** for your users

The example shows the complete flow from creating instructions to submitting a confirmed transaction on mainnet.

