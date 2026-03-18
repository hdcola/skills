# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an **Agent Skills Repository** - a collection of reusable, standard Agent Skills that extend the capabilities of AI agents with specialized tools and workflows. These skills are designed to be compatible with any Agent development tool that supports the Agent Skills standard.

## Repository Structure

```
skills/
├── oracle-sqlcl/           # Skill for querying Oracle databases
│   ├── SKILL.md            # Skill metadata and documentation
│   ├── scripts/            # Helper bash scripts (e.g., sqlcl_query.sh)
│   ├── assets/             # Configuration examples (e.g., sqlcl-connections-example.json)
│   └── references/         # Additional documentation (e.g., common_queries.md)
├── pr-comments/            # Skill for managing GitHub PR review comments
│   ├── SKILL.md            # Skill metadata and documentation
│   └── scripts/            # Helper bash scripts (e.g., fetch_pending_comments.sh)
└── README.md               # User-facing documentation for installing skills
```

## Skill Architecture

Each skill is a self-contained directory with:

1. **SKILL.md** (required)
   - Metadata: `name`, `description`
   - Documentation on usage, prerequisites, triggers, and workflows
   - Core principles and examples

2. **Supporting files** (optional)
   - Scripts: Executable bash/python files referenced by the skill
   - Assets: Configuration templates, examples, connection details
   - References: Additional documentation, query templates, guides

## Current Skills

### pr-comments
- **Purpose**: Manage GitHub PR review comments (fetch/resolve)
- **Key Workflow**:
  1. Fetch pending comments using `fetch_pending_comments.sh`
  2. Resolve review threads using `resolve_comment_thread.sh`
- **Safety**: Read-only operations (fetch) run freely; mutations (resolve) require user confirmation.

### oracle-sqlcl
- **Purpose**: Execute SQL queries against Oracle databases from an agent
- **Key Files**:
  - `scripts/sqlcl_query.sh` - Main script that handles connection and query execution
  - `assets/sqlcl-connections-example.json` - Configuration template
  - `references/common_queries.md` - Example queries
- **Requirements**: SQLcl installed (via `brew install sqlcl` or manual installation)
- **Configuration**: `~/.claude/sqlcl-connections.json` or `.sqlcl-connections.json` (project-level)

## Installation for Users

The recommended way to install a skill is using the `skills` CLI:

```bash
npx skills add <skill-name>
```

Alternatively, skills can be installed by copying to the agent's skills folder (e.g., `~/.claude/skills/` for Claude Code):

```bash
cp -r skills/<skill-name>/ ~/.claude/skills/<skill-name>/
```

After installation, skills are immediately available based on their trigger conditions.

## Development Notes

- **No build process**: Skills are interpreted/executed directly; no compilation needed
- **Metadata-driven**: Skill functionality is declared in `SKILL.md` frontmatter
- **Configuration secrets**: Local connection configs are in `.gitignore` (`.sqlcl-connections.json`, `*.local.json`)
- **Cross-platform**: Skills should work on macOS, Linux, and Windows where applicable
- **Language support**: Skills can include bash, Python, or other executable scripts

## Git Workflow

- **Remote**: https://github.com/hdcola/skills.git
- **Default branch**: main
- **PRs required** for new skills (see recent commits for merge patterns)
- **History**: Repository started with oracle-sqlcl skill, added github-reviewer in later PRs

## When Adding New Skills

1. Create a new directory under `skills/` with a descriptive name
2. Write a comprehensive `SKILL.md` with:
   - Clear metadata (name, description)
   - Prerequisites and installation instructions
   - Quick start guide
   - Core principles and workflow steps
   - Examples of trigger conditions
3. Include supporting files (scripts, assets, references) in appropriate subdirectories
4. Update `README.md` with the new skill entry in the "Available Skills" table
5. Consider bilingual content (Chinese/English) if the skill targets global users
