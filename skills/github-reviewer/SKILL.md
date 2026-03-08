---
name: github-reviewer
description: A specialized tool for automated GitHub Pull Request expert reviews with bilingual output. Performs deep code analysis and posts professional reviews in Chinese and English.
---
# github-reviewer

A specialized tool for automated GitHub Pull Request expert reviews with bilingual output. Checks out PRs, performs deep code analysis across Correctness, Maintainability, Performance, and Security, then posts professional reviews and inline comments directly to GitHub in both Chinese and English.

**Use this skill whenever the user mentions reviewing a GitHub PR**, even if they phrase it casually (e.g., "look at this PR", "check the code", "review this for me", "看看这个 PR"). Also use it when they want to post reviews to GitHub, add code comments to specific lines, or analyze PR changes. Works with any GitHub repository the user has access to.

## Prerequisites
- `gh` CLI installed and authenticated (`gh auth status` to verify)
- `git` installed
- Access to the repository being reviewed

## Core Principles
- **Bilingual Output**: All content posted to GitHub (Body, Inline Comments) must include both **Simplified Chinese** and **English**.
- **No Explicit Tags**: Do **NOT** use labels like "[Chinese]" or "[English]". Present the Chinese paragraph first, followed immediately by the English translation.
- **Automated Operations**: Prioritize using the `gh` CLI and its API for all operations.
- **Precision**: Inline comments must be verified against `git diff` for accurate file paths and line numbers.

## Workflow

### 1. Checkout and Analysis
1. **Verify PR Access**: Use `gh pr view <ID>` to confirm the PR exists and you have access.
2. **Determine Base Branch**: The PR's base branch is shown in the output above. **Do NOT assume it's `main`** — use whatever base branch the PR specifies (often `main`, `master`, `develop`, or custom branches).
3. **Checkout Branch**: Use `gh pr checkout <ID>`. This checks out the PR's branch locally.
4. **Analyze Changes**:
   - Use `git diff <BASE_BRANCH>...HEAD` to view the full diff (replace `<BASE_BRANCH>` with the actual base branch from step 2).
   - If the checkout fails, inform the user immediately — it likely means authentication issues or the branch no longer exists.
   - Focus on: **Correctness**, **Maintainability**, **Performance**, **Security**, and **Naming Consistency**.

### 2. Generate Review Content
- **General Review Summary**:
  - Structure: Summary, Findings (Critical, Improvements), Conclusion.
  - Language: Provide the Chinese text first, followed by the English translation for each section. No tags.
- **Inline Comments**:
  - Target specific lines with issues or suggestions.
  - Language: Provide the Chinese explanation first, followed by the English explanation. No tags.

### 3. Posting to GitHub
- **General Review**:
  ```bash
  gh pr review <ID> --[approve|request-changes|comment] --body "<BILINGUAL_BODY>"
  ```
- **Inline Comments (Batch via API)**:
  To ensure atomicity, use the `gh api` to post the review and all comments at once:
  ```bash
  gh api repos/:owner/:repo/pulls/:pull_number/reviews \
    -f body="<GENERAL_BILINGUAL_SUMMARY>" \
    -f event="REQUEST_CHANGES" \
    -F "comments[][path]=src/main.js" \
    -F "comments[][line]=15" \
    -F "comments[][body]=<BILINGUAL_INLINE_COMMENT>"
  ```

## Review Pillars
1. **Correctness**: Logical flaws, edge case handling, and ID generation (especially collision risks after storage hydration).
2. **Maintainability**: Code structure, modularity, and avoiding variable shadowing.
3. **Consistency**: Consistent use of domain terminology (e.g., Todo vs. Product).
4. **Security & Robustness**: Error handling and secure usage of browser storage (localStorage).

## Usage Examples

### Example 1: Basic PR Review
**User input**: "Review PR #42"

**Workflow**:
1. `gh pr view 42` → Shows base branch is `main`, PR title "Add user authentication"
2. `gh pr checkout 42` → Checks out the feature branch
3. `git diff main...HEAD` → Analyzes the changes
4. Generates bilingual review with findings
5. `gh pr review 42 --request-changes --body "<BILINGUAL_SUMMARY>"`

**Sample Output** (posted to GitHub):
```
完整的代码审查发现3个关键问题和2个改进建议。认证逻辑缺少错误处理，密钥存储方式不安全，变量命名不一致。

Comprehensive code review found 3 critical issues and 2 improvement suggestions. Authentication logic lacks error handling, key storage approach is insecure, variable naming is inconsistent.

**关键问题 | Critical Issues:**
1. JWT token 没有过期验证机制
2. 密码以明文存储在 localStorage

**改进建议 | Improvements:**
1. 提取重复的验证逻辑到工具函数
2. 使用更清晰的变量名 (userToken → authenticationToken)
```

### Example 2: Inline Comments on Specific Lines
**User input**: "Add a comment on line 45 about the null check"

**API Call**:
```bash
gh api repos/:owner/:repo/pulls/:pull_number/reviews \
  -f body="参考下方内联评论 | See inline comments below" \
  -f event="COMMENT" \
  -F comments[][path]=src/auth.js \
  -F comments[][line]=45 \
  -F comments[][body]="这里应该检查 token 是否为空。Missing null check here for the token."
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `gh: Not authenticated` | Run `gh auth login` and complete the browser authentication flow |
| `Checkout failed: Branch not found` | The PR's branch may have been deleted. Ask the user to verify the PR number |
| `git diff shows nothing` | Ensure you're on the PR's branch: `git branch` should show the PR branch, not main |
| Can't determine base branch | If `gh pr view` doesn't show a base branch, use `git log --oneline` to see the commit history and infer the target branch |
