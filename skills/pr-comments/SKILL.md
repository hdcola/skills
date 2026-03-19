---
name: pr-comments
description: Fetch unresolved review comments from a GitHub PR or mark comments as resolved. Requires explicit repository context (GitHub URL or owner/repo/number). Use this when managing PR review feedback, checking pending comments, or marking review threads as resolved. Supports full GitHub URLs (most reliable) or explicit owner/repo/PR-number arguments.
---

# GitHub PR Review Comment Manager

This skill provides tools for fetching unresolved (PENDING) review comments and marking them as Resolved using GitHub's GraphQL API. The workflow is decomposed into reusable scripts for clarity and maintainability.

## Core Functions

### Fetch Pending Comments [READ-ONLY]

Get all unresolved review comments from a PR. **Requires explicit repository context** unless providing just the PR number in a git repository:

```bash
bash scripts/fetch_pending_comments.sh PR_NUMBER
# OR
bash scripts/fetch_pending_comments.sh https://github.com/owner/repo/pull/123
# OR
bash scripts/fetch_pending_comments.sh OWNER REPO PR_NUMBER
```

**Input format (choose one):**
- **Option A (Number):** `123` — Just the PR number (autodetects current repo via `gh repo view`)
- **Option B (URL):** `https://github.com/owner/repo/pull/123` — Full GitHub URL (most reliable)
- **Option C (explicit):** `owner repo 123` — Three arguments: owner, repo name, PR number

**Output format:** Displays unresolved comments with:
- Thread ID
- File path and line range
- Author name
- Comment text (truncated to single line)

**Example usage:**
```bash
# Using PR number (autodetect repo)
bash scripts/fetch_pending_comments.sh 42

# Using URL (recommended)
bash scripts/fetch_pending_comments.sh https://github.com/anthropics/claude-code/pull/42
```

**Example output:**
```
ID: MDExOlB1bGxSZXF1ZXN0UmV2aWV3VGhyZWFk... | src/app.js:45-47 | @alice: fix the error handling here
```

### Resolve Review Threads [MODIFYING — requires user confirmation]

Mark one or more review threads as resolved:

```bash
bash scripts/resolve_comment_thread.sh THREAD_ID [THREAD_ID2 ...]
```

**Important:** This performs a mutation and MUST only be called after explicit user approval. The user should:
1. Review the pending comments
2. Approve which threads to resolve
3. Provide the thread IDs

**Output:** Shows which threads were successfully resolved and which (if any) failed.

## Workflow

### Typical Usage Pattern

1. **User:** "Check pending comments on this PR"
   - If user provides: URL → `bash scripts/fetch_pending_comments.sh https://github.com/owner/repo/pull/123`
   - If user provides: owner, repo, PR number → `bash scripts/fetch_pending_comments.sh owner repo 123`
   - Display results to user

2. **User:** "Resolve these three: [ID1] [ID2] [ID3]"
   - Confirm: "I'll resolve these 3 threads. OK?"
   - User confirms
   - Run: `bash scripts/resolve_comment_thread.sh ID1 ID2 ID3`
   - Report results

## Important Rules

- **Explicit context required**: Always provide full GitHub URL or explicit owner/repo/number. Do NOT rely on git repository context — this ensures scripts work reliably from any directory.
- **Scope**: This skill handles ONLY review comment workflow — it does not modify source code or PR content.
- **Safety**: Read-only operations (fetch) run freely. Mutations (resolve) require explicit user confirmation first.
- **Error handling**: Scripts include validation and report errors clearly with actionable messages.
- **Concurrency**: Each invocation is independent; safe to run multiple times.
