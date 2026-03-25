#!/bin/bash

# Helper script to detect git repository context
# Outputs JSON with repo detection status and suggestions
# Exit codes: 0 = success, 1 = not in a git repo

set -euo pipefail

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    # Not in a git repo - provide helpful output
    cat <<'EOF'
{
  "in_git_repo": false,
  "owner": null,
  "repo_name": null,
  "error": "Not in a git repository",
  "suggestion": "Use one of these alternatives:\n  • Option B (URL): bash scripts/fetch_pending_comments.sh https://github.com/owner/repo/pull/123\n  • Option C (explicit): bash scripts/fetch_pending_comments.sh owner repo 123"
}
EOF
    exit 1
fi

# We're in a git repo - try to detect owner and repo
if REPO_JSON=$(gh repo view --json owner,name 2>/dev/null); then
    OWNER=$(echo "$REPO_JSON" | jq -r '.owner.login')
    REPO_NAME=$(echo "$REPO_JSON" | jq -r '.name')

    cat <<EOF
{
  "in_git_repo": true,
  "owner": "$OWNER",
  "repo_name": "$REPO_NAME",
  "error": null,
  "suggestion": null
}
EOF
    exit 0
else
    # In a git repo but gh command failed
    cat <<'EOF'
{
  "in_git_repo": true,
  "owner": null,
  "repo_name": null,
  "error": "gh repo view command failed",
  "suggestion": "This can happen if:\n  • GitHub CLI is not authenticated (run: gh auth login)\n  • Remote origin is not a GitHub repository\n  • GitHub CLI is not installed\n\nFallback options:\n  • Use explicit args: bash scripts/fetch_pending_comments.sh owner repo 123\n  • Use full URL: bash scripts/fetch_pending_comments.sh https://github.com/owner/repo/pull/123"
}
EOF
    exit 1
fi
