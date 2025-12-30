# Quick Test Guide - Mainnet

## What Getting-Started Does

**TL;DR: It shows you how to do gasless transactions - you pay in USDC, Kora pays SOL for fees.**

### `quick-start.ts` - Simple Test
- Connects to Kora server
- Gets server config
- Gets a blockhash
- **Takes 2 seconds, no transactions**

### `full-demo.ts` - Full Gasless Transaction
**What it does:**
1. Creates a transaction with:
   - Transfer 10 USDC from your wallet → destination
   - Transfer 0.01 SOL from your wallet → destination  
   - Add memo "Hello, Kora!"
2. **Gets payment instruction from Kora** (you pay USDC to Kora)
3. Signs with your wallet
4. **Kora co-signs as fee payer** (Kora pays SOL for gas)
5. Submits to mainnet
6. Waits for confirmation

**Result:** You execute transactions without SOL - you pay in USDC!

## Setup for Mainnet (5 minutes)

### Step 1: Create .env file

```bash
cd examples/getting-started/demo
cp .env.example .env
```

Edit `.env` and add your keypairs:

```bash
# Get base58 private key from a keypair file:
# solana-keygen new -o test.json
# cat test.json | jq -r '.[:64]' | base58

TEST_SENDER_KEYPAIR=your_base58_key_here
DESTINATION_KEYPAIR=your_base58_key_here
```

**Important:** Your `TEST_SENDER_KEYPAIR` needs USDC on mainnet!

### Step 2: Install dependencies

```bash
cd client
pnpm install
```

### Step 3: Run Quick Test

```bash
pnpm start
```

**Expected:**
```
Kora Config: { ... }
Blockhash:  ...
```

### Step 4: Run Full Demo (REAL TRANSACTION!)

```bash
pnpm full-demo
```

**⚠️ WARNING: This creates a REAL transaction on mainnet!**

It will:
- Transfer 10 USDC from your wallet
- Transfer 0.01 SOL from your wallet
- Pay Kora in USDC for gas
- Submit to mainnet

## Rate Limit Testing

### Fixed Rate Limit Test Script

```bash
# From project root
./scripts/test-rate-limit-fixed.sh http://localhost:8080 200 150
# Sends 200 requests at 150 req/s (above the 100 req/s limit)
```

### Burst Test (Better for Testing)

```bash
./scripts/test-rate-limit-burst.sh http://localhost:8080 250
# Sends 250 requests all at once
```

**Note:** Rate limiting in Kora is **per-second**, so if you send requests slowly, they might all succeed. The burst test is better for testing.

## Troubleshooting

### Rate Limit Not Working?
- Rate limit is **100 requests per second**
- If you send requests slowly, they all succeed
- Use burst test: `./scripts/test-rate-limit-burst.sh`
- Check server logs for rate limit messages

### Getting-Started Fails?
- Make sure `.env` file exists in `examples/getting-started/demo/`
- Check that keypairs are base58 format
- Verify `TEST_SENDER_KEYPAIR` has USDC on mainnet
- Ensure Kora server is running: `curl http://localhost:8080`

### "Insufficient funds"
- Your test sender needs USDC on mainnet
- Check balance on Solana explorer

## Summary

**Getting-Started = Gasless Transactions Demo**

- You pay in USDC (or tokens)
- Kora pays SOL for fees
- Better UX for users

**Rate Limit:**
- Configured: 100 requests/second
- Test with burst script to see it work
- Per-second limiting, not total

