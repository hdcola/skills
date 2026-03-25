#!/bin/bash

# Fetch unresolved (PENDING) review comments from a GitHub PR
# Usage:
#   fetch_pending_comments.sh                        (auto-detect from current branch)
#   fetch_pending_comments.sh PR_NUMBER              (auto-detect repo, works from anywhere)
#   fetch_pending_comments.sh https://github.com/owner/repo/pull/123
#   fetch_pending_comments.sh OWNER REPO PR_NUMBER

set -euo pipefail

# Function to check if a command exists
require_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "❌ Error: '$cmd' is not installed or not in PATH." >&2
        echo "" >&2
        if [ "$cmd" = "gh" ]; then
            echo "Install GitHub CLI: https://cli.github.com" >&2
            echo "Or authenticate: gh auth login" >&2
        elif [ "$cmd" = "git" ]; then
            echo "Install Git: https://git-scm.com/downloads" >&2
        elif [ "$cmd" = "jq" ]; then
            echo "Install jq: https://stedolan.github.io/jq/download/" >&2
        fi
        exit 1
    fi
}

# Check for common dependencies (always needed)
require_cmd "gh"
require_cmd "jq"

# Note: git is checked conditionally below based on input format

# Determine whether to use colors in output
COLOR_ENABLED=true
if [ ! -t 1 ] || [ -n "${NO_COLOR-}" ]; then
    COLOR_ENABLED=false
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_error() {
    if [ "$COLOR_ENABLED" = true ]; then
        echo -e "${RED}❌ Error: $1${NC}" >&2
    else
        echo "❌ Error: $1" >&2
    fi
}

print_info() {
    if [ "$COLOR_ENABLED" = true ]; then
        echo -e "${GREEN}$1${NC}"
    else
        echo "$1"
    fi
}

print_debug() {
    if [ "$COLOR_ENABLED" = true ]; then
        echo -e "${BLUE}ℹ️  $1${NC}" >&2
    else
        echo "ℹ️  $1" >&2
    fi
}

print_help() {
    cat >&2 <<'EOF'
Usage:
  Option 0 (current branch): fetch_pending_comments.sh
                             (queries the PR for your current branch)
                             (must run from inside a git repo with a remote configured)

  Option A (PR number):      fetch_pending_comments.sh 216
                             (⭐ RECOMMENDED - auto-detects repo)
                             (must run from inside a git repo)

  Option B (GitHub URL):     fetch_pending_comments.sh https://github.com/owner/repo/pull/123
                             (explicit, works from anywhere)

  Option C (explicit args):  fetch_pending_comments.sh owner repo 123
                             (works from anywhere, requires knowing repo details)
EOF
}

# Validate working directory context (for PR number auto-detection)
validate_git_context() {
    # Check if we're in a git repo
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        return 1
    fi

    # Check if any remote is configured (origin, upstream, or others)
    if ! git remote >/dev/null 2>&1 || [ -z "$(git remote 2>/dev/null)" ]; then
        # Try fallback: let gh determine the repo context
        if ! gh repo view >/dev/null 2>&1; then
            return 1
        fi
    fi

    return 0
}

# Verify detected repo actually exists and is accessible
verify_repo_exists() {
    local owner="$1"
    local repo="$2"
    local api_error

    # Try to fetch basic repo info to verify it's accessible
    api_error=$(gh api repos/"$owner"/"$repo" --jq .name 2>&1) || {
        # Check if it's an auth issue
        if echo "$api_error" | grep -qi "unauthorized\|authentication\|forbidden"; then
            return 2  # Auth error
        elif echo "$api_error" | grep -qi "rate limit"; then
            return 3  # Rate limit
        else
            return 1  # Repo not found or other error
        fi
    }

    return 0
}

