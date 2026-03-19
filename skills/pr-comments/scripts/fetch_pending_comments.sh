#!/bin/bash

# Fetch unresolved (PENDING) review comments from a GitHub PR
# Usage: fetch_pending_comments.sh [PR_NUMBER_OR_URL]

set -euo pipefail

# Fetch unresolved review comments from a GitHub PR
# Usage:
#   fetch_pending_comments.sh OWNER REPO PR_NUMBER
#   fetch_pending_comments.sh https://github.com/owner/repo/pull/123

if [[ $# -eq 0 ]]; then
    echo "❌ Error: Missing arguments."
    echo ""
    echo "Usage:"
    echo "  Option A (URL):  fetch_pending_comments.sh https://github.com/owner/repo/pull/123"
    echo "  Option B (args): fetch_pending_comments.sh owner repo 123"
    exit 1
fi

# Parse input: either a URL, a single PR number, or three arguments
if [[ $# -eq 1 ]]; then
    INPUT="$1"
    # Case 1: GitHub URL
    if [[ $INPUT =~ github\.com/([^/]+)/([^/]+)/pull/([0-9]+) ]]; then
        OWNER="${BASH_REMATCH[1]}"
        REPO_NAME="${BASH_REMATCH[2]}"
        PR_NUMBER="${BASH_REMATCH[3]}"
    # Case 2: Numeric PR number only
    elif [[ $INPUT =~ ^[0-9]+$ ]]; then
        PR_NUMBER="$INPUT"
        # Detect current repo using gh cli
        if ! REPO_JSON=$(gh repo view --json owner,name 2>/dev/null); then
            echo "❌ Error: Could not detect current repository. Please provide a full URL or owner/repo/number."
            exit 1
        fi
        OWNER=$(echo "$REPO_JSON" | /usr/bin/jq -r '.owner.login')
        REPO_NAME=$(echo "$REPO_JSON" | /usr/bin/jq -r '.name')
    else
        echo "❌ Error: Invalid input format. Expected a GitHub URL or a numeric PR number."
        echo "Got: $INPUT"
        exit 1
    fi
elif [[ $# -eq 3 ]]; then
    # Parse explicit owner/repo/number format
    OWNER="$1"
    REPO_NAME="$2"
    PR_NUMBER="$3"

    # Validate PR_NUMBER is numeric
    if ! [[ $PR_NUMBER =~ ^[0-9]+$ ]]; then
        echo "❌ Error: PR_NUMBER must be numeric. Got: $PR_NUMBER"
        exit 1
    fi
else
    echo "❌ Error: Invalid number of arguments ($#)."
    echo ""
    echo "Usage:"
    echo "  Option A (URL):  fetch_pending_comments.sh https://github.com/owner/repo/pull/123"
    echo "  Option B (args): fetch_pending_comments.sh owner repo 123"
    exit 1
fi

# GraphQL query to fetch unresolved review threads
QUERY='
query($owner: String!, $name: String!, $pullNumber: Int!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $pullNumber) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          path
          line
          startLine
          comments(first: 1) {
            nodes {
              author { login }
              body
            }
          }
        }
      }
    }
  }
}'

# Fetch data
RESPONSE=$(gh api graphql \
    -F owner="$OWNER" \
    -F name="$REPO_NAME" \
    -F pullNumber="$PR_NUMBER" \
    -f query="$QUERY" 2>&1)

# Check for GraphQL errors
if echo "$RESPONSE" | /usr/bin/jq -e '.errors' >/dev/null 2>&1; then
    echo "❌ GraphQL Error:"
    echo "$RESPONSE" | /usr/bin/jq '.errors'
    exit 1
fi

# Filter and format unresolved comments
PENDING_COUNT=$(echo "$RESPONSE" | /usr/bin/jq '[.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false)] | length')

if [[ "$PENDING_COUNT" -eq 0 ]]; then
    echo "✅ No pending comments found in $OWNER/$REPO_NAME#$PR_NUMBER"
    exit 0
fi

echo "📋 Found $PENDING_COUNT pending comment(s) in $OWNER/$REPO_NAME#$PR_NUMBER"
echo ""

# Output unresolved comments in a clean format
echo "$RESPONSE" | /usr/bin/jq -r '
.data.repository.pullRequest.reviewThreads.nodes[]
| select(.isResolved == false)
| {
    id: .id,
    path: .path,
    line: (if .startLine and .startLine != .line then "\(.startLine)-\(.line)" else "\(.line)" end),
    author: .comments.nodes[0].author.login,
    body: (.comments.nodes[0].body | gsub("\n"; " "))
  }
| "ID: \(.id) | \(.path):\(.line) | @\(.author): \(.body)"
'
