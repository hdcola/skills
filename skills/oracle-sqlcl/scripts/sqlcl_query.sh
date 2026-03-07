#!/bin/bash

# SQLcl Database Query Script
# Usage: ./sqlcl_query.sh <connection_name> <sql_query>
# or with config: ./sqlcl_query.sh --config <config_file> <connection_name> <sql_query>

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default config search paths
CONFIG_PATHS=(
    ".sqlcl-connections.json"
    "~/.claude/sqlcl-connections.json"
    "$HOME/.claude/sqlcl-connections.json"
)

CONFIG_FILE=""
CONNECTION_NAME=""
SQL_QUERY=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        *)
            if [ -z "$CONNECTION_NAME" ]; then
                CONNECTION_NAME="$1"
            elif [ -z "$SQL_QUERY" ]; then
                SQL_QUERY="$1"
            else
                SQL_QUERY="$SQL_QUERY $1"
            fi
            shift
            ;;
    esac
done

# If no explicit config provided, search default paths
if [ -z "$CONFIG_FILE" ]; then
    for path in "${CONFIG_PATHS[@]}"; do
        expanded_path="${path/#\~/$(echo ~)}"
        if [ -f "$expanded_path" ]; then
            CONFIG_FILE="$expanded_path"
            break
        fi
    done
fi

# Validate inputs
if [ -z "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ Error: Configuration file not found${NC}"
    echo "Please create ~/.claude/sqlcl-connections.json or .sqlcl-connections.json in your project"
    exit 1
fi

if [ -z "$CONNECTION_NAME" ] || [ -z "$SQL_QUERY" ]; then
    echo -e "${RED}❌ Error: Missing arguments${NC}"
    echo "Usage: $0 [--config <file>] <connection_name> <sql_query>"
    exit 1
fi

# Check if sql command exists
if ! command -v sql &> /dev/null; then
    echo -e "${RED}❌ Error: 'sql' command not found${NC}"
    echo "Please install Oracle SQLcl and ensure it's in your PATH"
    echo "Installation guide: https://www.oracle.com/tools/downloads/sqlcl-downloads.html"
    exit 1
fi

# Parse JSON config (using Python for reliability)
PYTHON_SCRIPT=$(cat <<'PYSCRIPT'
import json
import os
import sys

config_file = sys.argv[1]
connection_name = sys.argv[2]

try:
    with open(os.path.expanduser(config_file), 'r') as f:
        config = json.load(f)
except FileNotFoundError:
    print(f"Error: Config file '{config_file}' not found", file=sys.stderr)
    sys.exit(1)
except json.JSONDecodeError:
    print(f"Error: Invalid JSON in '{config_file}'", file=sys.stderr)
    sys.exit(1)

if 'connections' not in config:
    print("Error: 'connections' key not found in config", file=sys.stderr)
    sys.exit(1)

connections = config['connections']

if connection_name not in connections:
    available = ', '.join(connections.keys())
    print(f"Error: Connection '{connection_name}' not found", file=sys.stderr)
    print(f"Available connections: {available}", file=sys.stderr)
    sys.exit(1)

conn_config = connections[connection_name]

# Extract connection details
host = conn_config.get('host', 'localhost')
port = conn_config.get('port', 1521)
service = conn_config.get('service', '')
user = conn_config.get('user', '')
password = conn_config.get('password', '')

# Replace environment variables
password = os.path.expandvars(password)

# Build connection string
if service:
    connect_string = f"{user}/{password}@{host}:{port}/{service}"
else:
    connect_string = f"{user}/{password}@{host}:{port}"

print(connect_string)
PYSCRIPT
)

# Get connection string from config
CONNECT_STRING=$(python3 <(echo "$PYTHON_SCRIPT") "$CONFIG_FILE" "$CONNECTION_NAME" 2>&1) || {
    echo -e "${RED}$CONNECT_STRING${NC}"
    exit 1
}

# Display the command that will be executed
echo -e "${YELLOW}📝 Executing SQL on connection: ${GREEN}$CONNECTION_NAME${NC}"
echo -e "${YELLOW}📋 SQL Query:${NC}"
echo "---"
echo "$SQL_QUERY"
echo "---"
echo ""

# Execute query
RESULT=$(sql -s "$CONNECT_STRING" <<EOF
SET PAGESIZE 50000
SET LINESIZE 32767
SET LONG 20000
SET LONGCHUNKSIZE 20000
WHENEVER SQLERROR EXIT SQL.SQLCODE
$SQL_QUERY
EXIT
EOF
2>&1) || {
    echo -e "${RED}❌ Query execution failed:${NC}"
    echo "$RESULT"
    exit 1
}

# Display results
echo -e "${GREEN}✅ Query executed successfully:${NC}"
echo "$RESULT"
