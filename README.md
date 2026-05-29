# Agent Skills Repository

A collection of reusable, standard Agent Skills that extend the capabilities of AI agents with specialized tools and workflows. These skills are designed to be compatible with any Agent development tool that supports the Agent Skills standard.

## Available Skills

| Skill              | Description                                              | Use Cases                                                           |
| :----------------- | :------------------------------------------------------- | :------------------------------------------------------------------ |
| [**pr-comments**](#pr-comments)    | Manage GitHub PR review comments (fetch/resolve)         | PR feedback management, tracking unresolved comments, closing threads |
| [**oracle-sqlcl**](#oracle-sqlcl)   | Execute SQL queries against Oracle databases using SQLcl | Schema inspection, data verification, debugging, migration planning |
| [**ufile-slips**](#ufile-slips)    | Automate T3 and T5 tax slip management in UFile          | Adding, filling, exporting, and deleting tax slips via browser automation |

### pr-comments

Manage GitHub Pull Request review comments directly from your agent.

- **Fetch Pending Comments**: Get all unresolved review comments from a PR.
- **Resolve Threads**: Mark review threads as resolved after addressing feedback.
- **Flexible Input**: Supports full GitHub PR URLs or explicit owner/repo/number arguments.
- **Safe Operations**: Read-only fetching by default; mutations require explicit user confirmation.

**Installation:**

```bash
npx skills add https://github.com/hdcola/skills --skill pr-comments
```

Or manually:

```bash
cp -r skills/pr-comments/ ~/.claude/skills/pr-comments/
```

**Requirements:**

- `gh` CLI installed and authenticated.
- `git` installed.

For full documentation, see [skills/pr-comments/SKILL.md](skills/pr-comments/SKILL.md)

### oracle-sqlcl

Execute SQL queries directly against Oracle databases from your agent.

- **Schema Inspection**: Quickly explore table structures and relationships.
- **Data Verification**: Run queries to verify application state or test results.
- **Migration Support**: Plan and validate database migrations.
- **Troubleshooting**: Debug production or staging issues directly from the chat.

**Installation:**

```bash
npx skills add https://github.com/hdcola/skills --skill oracle-sqlcl
```

Or manually:

```bash
cp -r skills/oracle-sqlcl/ ~/.claude/skills/oracle-sqlcl/
```

**Requirements:**

- SQLcl installed and in PATH.
- Oracle database connection details configured.

**Quick Start:**

1. Install SQLcl: `brew install sqlcl` (macOS) or follow [manual installation](skills/oracle-sqlcl/SKILL.md#manual-installation-macos-or-other-platforms).
2. Create a config file at `~/.claude/sqlcl-connections.json` or `.sqlcl-connections.json`.
3. See [Configuration Example](skills/oracle-sqlcl/assets/sqlcl-connections-example.json).

For full documentation, see [skills/oracle-sqlcl/SKILL.md](skills/oracle-sqlcl/SKILL.md)

### ufile-slips

Automate T3 and T5 tax slip management in UFile through browser automation.

- **Add Slips**: Quickly add new T3 or T5 slips.
- **Fill Slips**: Automatically populate slip fields (issuer, box values, etc.).
- **Export Slips**: Extract filled values from slip forms.
- **Delete Slips**: Remove slips by type or by specific name.

**Installation:**

```bash
npx skills add https://github.com/hdcola/skills --skill ufile-slips
```

Or manually:

```bash
cp -r skills/ufile-slips/ ~/.claude/skills/ufile-slips/
```

**Requirements:**

- **Chrome Browser**: Must use Google Chrome (not other browsers).
- **Remote Debugging**: Enable remote debugging in Chrome:
  1. Go to `chrome://inspect/#remote-debugging`
  2. Check "Allow remote debugging for this browser instance"
- **Chrome DevTools MCP**: Install the MCP server in your agent:
  ```bash
  npm install -g @anthropic-ai/chrome-devtools-mcp
  ```
  See [Chrome DevTools MCP Setup Guide](https://developer.chrome.com/blog/chrome-devtools-mcp-debug-your-browser-session) for configuration details.
- **Active UFile Tab**: UFile interview tab must be loaded and active (`https://secure.ufile.ca/...`).

For full documentation, see [skills/ufile-slips/SKILL.md](skills/ufile-slips/SKILL.md)

## Contributing

To add a new skill:

1. Create a directory under `skills/` with the skill name.
2. Include a `SKILL.md` file with skill metadata (YAML frontmatter) and documentation.
3. Add any supporting files (scripts, assets, references).
4. Update this README with the new skill entry.