# Get PR number from current branch
get_pr_from_current_branch() {
    local branch_name
    local pr_number

    # Get current branch name
    if ! branch_name=$(git rev-parse --abbrev-ref HEAD 2>/dev/null); then
        print_error "Could not determine current branch."
        return 1
    fi

    if [[ "$branch_name" == "HEAD" ]]; then
        print_error "You are in detached HEAD state. Cannot determine PR from branch."
        echo "" >&2
        echo -e "${YELLOW}Solutions:${NC}" >&2
        echo "  • Switch to a branch: git checkout <branch-name>" >&2
        echo "  • Or provide PR number explicitly: fetch_pending_comments.sh <PR_NUMBER>" >&2
        return 1
    fi

    print_debug "Current branch: $branch_name"

    # Query for PR associated with this branch
    if ! pr_number=$(gh pr list --head "$branch_name" --json number --jq '.[0].number' 2>/dev/null); then
        print_error "Could not query PR for branch '$branch_name'."
        echo "" >&2
        echo -e "${YELLOW}Possible causes:${NC}" >&2
        echo "  • No PR exists for this branch" >&2
        echo "  • You don't have permissions" >&2
        echo "  • GitHub CLI is not authenticated" >&2
        return 1
    fi

    # Check if we got a valid PR number
    if [[ -z "$pr_number" ]] || [[ "$pr_number" == "null" ]]; then
        print_error "No PR found for branch '$branch_name'."
        echo "" >&2
        echo -e "${YELLOW}Solutions:${NC}" >&2
        echo "  • Make sure the branch has a PR open on GitHub" >&2
        echo "  • Or provide PR number explicitly: fetch_pending_comments.sh <PR_NUMBER>" >&2
        return 1
    fi

    echo "$pr_number"
    return 0
}

