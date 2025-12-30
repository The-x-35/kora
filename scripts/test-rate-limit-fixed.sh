#!/bin/bash

# Fixed rate limit test script (macOS compatible)
# Usage: ./scripts/test-rate-limit-fixed.sh [KORA_URL] [NUM_REQUESTS] [REQUESTS_PER_SECOND]

set -e

KORA_URL=${1:-"http://localhost:8080"}
NUM_REQUESTS=${2:-200}
REQUESTS_PER_SECOND=${3:-150}  # Send more than rate limit (100) to test throttling

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kora Rate Limit Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Kora URL: $KORA_URL"
echo "Total Requests: $NUM_REQUESTS"
echo "Rate: $REQUESTS_PER_SECOND requests/second"
echo ""

# Check if server is running
if ! curl -s "$KORA_URL" > /dev/null 2>&1; then
    echo "❌ Error: Cannot connect to Kora server at $KORA_URL"
    exit 1
fi

echo "✅ Server is reachable"
echo ""
echo "Starting rate limit test..."
echo ""

# Create temp files for results
RESULTS_FILE=$(mktemp)
SUCCESS_FILE=$(mktemp)
RATELIMIT_FILE=$(mktemp)
ERROR_FILE=$(mktemp)

# Cleanup function
cleanup() {
    rm -f "$RESULTS_FILE" "$SUCCESS_FILE" "$RATELIMIT_FILE" "$ERROR_FILE" 2>/dev/null
}
trap cleanup EXIT

# Function to make a request and record result
make_request() {
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$KORA_URL" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","id":1,"method":"liveness","params":[]}' \
        2>/dev/null)
    
    echo "$http_code" >> "$RESULTS_FILE"
    
    case "$http_code" in
        200)
            echo "1" >> "$SUCCESS_FILE"
            ;;
        429)
            echo "1" >> "$RATELIMIT_FILE"
            ;;
        *)
            echo "1" >> "$ERROR_FILE"
            ;;
    esac
}

# Start time
START_TIME=$(date +%s.%N)

# Calculate delay between requests (in seconds)
DELAY=$(awk "BEGIN {printf \"%.6f\", 1.0 / $REQUESTS_PER_SECOND}")

# Send requests
for ((i=1; i<=NUM_REQUESTS; i++)); do
    make_request &
    
    # Show progress every 50 requests
    if [ $((i % 50)) -eq 0 ]; then
        echo -ne "\rProgress: $i/$NUM_REQUESTS requests sent..."
    fi
    
    # Sleep to maintain rate (except for last request)
    if [ $i -lt $NUM_REQUESTS ]; then
        sleep "$DELAY"
    fi
done

# Wait for all background jobs
wait

echo ""  # New line after progress

# Wait a moment for all responses
sleep 0.5

# Calculate statistics
END_TIME=$(date +%s.%N)
DURATION=$(awk "BEGIN {printf \"%.2f\", $END_TIME - $START_TIME}")

# Count results
SUCCESS_COUNT=$(wc -l < "$SUCCESS_FILE" 2>/dev/null | tr -d ' ' || echo "0")
RATE_LIMIT_COUNT=$(wc -l < "$RATELIMIT_FILE" 2>/dev/null | tr -d ' ' || echo "0")
ERROR_COUNT=$(wc -l < "$ERROR_FILE" 2>/dev/null | tr -d ' ' || echo "0")

# Calculate actual rate
if [ "$DURATION" != "0.00" ]; then
    ACTUAL_RATE=$(awk "BEGIN {printf \"%.2f\", $NUM_REQUESTS / $DURATION}")
else
    ACTUAL_RATE="N/A"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Rate Limit Test Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Test Duration: ${DURATION}s"
echo "Total Requests: $NUM_REQUESTS"
echo "Actual Rate: $ACTUAL_RATE requests/second"
echo ""
echo "Response Breakdown:"
echo "  ✅ Successful (200): $SUCCESS_COUNT"
echo "  ⚠️  Rate Limited (429): $RATE_LIMIT_COUNT"
echo "  ❌ Errors (other): $ERROR_COUNT"
echo ""

# Analyze results
if [ "$RATE_LIMIT_COUNT" -gt 0 ]; then
    PERCENTAGE=$(awk "BEGIN {printf \"%.1f\", ($RATE_LIMIT_COUNT * 100) / $NUM_REQUESTS}")
    echo "📊 Analysis:"
    echo "  ✅ Rate limiting is WORKING! $RATE_LIMIT_COUNT requests ($PERCENTAGE%) were throttled"
    echo ""
    if [ "$SUCCESS_COUNT" -gt 0 ]; then
        SUCCESS_PERCENT=$(awk "BEGIN {printf \"%.1f\", ($SUCCESS_COUNT * 100) / $NUM_REQUESTS}")
        echo "  ✅ $SUCCESS_COUNT requests ($SUCCESS_PERCENT%) succeeded"
    fi
else
    echo "⚠️  Warning: No rate limiting detected!"
    echo "   This could mean:"
    echo "   - Rate limit is higher than test rate ($REQUESTS_PER_SECOND req/s)"
    echo "   - Rate limiting is disabled in config"
    echo "   - Server is not enforcing limits"
    echo ""
    echo "   Check your kora.mainnet.toml: [kora] rate_limit = 100"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

