#!/bin/bash

# Resolve a review thread by its GraphQL ID
# Usage: resolve_comment_thread.sh THREAD_ID [THREAD_ID2 ...]
#
# Note: This script REQUIRES user confirmation before modifying any data.
# It should only be called after explicit user approval.

set -euo pipefail

# Require at least one thread ID
if [[ $# -eq 0 ]]; then
    echo "❌ Error: At least one thread ID required."
    echo "Usage: resolve_comment_thread.sh THREAD_ID [THREAD_ID2 ...]"
    exit 1
fi

# Function to resolve a single thread
resolve_single_thread() {
    local THREAD_ID="$1"

    MUTATION='
mutation($threadId: ID!) {
  resolveReviewThread(input: {threadId: $threadId}) {
    thread {
      isResolved
      path
    }
  }
}'

    RESPONSE=$(gh api graphql \
        -f threadId="$THREAD_ID" \
        -f query="$MUTATION" 2>&1)

    # Check for GraphQL errors
    if echo "$RESPONSE" | jq -e '.errors' >/dev/null 2>&1; then
        echo "❌ Failed to resolve thread $THREAD_ID:"
        echo "$RESPONSE" | jq '.errors[]' 2>/dev/null || echo "$RESPONSE"
        return 1
    fi

    # Extract result safely
    RESOLVED=$(echo "$RESPONSE" | jq -r '.data.resolveReviewThread.thread.isResolved // "error"' 2>/dev/null)
    THREAD_PATH=$(echo "$RESPONSE" | jq -r '.data.resolveReviewThread.thread.path // "unknown"' 2>/dev/null)

    if [[ "$RESOLVED" == "true" ]]; then
        echo "✅ Resolved: $THREAD_PATH"
        return 0
    else
        echo "⚠️  Failed to resolve thread $THREAD_ID"
        return 1
    fi
}

# Resolve each provided thread ID
SUCCESS_COUNT=0
FAIL_COUNT=0

for THREAD_ID in "$@"; do
    if resolve_single_thread "$THREAD_ID"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi
done

# Summary
echo ""
if [[ $FAIL_COUNT -eq 0 ]]; then
    echo "✅ All $SUCCESS_COUNT thread(s) resolved successfully."
    exit 0
else
    echo "⚠️  Resolved: $SUCCESS_COUNT | Failed: $FAIL_COUNT"
    exit 1
fi
