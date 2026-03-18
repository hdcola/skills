#!/bin/bash

# Fetch unresolved (PENDING) review comments from a GitHub PR
# Usage: fetch_pending_comments.sh [PR_NUMBER_OR_URL]

set -euo pipefail

# Parse input: PR number or GitHub URL
INPUT="${1:-}"

# If no input provided, try to get the current PR number
if [[ -z "$INPUT" ]]; then
    INPUT=$(gh pr view --json number -q .number 2>/dev/null || echo "")
    if [[ -z "$INPUT" ]]; then
        echo "❌ Error: Could not determine PR. Please provide a PR number or GitHub URL."
        exit 1
    fi
fi

# Determine repo and PR number
if [[ $INPUT =~ github\.com/([^/]+)/([^/]+)/pull/([0-9]+) ]]; then
    OWNER="${BASH_REMATCH[1]}"
    REPO_NAME="${BASH_REMATCH[2]}"
    PR_NUMBER="${BASH_REMATCH[3]}"
elif [[ $INPUT =~ ^[0-9]+$ ]]; then
    # Get default repo info
    REPO_INFO=$(gh repo view --json owner,name -q '.owner.login + " " + .name' 2>/dev/null)
    if [[ -z "$REPO_INFO" ]]; then
        echo "❌ Error: Could not determine default repository. Please provide a full GitHub URL."
        exit 1
    fi
    read -r OWNER REPO_NAME <<< "$REPO_INFO"
    PR_NUMBER="$INPUT"
else
    echo "❌ Error: Input must be a PR number or GitHub URL (e.g., 123 or https://github.com/owner/repo/pull/123)."
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
