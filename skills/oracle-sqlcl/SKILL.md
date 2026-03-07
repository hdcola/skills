---
name: oracle-sqlcl
description: Execute SQL queries against Oracle databases using SQLcl. Oracle databases only - does not support other databases. Use when you need to query Oracle database schemas, inspect table structures, verify data, debug test results, plan migrations, or execute migration scripts. Supports multiple Oracle database connections with automatic prompting to select the correct database. Displays the SQL command being executed and returns query results. Requires SQLcl to be installed and configured in PATH.
---

# SQLcl Connector

Execute SQL queries against Oracle databases using SQLcl from Claude. Perfect for schema inspection, data verification, and migration planning.

## Prerequisites

### macOS (Recommended: Homebrew)

SQLcl is easiest to install on macOS using Homebrew. If you don't have Homebrew installed, get it from https://brew.sh

**Installation:**

```bash
# Install SQLcl via Homebrew
brew install sqlcl
```

**Verify installation:**

```bash
sql -version
```

You should see output like:
```
SQLcl: Release 23.4.0 Production
```

That's it! Homebrew automatically adds SQLcl to your PATH.

**If Homebrew installation fails:** The `sqlcl` formula may not be available. Try the manual installation method below instead.

### Manual Installation (macOS or other platforms)

If Homebrew doesn't work, or you're on a different OS:

1. Download SQLcl from: https://www.oracle.com/tools/downloads/sqlcl-downloads.html
2. Extract the archive
3. Add SQLcl to your PATH:

```bash
# Edit ~/.zshrc (or ~/.bashrc if using bash)
export PATH=$PATH:/path/to/sqlcl/bin
```

4. Reload your shell:
```bash
source ~/.zshrc
```

5. Verify:
```bash
sql -version
```

## Quick Start

### 1. Set Up Configuration

Create a configuration file at one of these locations:

**Global (for all projects):**
```bash
~/.claude/sqlcl-connections.json
```

**Per-project:**
```bash
.sqlcl-connections.json
```

**Example configuration:**
```json
{
  "connections": {
    "primary": {
      "host": "localhost",
      "port": 1521,
      "service": "ORCL",
      "user": "schema_user",
      "password": "your_password_here"
    },
    "secondary": {
      "host": "prod-db.example.com",
      "port": 1521,
      "service": "PROD_DB",
      "user": "prod_user",
      "password": "prod_password_here"
    },
    "staging": {
      "host": "staging-db.example.com",
      "port": 1521,
      "service": "STAGING_DB",
      "user": "staging_user",
      "password": "staging_password_here"
    }
  }
}
```

