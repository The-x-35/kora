#!/bin/bash

# Burst rate limit test - sends many requests quickly to test rate limiting
# Usage: ./scripts/test-rate-limit-burst.sh [KORA_URL] [NUM_REQUESTS]

set -e

KORA_URL=${1:-"http://localhost:8080"}
NUM_REQUESTS=${2:-250}  # Send more than rate limit (100) in a burst

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kora Rate Limit Test (Burst)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Kora URL: $KORA_URL"
echo "Total Requests: $NUM_REQUESTS (burst - all at once)"
echo "Expected Rate Limit: 100 requests/second"
echo ""

# Check if server is running
if ! curl -s "$KORA_URL" > /dev/null 2>&1; then
    echo "❌ Error: Cannot connect to Kora server at $KORA_URL"
    exit 1
fi

echo "✅ Server is reachable"
echo ""
echo "Sending $NUM_REQUESTS requests in a burst..."
echo ""

# Create temp files
RESULTS_FILE=$(mktemp)
SUCCESS_COUNT=0
RATE_LIMIT_COUNT=0
ERROR_COUNT=0

# Function to make a request
make_request() {
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$KORA_URL" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","id":1,"method":"liveness","params":[]}' \
        2>/dev/null)
    
    echo "$http_code" >> "$RESULTS_FILE"
    
    case "$http_code" in
        200)
            ((SUCCESS_COUNT++))
            ;;
        429)
            ((RATE_LIMIT_COUNT++))
            ;;
        *)
            ((ERROR_COUNT++))
            ;;
    esac
}

# Start time
START_TIME=$(date +%s.%N)

# Send all requests in parallel (burst)
for ((i=1; i<=NUM_REQUESTS; i++)); do
    make_request &
done

# Wait for all requests
wait

END_TIME=$(date +%s.%N)
DURATION=$(awk "BEGIN {printf \"%.2f\", $END_TIME - $START_TIME}")

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Rate Limit Test Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Test Duration: ${DURATION}s"
echo "Total Requests: $NUM_REQUESTS"
echo ""
echo "Response Breakdown:"
echo "  ✅ Successful (200): $SUCCESS_COUNT"
echo "  ⚠️  Rate Limited (429): $RATE_LIMIT_COUNT"
echo "  ❌ Errors (other): $ERROR_COUNT"
echo ""

# Analyze
if [ $RATE_LIMIT_COUNT -gt 0 ]; then
    PERCENT=$(awk "BEGIN {printf \"%.1f\", ($RATE_LIMIT_COUNT * 100) / $NUM_REQUESTS}")
    echo "✅ Rate limiting is WORKING!"
    echo "   $RATE_LIMIT_COUNT requests ($PERCENT%) were rate limited"
else
    echo "⚠️  No rate limiting detected!"
    echo "   All $NUM_REQUESTS requests succeeded"
    echo ""
    echo "   Possible reasons:"
    echo "   - Rate limit might be per-second, not total"
    echo "   - Rate limiting might be per-IP or per-connection"
    echo "   - Check server logs for rate limit messages"
fi

# Cleanup
rm -f "$RESULTS_FILE"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

