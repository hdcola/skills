# Agent Skills Repository

A collection of reusable, standard Agent Skills that extend the capabilities of AI agents with specialized tools and workflows. These skills are designed to be compatible with any Agent development tool that supports the Agent Skills standard.

## Installation

The recommended way to install a skill is using the `skills` CLI:

```bash
npx skills add https://github.com/hdcola/skills --skill <skill-name>
```

For example, to install the `oracle-sqlcl` skill:

```bash
npx skills add https://github.com/hdcola/skills --skill oracle-sqlcl
```

Alternatively, you can manually copy the skill directory to your agent's skills folder (e.g., `~/.claude/skills/` for Claude Code):

```bash
cp -r skills/<skill-name>/ ~/.claude/skills/<skill-name>/
```

## Available Skills

| Skill            | Description                                              | Use Cases                                                           |
| :--------------- | :------------------------------------------------------- | :------------------------------------------------------------------ |
| **pr-comments**  | Manage GitHub PR review comments (fetch/resolve)         | PR feedback management, tracking unresolved comments, closing threads |
| **oracle-sqlcl** | Execute SQL queries against Oracle databases using SQLcl | Schema inspection, data verification, debugging, migration planning |

### pr-comments

Manage GitHub Pull Request review comments directly from your agent.

- **Fetch Pending Comments**: Get all unresolved review comments from a PR.
- **Resolve Threads**: Mark review threads as resolved after addressing feedback.
- **Flexible Input**: Supports full GitHub PR URLs or explicit owner/repo/number arguments.
- **Safe Operations**: Read-only fetching by default; mutations require explicit user confirmation.

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

**Requirements:**

- SQLcl installed and in PATH.
- Oracle database connection details configured.

**Quick Start:**

1. Install SQLcl: `brew install sqlcl` (macOS) or follow [manual installation](skills/oracle-sqlcl/SKILL.md#manual-installation-macos-or-other-platforms).
2. Create a config file at `~/.claude/sqlcl-connections.json` or `.sqlcl-connections.json`.
3. See [Configuration Example](skills/oracle-sqlcl/assets/sqlcl-connections-example.json).

For full documentation, see [skills/oracle-sqlcl/SKILL.md](skills/oracle-sqlcl/SKILL.md)

## Contributing

To add a new skill:

1. Create a directory under `skills/` with the skill name.
2. Include a `SKILL.md` file with skill metadata (YAML frontmatter) and documentation.
3. Add any supporting files (scripts, assets, references).
4. Update this README with the new skill entry.