**Security note:** Keep this file private (don't commit to git). Add `.sqlcl-connections.json` to `.gitignore`.

### 2. Verify SQLcl is Installed

SQLcl should be installed already (see **Prerequisites** section above). Verify it works:

```bash
sql -version
```

If this command is not found, follow the installation steps in the **Prerequisites** section.

### 3. Query Your Database

When you request a database query, provide:
- **Database name**: Which connection from your config to use (e.g., "primary", "secondary")
- **Query type**: What you want to do (see examples below)
- **Specific details**: Table names, column names, IDs, etc.

Examples of what to ask:
- "Query the primary database to list all tables"
- "Show me the structure of the USER_ACCOUNTS table in secondary"
- "Get all columns from CUSTOMER where ID = 123 in primary"
- "Execute this migration script on secondary: [SQL]"

## Common Use Cases

### Inspect Schema

```
"Show all tables in the primary database"
"What columns does the ORDERS table have in secondary?"
"List all indexes on the PRODUCT table"
```

### Verify Data

```
"Check how many records are in the CUSTOMER table in primary"
"Show me 10 sample rows from the TRANSACTION table"
"Verify that the customer with ID 456 exists in secondary"
```

### Debug Tests

```
"Did the migration create the new AUDIT_LOG table in primary?"
"Show me the constraints on the USER_ROLES table in secondary"
"Check if the unique constraint was created correctly"
```

### Migration Planning

```
"Show all sequences in the secondary database"
"What triggers exist on the PAYMENT table in primary?"
"List all foreign key relationships for the ORDER_ITEMS table"
```

## Query Execution Flow

1. **You provide request** - Tell what you want to query and on which database
2. **SQL is generated** - Appropriate SQL statement is created
3. **Command displayed** - The exact `sql` command to be executed is shown
4. **Query runs** - SQLcl connects and executes
5. **Results returned** - Query output is displayed

## Reference Queries

Common SQL queries for inspection are available in `references/common_queries.md`:
- List all tables
- Describe table structure
- Get column details
- Count rows
- View sample data
- Inspect constraints and keys
- Check sequences
- Verify migrations

## Configuration Details

### Connection String Format

SQLcl supports multiple connection formats. The skill automatically builds the correct format from your config:

```
user/password@host:port/service
```


### Connection Names

Choose connection names that make sense for your use case:
- **Environment-based**: `local`, `dev`, `staging`, `production`
- **Role-based**: `primary`, `secondary`, `replica`
- **Project-based**: `billing_db`, `user_service_db`
- **Custom**: Any descriptive name for your setup

### Multiple Projects

Since configs support both global (`~/.claude/sqlcl-connections.json`) and per-project (`.sqlcl-connections.json`) files:

- **Global config**: Define databases used across projects
- **Project config**: Override or add project-specific databases

The skill searches in this order:
1. `.sqlcl-connections.json` (project directory)
2. `~/.claude/sqlcl-connections.json` (user home)
3. `$HOME/.claude/sqlcl-connections.json` (fallback)

First match found is used.

## Troubleshooting

### "sql command not found"

SQLcl is not installed or not in PATH. Follow the installation steps in the **Prerequisites** section:

**For macOS (easiest):**
```bash
brew install sqlcl
sql -version  # Verify
```

**For other platforms or if Homebrew fails:**
- Download from: https://www.oracle.com/tools/downloads/sqlcl-downloads.html
- Extract and add to PATH in `~/.zshrc` or `~/.bashrc`:
  ```bash
  export PATH=$PATH:/path/to/sqlcl/bin
  source ~/.zshrc
  sql -version  # Verify
  ```

### "Connection refused"

Database host/port is incorrect or database is not running:

- Verify connection details in your config file
- Test connection manually: `sql user/password@host:port/service`
- Ensure database service is running

### "Invalid username/password"

Credentials in your config file are incorrect:

1. Check your config file (`~/.claude/sqlcl-connections.json` or `.sqlcl-connections.json`)
2. Verify the username and password are correct for that database
3. Test credentials manually:
   ```bash
   sql username/password@host:port/service
   ```

### "Configuration file not found"

Create the config file:

```bash
# Global (recommended for multi-project use)
mkdir -p ~/.claude
cp assets/sqlcl-connections-example.json ~/.claude/sqlcl-connections.json
# Edit with your connection details

# Or per-project
cp assets/sqlcl-connections-example.json .sqlcl-connections.json
# Edit with your connection details
```

## Tips and Best Practices

### 1. Keep Configuration Files Secure

Never commit configuration files with passwords to git:

```bash
# Add to .gitignore
.sqlcl-connections.json
~/.claude/sqlcl-connections.json
```

Keep the files locally on your machine and share connection details with team members separately.

### 2. Organize Multiple Environments

Define all environments in one config:

```json
{
  "connections": {
    "local": { ... },
    "dev": { ... },
    "staging": { ... },
    "production": { ... }
  }
}
```

### 3. Keep Queries Readable

For complex queries, format them clearly:

```
SELECT 
  id, 
  name, 
  created_date 
FROM user_accounts 
WHERE status = 'ACTIVE' 
ORDER BY created_date DESC
```

### 4. Large Result Sets

SQLcl automatically handles:
- Pagination (50,000 lines per page)
- Long column values
- Large character data

Results are fully displayed in Claude's response.

