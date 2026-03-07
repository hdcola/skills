# Claude Skills Repository

A collection of reusable skills for Claude that extend its capabilities with specialized tools and workflows.

## Installation

Skills are installed by copying the skill directory to your Claude skills folder:

```bash
cp -r <skill-name>/ ~/.claude/skills/<skill-name>/
```

For example, to install the `oracle-sqlcl` skill:

```bash
cp -r oracle-sqlcl/ ~/.claude/skills/oracle-sqlcl/
```

After copying, the skill will be available in Claude Code.

## Available Skills

| Skill            | Description                                              | Use Cases                                                                        |
| ---------------- | -------------------------------------------------------- | -------------------------------------------------------------------------------- |
| **oracle-sqlcl** | Execute SQL queries against Oracle databases using SQLcl | Schema inspection, data verification, debugging test results, migration planning |

### oracle-sqlcl

Execute SQL queries directly against Oracle databases from Claude. Perfect for:

- Inspecting database schemas and table structures
- Verifying data and running checks
- Planning and validating database migrations
- Debugging test results

**Requirements:**

- SQLcl installed and in PATH
- Oracle database connection details configured

**Quick Start:**

1. Install SQLcl: `brew install sqlcl` (macOS) or follow [manual installation](oracle-sqlcl/SKILL.md#manual-installation-macos-or-other-platforms)
2. Create a config file at `~/.claude/sqlcl-connections.json` or `.sqlcl-connections.json`
3. See [Configuration Example](oracle-sqlcl/assets/sqlcl-connections-example.json)

For full documentation, see [oracle-sqlcl/SKILL.md](oracle-sqlcl/SKILL.md)

## Contributing

To add a new skill:

1. Create a directory with the skill name
2. Include a `SKILL.md` file with skill metadata and documentation
3. Add any supporting files (scripts, assets, references)
4. Update this README with the skill entry