# Parse input: no args (current branch), PR number, URL, or three arguments
if [[ $# -eq 0 ]]; then
    # Option 0: No arguments - query from current branch (requires git)
    require_cmd "git"
    if ! validate_git_context; then
        print_error "Branch-based PR lookup requires running from a git repository."
        echo "" >&2
        echo -e "${YELLOW}Solutions:${NC}" >&2
        echo "  1. Run from your project root directory" >&2
        echo "  2. Or provide PR number: fetch_pending_comments.sh <PR_NUMBER>" >&2
        echo "  3. Or use explicit format: fetch_pending_comments.sh OWNER REPO <PR_NUMBER>" >&2
        exit 1
    fi

    if ! PR_NUMBER=$(get_pr_from_current_branch); then
        exit 1
    fi

    # Now auto-detect owner/repo like we do for PR numbers
    if REPO_JSON=$(gh repo view --json owner,name 2>/dev/null); then
        OWNER=$(echo "$REPO_JSON" | jq -r '.owner.login' 2>/dev/null || echo "")
        REPO_NAME=$(echo "$REPO_JSON" | jq -r '.name' 2>/dev/null || echo "")

        if [[ -z "$OWNER" ]] || [[ -z "$REPO_NAME" ]]; then
            print_error "Failed to parse repository information from 'gh repo view'."
            exit 1
        fi

        print_debug "Auto-detected repo: $OWNER/$REPO_NAME"
    else
        print_error "Could not retrieve repository information."
        exit 1
    fi

elif [[ $# -eq 1 ]]; then
    INPUT="$1"
    # Case 1: GitHub PR URL
    if [[ $INPUT =~ ^https?://(www\.)?github\.com/([^/]+)/([^/]+)/pull/([0-9]+)(\?.*)?$ ]]; then
        OWNER="${BASH_REMATCH[2]}"
        REPO_NAME="${BASH_REMATCH[3]}"
        PR_NUMBER="${BASH_REMATCH[4]}"
    # Case 2: Numeric PR number only - auto-detect repo (requires git)
    elif [[ $INPUT =~ ^[0-9]+$ ]]; then
        PR_NUMBER="$INPUT"

        # Require git for auto-detection
        require_cmd "git"

        # Validate we're in a proper git repo context
        if ! validate_git_context; then
            print_error "PR number auto-detection requires running from a git repository."
            echo "" >&2
            echo -e "${YELLOW}Current working directory:${NC} $(pwd)" >&2
            echo -e "${YELLOW}Why this failed:${NC}" >&2
            echo "  • You're not in a git directory, OR" >&2
            echo "  • The git repository has no remotes configured" >&2
            echo "" >&2
            echo -e "${YELLOW}Solutions:${NC}" >&2
            echo "  1. Run from your project's root directory (where .git is located)" >&2
            echo "  2. Or use explicit owner/repo format:" >&2
            echo "     bash scripts/fetch_pending_comments.sh OWNER REPO $PR_NUMBER" >&2
            echo "  3. Or use a GitHub URL:" >&2
            echo "     bash scripts/fetch_pending_comments.sh https://github.com/OWNER/REPO/pull/$PR_NUMBER" >&2
            exit 1
        fi

        # Try to detect repo from current git context
        if REPO_JSON=$(gh repo view --json owner,name 2>/dev/null); then
            OWNER=$(echo "$REPO_JSON" | jq -r '.owner.login' 2>/dev/null || echo "")
            REPO_NAME=$(echo "$REPO_JSON" | jq -r '.name' 2>/dev/null || echo "")

            # Validate we got valid values
            if [[ -z "$OWNER" ]] || [[ -z "$REPO_NAME" ]]; then
                print_error "Failed to parse repository information from 'gh repo view'."
                echo "" >&2
                echo -e "${YELLOW}Response was:${NC}" >&2
                echo "  $REPO_JSON" >&2
                echo "" >&2
                echo -e "${YELLOW}This might indicate:${NC}" >&2
                echo "  • The JSON format from GitHub CLI changed" >&2
                echo "  • Or jq is not parsing the response correctly" >&2
                echo "" >&2
                echo -e "${YELLOW}Try using explicit format instead:${NC}" >&2
                echo "  bash scripts/fetch_pending_comments.sh OWNER REPO $PR_NUMBER" >&2
                exit 1
            fi

            # Provide debug info on successful detection
            print_debug "Auto-detected repo: $OWNER/$REPO_NAME"
        else
            print_error "Could not retrieve repository information via 'gh repo view'."
            echo "" >&2
            echo -e "${YELLOW}Troubleshooting:${NC}" >&2
            echo "  • Is GitHub CLI authenticated? Run: gh auth status" >&2
            echo "  • Is the current directory a GitHub repository? Run: git remote -v" >&2
            echo "  • Do you have permissions to access this repository?" >&2
            echo "" >&2
            echo -e "${YELLOW}Use one of these instead:${NC}" >&2
            echo "  • Option C: bash scripts/fetch_pending_comments.sh OWNER REPO $PR_NUMBER" >&2
            echo "  • Option B: bash scripts/fetch_pending_comments.sh https://github.com/OWNER/REPO/pull/$PR_NUMBER" >&2
            exit 1
        fi
    else
        print_error "Invalid input format. Expected a PR number, GitHub URL, or owner/repo/number."
        echo "Got: $INPUT" >&2
        echo "" >&2
        print_help
        exit 1
    fi
elif [[ $# -eq 3 ]]; then
    # Parse explicit owner/repo/number format
    OWNER="$1"
    REPO_NAME="$2"
    PR_NUMBER="$3"

    # Validate PR_NUMBER is numeric
    if ! [[ $PR_NUMBER =~ ^[0-9]+$ ]]; then
        print_error "PR_NUMBER must be numeric. Got: $PR_NUMBER"
        exit 1
    fi
else
    print_error "Invalid number of arguments ($#). Expected 1 or 3."
    echo "" >&2
    print_help
    exit 1
fi

# Verify repo exists and is accessible
verify_repo_exists "$OWNER" "$REPO_NAME" >/dev/null 2>&1 || {
    ret=$?
    case $ret in
        2)
            print_error "GitHub authentication failed for repository '$OWNER/$REPO_NAME'."
            echo "" >&2
            echo -e "${YELLOW}Solutions:${NC}" >&2
            echo "  • Authenticate with GitHub: gh auth login" >&2
            echo "  • Or check your token: gh auth status" >&2
            ;;
        3)
            print_error "GitHub API rate limit exceeded."
            echo "" >&2
            echo -e "${YELLOW}Solution:${NC}" >&2
            echo "  • Wait a few minutes before retrying" >&2
            ;;
        *)
            print_error "Repository '$OWNER/$REPO_NAME' not found or not accessible."
            echo "" >&2
            echo -e "${YELLOW}Possible causes:${NC}" >&2
            echo "  • The repository doesn't exist" >&2
            echo "  • You don't have access to it" >&2
            echo "  • You ran the script from the wrong directory (wrong git repo detected)" >&2
            echo "" >&2
            echo -e "${YELLOW}Recommendation:${NC}" >&2
            echo "  Make sure you're running this from your project root directory." >&2
            echo "  Or use explicit repo details:" >&2
            echo "    bash scripts/fetch_pending_comments.sh OWNER REPO $PR_NUMBER" >&2
            ;;
    esac
    exit 1
}

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

# Fetch data - capture both stdout and exit code
if ! RESPONSE=$(gh api graphql \
    -F owner="$OWNER" \
    -F name="$REPO_NAME" \
    -F pullNumber="$PR_NUMBER" \
    -f query="$QUERY" 2>&1); then
    # gh command failed (auth, network, CLI error)
    print_error "GitHub API request failed:"
    echo "$RESPONSE" >&2
    echo "" >&2
    echo -e "${YELLOW}Possible causes:${NC}" >&2
    echo "  • Authentication failed or expired" >&2
    echo "  • Network connection issue" >&2
    echo "  • GitHub API outage" >&2
    echo "" >&2
    echo -e "${YELLOW}Try:${NC}" >&2
    echo "  • Verify authentication: gh auth status" >&2
    echo "  • Re-authenticate: gh auth login" >&2
    exit 1
fi

# Check for GraphQL errors in the response
if echo "$RESPONSE" | jq -e '.errors' >/dev/null 2>&1; then
    print_error "GraphQL API returned an error:"
    echo "$RESPONSE" | jq '.errors' >&2
    echo "" >&2
    if [ "$COLOR_ENABLED" = true ]; then
        echo -e "${YELLOW}Common causes:${NC}" >&2
    else
        echo "Common causes:" >&2
    fi
    echo "  • PR #$PR_NUMBER does not exist in $OWNER/$REPO_NAME" >&2
    echo "  • Authentication failed (verify with: gh auth status)" >&2
    echo "  • Rate limit exceeded" >&2
    exit 1
fi

# Check if the PR itself exists (pullRequest can be null even without GraphQL errors)
PULL_REQUEST_VALUE=$(echo "$RESPONSE" | jq '.data.repository.pullRequest' 2>/dev/null || echo "")
if [ -z "$PULL_REQUEST_VALUE" ]; then
    print_error "Could not retrieve PR information from GitHub API"
    exit 1
fi
if [ "$PULL_REQUEST_VALUE" = "null" ]; then
    print_error "PR #$PR_NUMBER does not exist in $OWNER/$REPO_NAME"
    exit 1
fi

# Filter and format unresolved comments
PENDING_COUNT=$(echo "$RESPONSE" | jq '[.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false)] | length')

if [[ "$PENDING_COUNT" -eq 0 ]]; then
    print_info "✅ No pending comments found in $OWNER/$REPO_NAME#$PR_NUMBER"
    exit 0
fi

print_info "📋 Found $PENDING_COUNT pending comment(s) in $OWNER/$REPO_NAME#$PR_NUMBER"
echo ""

# Output unresolved comments in a clean format
echo "$RESPONSE" | jq -r '
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
