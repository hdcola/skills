---
name: pr-comments
description: Fetch unresolved review comments from a GitHub PR or mark comments as resolved. Use this when managing PR review feedback, checking pending comments, or marking review threads as resolved. Supports PR number (auto-detects repo), GitHub URLs, or explicit owner/repo/PR-number.
---

# GitHub PR Review Comment Manager

This skill automatically fetches unresolved review comments from GitHub PRs and helps you resolve them. It uses GitHub's GraphQL API and handles multiple input formats seamlessly.

## Quick Start

Invoke the skill with any of these formats — the skill auto-detects and fetches immediately:

```
/pr-comments                                                              # From current branch (auto-detects PR & repo)
/pr-comments 216                                                          # PR number (auto-detects repo)
/pr-comments https://github.com/owner/repo/pull/123                      # GitHub URL
/pr-comments owner repo 123                                               # Explicit owner/repo/PR#
```

The skill will:
1. **Fetch automatically** — No extra steps needed; comments display immediately
2. **Show pending comments** — File paths, authors, comment text, and thread IDs
3. **Ready to resolve** — Once you've reviewed, provide thread IDs to resolve

## Workflow

1. **User invokes skill** with PR identifier (any format above)
   - Skill auto-detects format and fetches pending comments
   - Displays results immediately

2. **Review pending comments** displayed by the skill

3. **Optionally resolve** — If you want to mark threads as resolved:
   - Provide thread IDs from the output
   - Skill will ask for confirmation (resolving is destructive)
   - Threads marked as resolved

**Example output:**
```
📋 Found 3 pending comment(s) in hugcanada/insurfactapps#216

ID: PRRT_kwDOQFTPGc51yyCV | apps/IFCAdmin/app/layouts/AppMenuItem.vue:126 | @reviewer: missing icon handling
ID: PRRT_kwDOQFTPGc51yyCz | apps/IFCAdmin/app/layouts/AppMenuItem.vue:129 | @reviewer: accessibility issue
ID: PRRT_kwDOQFTPGc51yyDP | apps/IFCAdmin/app/assets/layout/_menu.scss:90 | @reviewer: empty styles
```

## Input Formats

The skill accepts four formats. Choose based on your situation:

| Option | Example | Dependencies | When to use |
|--------|---------|-------------|------------|
| **0** ⭐⭐ | (no arguments) | `gh`, `jq`, `git` | When working on a PR branch (must run from git repo) |
| **A** ⚠️ | `216` | `gh`, `jq`, `git` — Must run from git repo with remote origin configured | When you know the PR number and are in the project directory |
| **B** ⭐ | `https://github.com/owner/repo/pull/123` | `gh`, `jq` (no git needed) | **Recommended** — Works anywhere without a git repository |
| **C** | `owner repo 123` | `gh`, `jq` (no git needed) | When you know the owner/repo details, works anywhere |

**Option 0 (Current Branch):**
- No arguments needed — just run `/pr-comments`
- Queries GitHub for the PR associated with your current branch
- **Requires:** Must run from project root (a git repo with remote origin)
- **Most convenient** for developers actively working on a PR

**Key Point:** Options 0 and A both require running from a git repository with a configured remote origin. For maximum portability, use Option B (GitHub URL) or C (explicit owner/repo).

**Why Option A can fail:**
- If you run the script from a directory inside a monorepo or nested git structure, auto-detection might find the wrong repository
- **Solution:** Use Option 0 (current branch), Option B (GitHub URL), or Option C (explicit owner/repo)

If you encounter errors, the script will automatically suggest alternative formats.

## How Claude Executes This Skill

When you invoke `/pr-comments`, Claude should:

1. **Ensure correct working directory** — **CRITICAL**: Change to the project root (the directory containing `.git`) before executing the script. This is required for auto-detection to work correctly.
2. **Parse the user's input** — Extract the PR identifier in whatever format they provided
3. **Auto-fetch immediately** — Run the appropriate fetch script without asking for confirmation (fetching is read-only and safe)
4. **Display results** — Show pending comments with thread IDs
5. **Offer next steps** — Explain how to resolve threads if there are any pending

**Implementation detail:** The skill must execute from the project root:
```bash
# Change to project root FIRST (critical for auto-detection)
cd <project-root>

# Then run the fetch script (no confirmation needed)
bash <skill-path>/scripts/fetch_pending_comments.sh <user-input>
```

**Why this matters:** When using Option A (PR number only), the script auto-detects the repository by running `git rev-parse --git-dir` and `gh repo view`. If run from a non-project directory, git may find the wrong repository, causing auto-detection to fail. The script will detect this and suggest using Option B (GitHub URL) or C (explicit owner/repo) instead, but execution from the project root eliminates this issue entirely.

This works for all four input formats — the script handles the detection internally.

---

## Resolving Comments [Destructive — confirmation required]

If the user asks to resolve comments:

1. **Require explicit approval** — Confirm which thread IDs they want to resolve
2. **Ask for permission** — "I'll resolve these N threads. OK?"
3. **Execute on approval** — Run `bash scripts/resolve_comment_thread.sh ID1 ID2 ...`

Resolving modifies the PR, so it requires user confirmation. Fetching does not.

## Key Principles

- **Auto-fetch on invocation** — When you invoke the skill with a PR identifier, it immediately fetches and displays comments. No manual steps required.

- **Safe operations are automatic** — Read-only fetch operations run immediately without confirmation.

- **Destructive operations require approval** — Only when resolving threads (which modifies the PR) does the skill ask for explicit user confirmation.

- **Multiple input formats** — The skill accepts PR numbers (auto-detect), GitHub URLs, or explicit owner/repo/PR# — all work seamlessly.

- **Error suggestions** — If auto-detection fails (e.g., not in a git repo), error messages suggest using alternative input formats (URL or explicit owner/repo).

- **Scope** — This skill handles GitHub PR review comments only — it doesn't modify code or PR content.

- **No side effects** — Each invocation is independent; fetching the same PR multiple times is safe.
