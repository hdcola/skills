---
name: pr-comments
description: 获取 GitHub PR 的未解决评论（PENDING）或将评论标记为已解决（Resolved）。支持通过 PR 编号或 URL 操作。
---

# GitHub PR Review Comment Manager

This skill provides tools for fetching unresolved (PENDING) review comments and marking them as Resolved using GitHub's GraphQL API. The workflow is decomposed into reusable scripts for clarity and maintainability.

## Core Functions

### Fetch Pending Comments [READ-ONLY]

Get all unresolved review comments from a PR:

```bash
bash scripts/fetch_pending_comments.sh [PR_NUMBER_OR_URL]
```

**Input flexibility:**
- `123` — Uses the current repository and PR #123
- `https://github.com/owner/repo/pull/123` — Full GitHub URL
- (no args) — Fetches comments from the currently checked-out PR if in a git repo

**Output format:** Displays unresolved comments with:
- Thread ID
- File path and line range
- Author name
- Comment text (truncated to single line)

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

1. **User:** "Check pending comments on PR #123"
   - Run: `bash scripts/fetch_pending_comments.sh 123`
   - Display results to user

2. **User:** "Resolve these three: [ID1] [ID2] [ID3]"
   - Confirm: "I'll resolve these 3 threads. OK?"
   - User confirms
   - Run: `bash scripts/resolve_comment_thread.sh ID1 ID2 ID3`
   - Report results

## Important Rules

- **Scope**: This skill handles ONLY review comment workflow — it does not modify source code or PR content.
- **Safety**: Read-only operations (fetch) run freely. Mutations (resolve) require explicit user confirmation first.
- **Error handling**: Scripts include validation and report errors clearly with actionable messages.
- **Concurrency**: Each invocation is independent; safe to run multiple times.
