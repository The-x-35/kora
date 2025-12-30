# Quick Start: Running Kora on Mainnet

This is a quick guide to get your Kora server running on Solana mainnet.

## Prerequisites Check

1. ✅ Private key added to `.env` file as `KORA_MAINNET_PRIVATE_KEY`
2. ✅ Private key account funded with SOL on mainnet
3. ✅ RPC URL configured in `.env` file

## Step 1: Verify Setup

Run the verification script:

```bash
chmod +x scripts/verify-setup.sh
./scripts/verify-setup.sh
```

This will check:
- `.env` file exists and has required variables
- Configuration files are present
- Kora binary is available

## Step 2: Start the Server

### Option A: Using the helper script (Recommended)

```bash
chmod +x scripts/run-mainnet.sh
./scripts/run-mainnet.sh
```

### Option B: Manual start

```bash
# Load environment variables
export $(cat .env | grep -v '^#' | xargs)

# Start the server
# Note: --config and --rpc-url are global arguments, so they come before 'rpc start'
kora --config kora.mainnet.toml --rpc-url "$RPC_URL" rpc start --signers-config signers.mainnet.toml --port 8080
```

### Option C: Using cargo (if kora binary not installed)

```bash
export $(cat .env | grep -v '^#' | xargs)

cargo run --release -- --config kora.mainnet.toml --rpc-url "$RPC_URL" rpc start --signers-config signers.mainnet.toml --port 8080
```

## Step 3: Verify Server is Running

In another terminal, test the server:

```bash
# Check liveness
curl http://localhost:8080

# Get server config
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getConfig","params":[]}'
```

You should see a JSON response with the server configuration.

## Step 4: Run the Getting-Started Example

Navigate to the example directory:

```bash
cd examples/getting-started/demo/client
pnpm install
```

The example is already configured to connect to `http://localhost:8080` by default.

Run the quick start:

```bash
pnpm start
```

Or run the full demo:

```bash
pnpm full-demo
```

## Troubleshooting

### Server won't start

1. **Check private key format**: The private key should be base58 encoded (64 characters)
2. **Verify RPC URL**: Test the RPC URL with curl
3. **Check account balance**: Ensure the fee payer account has SOL
4. **Check logs**: Look for error messages in the server output

### "Failed to initialize signer"

- Verify `KORA_MAINNET_PRIVATE_KEY` is set correctly in `.env`
- Check that the private key is in base58 format
- Ensure the environment variable name matches `signers.mainnet.toml`

### "Connection refused" or "Cannot connect to RPC"

- Verify the RPC URL is correct and accessible
- Check your internet connection
- Try the RPC URL in a browser or with curl

### Rate limiting issues

If you enabled usage limiting and Redis is not running:

```bash
# Start Redis with Docker
docker run -d -p 6379:6379 redis:latest

# Or disable usage limiting in kora.mainnet.toml
# Set [kora.usage_limit] enabled = false
```

## Next Steps

- Read [MAINNET_SETUP.md](MAINNET_SETUP.md) for detailed configuration options
- Explore the [API documentation](https://launch.solana.com/docs/kora/json-rpc-api)
- Check out [examples/](examples/) for more use cases

## Configuration Files

- **kora.mainnet.toml**: Main server configuration (rate limits, validation rules, etc.)
- **signers.mainnet.toml**: Signer configuration (which private key to use)
- **.env**: Environment variables (private key, RPC URL)

## Security Reminders

- ⚠️ Never commit your `.env` file to git
- ⚠️ Keep your private key secure
- ⚠️ Consider enabling authentication (API key or HMAC) for production
- ⚠️ Monitor your fee payer account balance

