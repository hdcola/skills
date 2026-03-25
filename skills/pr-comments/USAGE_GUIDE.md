# pr-comments Skill - Usage Guide

Quick reference for fetching pending review comments from GitHub PRs.

## Four Ways to Use

### Option 0: Current Branch (Most Convenient)
**Best for:** Working on an active PR branch

```bash
bash scripts/fetch_pending_comments.sh
```

**Requirements:**
- Must be run from within the git repository directory
- The current branch must have an associated PR on GitHub

**Pros:**
- No arguments needed
- Automatically finds the PR for your current branch
- Fastest to use when actively working on a PR

**When to use this:**
✅ You're working on a branch with an open PR
✅ You want the quickest command possible

---

### Option A: PR Number Only (Recommended for git repos)
**Best for:** Users already in the repository

```bash
bash scripts/fetch_pending_comments.sh 216
```

**Requirements:**
- Must be run from within the git repository directory (or a subdirectory)

**Pros:**
- Simplest syntax
- Auto-detects repository owner and name
- No need to look up repo details

**When to use this:**
✅ You're in the insurfactapps repo directory
✅ You want the quickest command
✅ You know the PR number

---

### Option B: GitHub URL (Universal)
**Best for:** Works from anywhere, explicit, no repo context needed

```bash
bash scripts/fetch_pending_comments.sh https://github.com/hugcanada/insurfactapps/pull/216
```

**Pros:**
- Works from any directory
- Very explicit - no ambiguity
- Easy to copy from GitHub URL bar

**When to use this:**
✅ You're in a skill or tool directory
✅ You want to be explicit about which repo
✅ You have the GitHub PR URL open

---

### Option C: Explicit Owner/Repo/Number
**Best for:** Scripting, automation, or when you prefer explicit syntax

```bash
bash scripts/fetch_pending_comments.sh hugcanada insurfactapps 216
```

**Pros:**
- Works from any directory
- Explicit and clear
- Good for scripts and automation
- No URL parsing needed

**When to use this:**
✅ You're writing a script that calls this
✅ You're in a directory far from the repo
✅ You prefer explicit arguments over URLs

---

## Real Examples

### Example 1: From the repo root
```bash
$ pwd
/Users/hd/work/prj/insurfact/insurfactapps

$ bash /Users/hd/.claude/skills/pr-comments/scripts/fetch_pending_comments.sh 216
📋 Found 4 pending comment(s) in hugcanada/insurfactapps#216
```

### Example 2: From the skill directory
```bash
$ pwd
/Users/hd/.claude/skills/pr-comments

# Option A won't work - gives helpful error
$ bash scripts/fetch_pending_comments.sh 216
❌ Error: PR number only works when run from a git repository

# Option B works fine
$ bash scripts/fetch_pending_comments.sh https://github.com/hugcanada/insurfactapps/pull/216
📋 Found 4 pending comment(s) in hugcanada/insurfactapps#216

# Option C also works fine
$ bash scripts/fetch_pending_comments.sh hugcanada insurfactapps 216
📋 Found 4 pending comment(s) in hugcanada/insurfactapps#216
```

### Example 3: From /tmp or anywhere else
```bash
$ cd /tmp
$ bash /Users/hd/.claude/skills/pr-comments/scripts/fetch_pending_comments.sh https://github.com/hugcanada/insurfactapps/pull/216
📋 Found 4 pending comment(s) in hugcanada/insurfactapps#216
```

---

## Troubleshooting

### "Error: PR number only works when run from a git repository"

**Cause:** You used Option A outside the repository
**Solution:** Use Option B (URL) or Option C (explicit args) instead

```bash
# Instead of:
bash scripts/fetch_pending_comments.sh 216

# Use:
bash scripts/fetch_pending_comments.sh https://github.com/hugcanada/insurfactapps/pull/216
```

### "GraphQL API returned an error"

**Causes:**
- GitHub CLI not authenticated
- PR number doesn't exist
- Rate limit exceeded

**Solutions:**
```bash
# Check GitHub authentication
gh auth status

# Login if needed
gh auth login
```

### "Not a GitHub repository" or similar errors

**Cause:** Your repository isn't on GitHub or `gh` isn't properly configured
**Solution:** Use Option B (URL) which doesn't need GitHub CLI configuration

---

## Command Reference

| Option | Syntax | Works from anywhere? | Requires git repo? |
|--------|--------|----------------------|-------------------|
| A | `sh fetch_pending_comments.sh 216` | ❌ | ✅ |
| B | `sh fetch_pending_comments.sh https://github.com/o/r/pull/216` | ✅ | ❌ |
| C | `sh fetch_pending_comments.sh owner repo 216` | ✅ | ❌ |

---

## Output Format

All three options produce the same output:

```
📋 Found 4 pending comment(s) in hugcanada/insurfactapps#216

ID: PRRT_kwDOQFTPGc52cAm4 | path/to/file.vue:36-44 | @author: Comment text...
ID: PRRT_kwDOQFTPGc52cAn1 | path/to/file.vue:37-44 | @author: Comment text...
```

Each pending comment shows:
- **ID**: Thread ID (used to resolve comments)
- **Path**: File path and line range
- **Author**: GitHub username
- **Comment text**: First line of the review comment
