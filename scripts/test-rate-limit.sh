#!/bin/bash

# Script to test Kora server rate limiting
# Usage: ./scripts/test-rate-limit.sh [KORA_URL] [REQUESTS_PER_SECOND] [DURATION_SECONDS]

set -e

KORA_URL=${1:-"http://localhost:8080"}
RATE_LIMIT=${2:-100}  # Expected rate limit from config
DURATION=${3:-10}     # Test duration in seconds
REQUESTS_PER_SECOND=$((RATE_LIMIT * 2))  # Send 2x the rate limit to test throttling

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kora Rate Limit Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Kora URL: $KORA_URL"
echo "Expected Rate Limit: $RATE_LIMIT requests/second"
echo "Test Rate: $REQUESTS_PER_SECOND requests/second"
echo "Duration: $DURATION seconds"
echo "Total Requests: $((REQUESTS_PER_SECOND * DURATION))"
echo ""

# Check if server is running
if ! curl -s "$KORA_URL" > /dev/null 2>&1; then
    echo "❌ Error: Cannot connect to Kora server at $KORA_URL"
    echo "   Make sure your server is running: ./scripts/run-mainnet.sh"
    exit 1
fi

echo "✅ Server is reachable"
echo ""
echo "Starting rate limit test..."
echo ""

# Create a temporary file for results
RESULTS_FILE=$(mktemp)
SUCCESS_COUNT=0
RATE_LIMIT_COUNT=0
ERROR_COUNT=0
TOTAL_REQUESTS=0

# Function to make a request
make_request() {
    local response=$(curl -s -w "\n%{http_code}" -X POST "$KORA_URL" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","id":1,"method":"liveness","params":[]}' \
        2>/dev/null)
    
    # Extract HTTP code (last line) - compatible with both GNU and BSD
    local http_code=$(echo "$response" | tail -n1)
    
    echo "$http_code" >> "$RESULTS_FILE"
    
    if [ "$http_code" = "200" ]; then
        ((SUCCESS_COUNT++))
    elif [ "$http_code" = "429" ]; then
        ((RATE_LIMIT_COUNT++))
    else
        ((ERROR_COUNT++))
    fi
    ((TOTAL_REQUESTS++))
}

# Calculate interval between requests (in microseconds)
# requests_per_second means 1 request every (1/requests_per_second) seconds
INTERVAL=$(echo "scale=6; 1000000 / $REQUESTS_PER_SECOND" | bc)

echo "Sending requests at $REQUESTS_PER_SECOND req/s..."
echo "Press Ctrl+C to stop early"
echo ""

# Start time
START_TIME=$(date +%s)
END_TIME=$((START_TIME + DURATION))

# Send requests
while [ $(date +%s) -lt $END_TIME ]; do
    make_request &
    
    # Sleep for the calculated interval (convert to seconds for sleep)
    sleep_seconds=$(echo "scale=6; $INTERVAL / 1000000" | bc)
    sleep "$sleep_seconds"
done

# Wait for all background jobs to complete
wait

# Calculate final statistics
FINAL_TIME=$(date +%s)
ACTUAL_DURATION=$((FINAL_TIME - START_TIME))
ACTUAL_RATE=$(echo "scale=2; $TOTAL_REQUESTS / $ACTUAL_DURATION" | bc)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Rate Limit Test Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Test Duration: $ACTUAL_DURATION seconds"
echo "Total Requests: $TOTAL_REQUESTS"
echo "Actual Rate: $ACTUAL_RATE requests/second"
echo ""
echo "Response Breakdown:"
echo "  ✅ Successful (200): $SUCCESS_COUNT"
echo "  ⚠️  Rate Limited (429): $RATE_LIMIT_COUNT"
echo "  ❌ Errors (other): $ERROR_COUNT"
echo ""

# Analyze results
if [ $RATE_LIMIT_COUNT -gt 0 ]; then
    RATE_LIMIT_PERCENTAGE=$(echo "scale=2; ($RATE_LIMIT_COUNT * 100) / $TOTAL_REQUESTS" | bc)
    echo "📊 Analysis:"
    echo "  Rate limiting is working! $RATE_LIMIT_PERCENTAGE% of requests were throttled"
    echo ""
    
    if [ $SUCCESS_COUNT -gt 0 ]; then
        SUCCESS_RATE=$(echo "scale=2; ($SUCCESS_COUNT * 100) / $TOTAL_REQUESTS" | bc)
        echo "  ✅ $SUCCESS_RATE% of requests succeeded"
    fi
    
    # Estimate effective rate limit
    if [ $ACTUAL_DURATION -gt 0 ]; then
        EFFECTIVE_RATE=$(echo "scale=2; $SUCCESS_COUNT / $ACTUAL_DURATION" | bc)
        echo "  📈 Effective rate: ~$EFFECTIVE_RATE requests/second"
    fi
else
    echo "⚠️  Warning: No rate limiting detected!"
    echo "   This could mean:"
    echo "   - Rate limit is higher than test rate"
    echo "   - Rate limiting is disabled"
    echo "   - Server is not enforcing limits"
    echo ""
    echo "   Try increasing the test rate or check your kora.toml configuration"
fi

# Clean up
rm -f "$RESULTS_FILE"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

