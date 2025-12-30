# Testing Guide for Kora Server

This guide explains how to test your Kora server, including the getting-started examples and rate limiting.

## Table of Contents

1. [Getting-Started Examples](#getting-started-examples)
2. [Rate Limit Testing](#rate-limit-testing)
3. [Quick Test Commands](#quick-test-commands)

## Getting-Started Examples

### What's Included

The getting-started example contains three TypeScript files:

#### 1. `quick-start.ts` - Simple Connection Test
**Purpose**: Verify your Kora server is working

**What it tests**:
- ✅ Server connectivity
- ✅ Configuration retrieval
- ✅ Blockhash retrieval

**How to run**:
```bash
cd examples/getting-started/demo/client
pnpm install
pnpm start
```

**Expected output**:
```
Kora Config: { fee_payers: [...], validation_config: {...}, ... }
Blockhash:  <blockhash_string>
```

#### 2. `full-demo.ts` - Complete Gasless Transaction
**Purpose**: End-to-end gasless transaction demo

**What it demonstrates**:
1. Client initialization (Kora + Solana RPC)
2. Keypair setup
3. Instruction creation (token transfer, SOL transfer, memo)
4. Payment instruction from Kora
5. Transaction building and signing
6. Transaction submission and confirmation

**How to run**:
```bash
cd examples/getting-started/demo/client
pnpm install
pnpm full-demo
```

**Prerequisites**:
- `.env` file with `TEST_SENDER_KEYPAIR` and `DESTINATION_KEYPAIR`
- Test sender needs USDC on mainnet (for payment)
- Kora server running on `http://localhost:8080`

**Expected output**: See [GETTING_STARTED_GUIDE.md](examples/getting-started/GETTING_STARTED_GUIDE.md)

#### 3. `setup.ts` - Local Development Setup
**Purpose**: Set up test environment for local devnet

**Note**: Only needed for local development, not for mainnet testing

### Setting Up for Mainnet Testing

1. **Create environment file**:
```bash
cd examples/getting-started/demo
cat > .env << EOF
TEST_SENDER_KEYPAIR=your_base58_private_key_here
DESTINATION_KEYPAIR=your_base58_private_key_here
SOLANA_RPC_URL=https://mainnet.helius-rpc.com/?api-key=d9b6d595-1feb-4741-8958-484ad55afdab
SOLANA_WS_URL=wss://mainnet.helius-rpc.com/?api-key=d9b6d595-1feb-4741-8958-484ad55afdab
EOF
```

2. **Install dependencies**:
```bash
cd client
pnpm install
```

3. **Run tests**:
```bash
# Quick test
pnpm start

# Full demo
pnpm full-demo
```

## Rate Limit Testing

### Simple Rate Limit Test

**Purpose**: Test if rate limiting is working

**How to run**:
```bash
./scripts/test-rate-limit-simple.sh [KORA_URL] [NUM_REQUESTS] [CONCURRENT]
```

**Examples**:
```bash
# Basic test (200 requests, 10 concurrent)
./scripts/test-rate-limit-simple.sh

# Custom test (500 requests, 20 concurrent)
./scripts/test-rate-limit-simple.sh http://localhost:8080 500 20

# Test remote server
./scripts/test-rate-limit-simple.sh https://your-kora-server.com 1000 50
```

**What it does**:
- Sends multiple concurrent requests to the Kora server
- Tracks successful (200), rate-limited (429), and error responses
- Reports statistics and analysis

**Expected output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Kora Rate Limit Test (Simple)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Kora URL: http://localhost:8080
Total Requests: 200
Concurrent: 10

✅ Server is reachable

Starting rate limit test...
Progress: 200/200 requests sent...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Rate Limit Test Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Test Duration: 2.5s
Actual Rate: 80.00 requests/second
Total Requests: 200

Response Breakdown:
  ✅ Successful (200): 100
  ⚠️  Rate Limited (429): 100
  ❌ Errors (other): 0

📊 Analysis:
  ✅ Rate limiting is working! 100 requests were throttled
  ✅ 100 requests succeeded
```

### Advanced Rate Limit Test

**Purpose**: More detailed rate limit testing with timing

**How to run**:
```bash
./scripts/test-rate-limit.sh [KORA_URL] [RATE_LIMIT] [DURATION]
```

**Examples**:
```bash
# Test at 2x the configured rate limit for 10 seconds
./scripts/test-rate-limit.sh http://localhost:8080 100 10

# Test for 30 seconds
./scripts/test-rate-limit.sh http://localhost:8080 100 30
```

**Note**: Requires `bc` command (usually pre-installed on Linux/macOS)

## Quick Test Commands

### 1. Server Health Check
```bash
curl http://localhost:8080
```

### 2. Get Server Config
```bash
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getConfig","params":[]}'
```

### 3. Get Blockhash
```bash
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getBlockhash","params":[]}'
```

### 4. Liveness Check
```bash
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"liveness","params":[]}'
```

### 5. Quick Rate Limit Test (10 requests)
```bash
for i in {1..10}; do
  curl -s -X POST http://localhost:8080 \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","id":1,"method":"liveness","params":[]}' \
    -w "\nHTTP: %{http_code}\n" &
done
wait
```

## Understanding Rate Limit Results

### If Rate Limiting is Working:
- ✅ You'll see HTTP 429 responses
- ✅ Some requests will succeed (200)
- ✅ The ratio depends on your rate limit configuration

### If Rate Limiting is NOT Working:
- ⚠️ All requests return 200
- ⚠️ No 429 responses
- ⚠️ Check your `kora.mainnet.toml`:
  ```toml
  [kora]
  rate_limit = 100  # Should be set
  ```

### Expected Behavior:
- **Below rate limit**: All requests succeed (200)
- **At rate limit**: Mix of 200 and 429 responses
- **Above rate limit**: Mostly 429 responses

## Troubleshooting

### "Cannot connect to Kora server"
- Verify server is running: `./scripts/run-mainnet.sh`
- Check port: `lsof -ti:8080`

### "All requests fail"
- Check server logs
- Verify configuration is correct
- Test with a single request first

### "No rate limiting detected"
- Check `rate_limit` in `kora.mainnet.toml`
- Try sending more requests
- Increase test rate

### Getting-Started Examples Fail
- Verify `.env` file exists and has required variables
- Check that keypairs have funds (for mainnet)
- Ensure Kora server is running
- Check server logs for errors

## Next Steps

After testing:
1. Review rate limit configuration in `kora.mainnet.toml`
2. Adjust rate limits based on your needs
3. Enable authentication for production
4. Set up monitoring and alerts
5. Review security warnings from server startup

