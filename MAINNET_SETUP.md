# Kora Mainnet Setup Guide

This guide will help you set up and run a Kora server on Solana mainnet.

## Prerequisites

1. **Rust 1.86+** - Install from [rustup.rs](https://rustup.rs/)
2. **Solana CLI 2.2+** - Install from [docs.solana.com](https://docs.solana.com/cli/install-solana-cli-tools)
3. **Redis** (optional, for caching and rate limiting) - Install from [redis.io](https://redis.io/download)
4. **Node.js 20+ and pnpm** (for getting-started example) - Install from [nodejs.org](https://nodejs.org/)

## Step 1: Generate Fee Payer Keypair

You need a Solana keypair that will be used to pay for transaction fees. This keypair must be funded with SOL.

```bash
# Generate a new keypair
solana-keygen new -o ~/.config/solana/mainnet-fee-payer.json

# Get the public key (you'll need this to fund the account)
solana-keygen pubkey ~/.config/solana/mainnet-fee-payer.json

# Export the private key in base58 format
# The private key is the first 64 bytes of the JSON file
cat ~/.config/solana/mainnet-fee-payer.json | jq -r '.[:64]' | base58
```

**Important:** Fund this account with SOL on mainnet. You can do this by:
1. Transferring SOL from another wallet
2. Using a faucet (if available)
3. Using a centralized exchange

## Step 2: Set Up Environment Variables

Create a `.env` file in the project root:

```bash
cp .env.example .env
```

Edit `.env` and set the following variables:

```bash
# Solana Mainnet RPC URL
RPC_URL=https://mainnet.helius-rpc.com/?api-key=d9b6d595-1feb-4741-8958-484ad55afdab

# Kora Fee Payer Private Key (Base58 encoded)
KORA_MAINNET_PRIVATE_KEY=your_base58_private_key_here

# Optional: API Key for authentication
# KORA_API_KEY=your-api-key-here

# Optional: HMAC Secret for request signature authentication
# KORA_HMAC_SECRET=your-hmac-secret-here
```

## Step 3: Configure Kora Server

The mainnet configuration files are already created:
- `kora.mainnet.toml` - Main server configuration
- `signers.mainnet.toml` - Signer configuration

Review and adjust these files as needed:

### Key Configuration Options in `kora.mainnet.toml`:

- **`rate_limit`**: Number of requests per second (default: 100)
- **`price_source`**: Set to "Jupiter" for mainnet (uses Jupiter price feeds)
- **`allowed_tokens`**: Tokens that can be used for payments (USDC, USDT by default)
- **`max_allowed_lamports`**: Maximum transaction size (default: 0.01 SOL)
- **`usage_limit`**: Per-wallet rate limiting (enabled by default)

### Rate Limiting Configuration:

```toml
[kora.usage_limit]
enabled = true
cache_url = "redis://localhost:6379"
max_transactions = 100  # Maximum transactions per wallet
fallback_if_unavailable = false  # Reject if Redis unavailable
```

**Note:** If you enable usage limiting, make sure Redis is running.

## Step 4: Start Redis (Optional but Recommended)

If you're using caching or usage limiting, start Redis:

```bash
# Using Docker
docker run -d -p 6379:6379 redis:latest

# Or using Homebrew (macOS)
brew services start redis

# Or using systemd (Linux)
sudo systemctl start redis
```

## Step 5: Build and Run the Server

### Build the project:

```bash
# Install dependencies
just install

# Build the project
just build
```

### Run the server:

```bash
# Using the mainnet configuration
# Note: --config and --rpc-url are global arguments, so they come before 'rpc start'
kora --config kora.mainnet.toml --rpc-url "$RPC_URL" rpc start --signers-config signers.mainnet.toml --port 8080
```

Or using environment variables:

```bash
export RPC_URL="https://mainnet.helius-rpc.com/?api-key=d9b6d595-1feb-4741-8958-484ad55afdab"
export KORA_MAINNET_PRIVATE_KEY="your_base58_private_key"

kora --config kora.mainnet.toml --rpc-url "$RPC_URL" rpc start --signers-config signers.mainnet.toml --port 8080
```

The server will start on `http://localhost:8080` by default.

## Step 6: Verify the Server is Running

Test the server:

```bash
# Check liveness
curl http://localhost:8080

# Get server config
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getConfig","params":[]}'
```

## Step 7: Run the Getting-Started Example

Navigate to the getting-started example:

```bash
cd examples/getting-started/demo/client
pnpm install
```

Update the client configuration in `src/full-demo.ts` or `src/quick-start.ts` to use mainnet:

```typescript
const CONFIG = {
  solanaRpcUrl: process.env.RPC_URL || "https://mainnet.helius-rpc.com/?api-key=d9b6d595-1feb-4741-8958-484ad55afdab",
  solanaWsUrl: "wss://mainnet.helius-rpc.com/?api-key=d9b6d595-1feb-4741-8958-484ad55afdab",
  koraRpcUrl: "http://localhost:8080/",
};
```

Run the example:

```bash
pnpm start  # Quick start
# or
pnpm full-demo  # Full demo
```

## Configuration Details

### Rate Limiting

Kora supports multiple levels of rate limiting:

1. **Global Rate Limit** (`kora.rate_limit`): Requests per second across all clients
2. **Usage Limit** (`kora.usage_limit`): Per-wallet transaction limits
   - Requires Redis for distributed rate limiting
   - `max_transactions`: Maximum transactions per wallet
   - `fallback_if_unavailable`: Whether to allow requests if Redis is down

### Authentication

You can secure your Kora server with:

1. **API Key**: Simple authentication via `KORA_API_KEY` env var or config
2. **HMAC**: More secure signature-based authentication via `KORA_HMAC_SECRET`

### Monitoring

Metrics are available at `http://localhost:8080/metrics` (Prometheus format).

## Troubleshooting

### Server won't start

1. Check that the private key is correctly set in `.env`
2. Verify the RPC URL is accessible
3. Ensure the fee payer account has SOL
4. Check logs for specific error messages

### Rate limiting not working

1. Ensure Redis is running if `usage_limit.enabled = true`
2. Check Redis connection URL in config
3. Verify `fallback_if_unavailable` setting

### Transaction failures

1. Ensure fee payer has sufficient SOL
2. Check `max_allowed_lamports` setting
3. Verify allowed programs and tokens in config
4. Check transaction size limits

## Security Best Practices

1. **Never commit private keys** - Use environment variables
2. **Use authentication** - Enable API key or HMAC authentication
3. **Monitor usage** - Set up alerts for unusual activity
4. **Limit transaction size** - Configure `max_allowed_lamports` appropriately
5. **Use Redis for rate limiting** - Prevents abuse across multiple instances
6. **Regularly update** - Keep Kora and dependencies up to date

## Next Steps

- Read the [full documentation](https://launch.solana.com/docs/kora)
- Explore the [API reference](https://launch.solana.com/docs/kora/json-rpc-api)
- Check out [examples](examples/) for more use cases

