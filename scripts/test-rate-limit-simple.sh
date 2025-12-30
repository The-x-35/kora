#!/bin/bash

# Simple rate limit test script (no external dependencies)
# Usage: ./scripts/test-rate-limit-simple.sh [KORA_URL] [NUM_REQUESTS] [CONCURRENT]

set -e

KORA_URL=${1:-"http://localhost:8080"}
NUM_REQUESTS=${2:-200}  # Total number of requests
CONCURRENT=${3:-10}      # Number of concurrent requests

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kora Rate Limit Test (Simple)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Kora URL: $KORA_URL"
echo "Total Requests: $NUM_REQUESTS"
echo "Concurrent: $CONCURRENT"
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
echo "Press Ctrl+C to stop"
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
    
    local http_code=$(echo "$response" | tail -n1)
    
    # Thread-safe counter update using file locking
    (
        flock -x 200
        echo "$http_code" >> "$RESULTS_FILE"
        
        if [ "$http_code" = "200" ]; then
            echo "SUCCESS" >> "$RESULTS_FILE.success"
        elif [ "$http_code" = "429" ]; then
            echo "RATE_LIMIT" >> "$RESULTS_FILE.ratelimit"
        else
            echo "ERROR" >> "$RESULTS_FILE.error"
        fi
    ) 200>"$RESULTS_FILE.lock"
}

# Start time
START_TIME=$(date +%s.%N)

# Send requests in batches
REMAINING=$NUM_REQUESTS
BATCH_NUM=0

while [ $REMAINING -gt 0 ]; do
    BATCH_SIZE=$((REMAINING < CONCURRENT ? REMAINING : CONCURRENT))
    BATCH_NUM=$((BATCH_NUM + 1))
    
    # Launch batch of concurrent requests
    for ((i=0; i<BATCH_SIZE; i++)); do
        make_request &
    done
    
    # Wait for batch to complete
    wait
    
    REMAINING=$((REMAINING - BATCH_SIZE))
    
    # Show progress
    if [ $((BATCH_NUM % 10)) -eq 0 ] || [ $REMAINING -eq 0 ]; then
        echo -ne "\rProgress: $((NUM_REQUESTS - REMAINING))/$NUM_REQUESTS requests sent..."
    fi
done

echo ""  # New line after progress

# Wait a bit for all responses
sleep 1

# Calculate final statistics
END_TIME=$(date +%s.%N)
DURATION=$(echo "$END_TIME - $START_TIME" | bc 2>/dev/null || echo "0")

# Count results
if [ -f "$RESULTS_FILE.success" ]; then
    SUCCESS_COUNT=$(wc -l < "$RESULTS_FILE.success" | tr -d ' ')
else
    SUCCESS_COUNT=0
fi

if [ -f "$RESULTS_FILE.ratelimit" ]; then
    RATE_LIMIT_COUNT=$(wc -l < "$RESULTS_FILE.ratelimit" | tr -d ' ')
else
    RATE_LIMIT_COUNT=0
fi

if [ -f "$RESULTS_FILE.error" ]; then
    ERROR_COUNT=$(wc -l < "$RESULTS_FILE.error" | tr -d ' ')
else
    ERROR_COUNT=0
fi

TOTAL_REQUESTS=$NUM_REQUESTS

# Calculate rate
if [ -n "$DURATION" ] && [ "$(echo "$DURATION > 0" | bc 2>/dev/null || echo 0)" = "1" ]; then
    ACTUAL_RATE=$(echo "scale=2; $TOTAL_REQUESTS / $DURATION" | bc 2>/dev/null || echo "N/A")
else
    ACTUAL_RATE="N/A"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Rate Limit Test Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
if [ "$DURATION" != "0" ]; then
    echo "Test Duration: ${DURATION}s"
    echo "Actual Rate: $ACTUAL_RATE requests/second"
fi
echo "Total Requests: $TOTAL_REQUESTS"
echo ""
echo "Response Breakdown:"
echo "  ✅ Successful (200): $SUCCESS_COUNT"
echo "  ⚠️  Rate Limited (429): $RATE_LIMIT_COUNT"
echo "  ❌ Errors (other): $ERROR_COUNT"
echo ""

# Analyze results
if [ $RATE_LIMIT_COUNT -gt 0 ]; then
    echo "📊 Analysis:"
    echo "  ✅ Rate limiting is working! $RATE_LIMIT_COUNT requests were throttled"
    echo ""
    if [ $SUCCESS_COUNT -gt 0 ]; then
        echo "  ✅ $SUCCESS_COUNT requests succeeded"
    fi
else
    echo "⚠️  Warning: No rate limiting detected!"
    echo "   This could mean:"
    echo "   - Rate limit is higher than test rate"
    echo "   - Rate limiting is disabled"
    echo "   - Server is not enforcing limits"
fi

# Clean up
rm -f "$RESULTS_FILE"* "$RESULTS_FILE.lock" 2>/dev/null

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

