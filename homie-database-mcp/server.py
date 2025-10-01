#!/usr/bin/env python3
"""
Homie Database Specialist MCP Server
Provides tools to manage the backend's specific SQLite database.
"""

import asyncio
import sqlite3
from pathlib import Path

import mcp.server.stdio
import mcp.types as types
from mcp.server import Server
from mcp.server.models import InitializationOptions

server = Server("homie-database")

# --- IMPORTANT CONFIGURATION ---
# The root of the MCP server directory
SERVER_ROOT = Path(__file__).parent
# The path to your project's SQLite database file
DB_PATH = Path("~/Projects/Homie/backend/homie_users.db").expanduser()
# The path to your SQL scripts
SCRIPTS_PATH = SERVER_ROOT / "scripts"

def get_db_connection():
    """Establish and return a connection to the SQLite database."""
    if not DB_PATH.exists():
        raise FileNotFoundError(f"Database file not found at {DB_PATH}")
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

@server.list_tools()
async def handle_list_tools() -> list[types.Tool]:
    """Defines the database interaction tools."""
    return [
        types.Tool(
            name="db_get_schema",
            description="Retrieve and display the full schema for all tables in the database.",
            inputSchema={"type": "object", "properties": {}}
        ),
        types.Tool(
            name="db_seed_test_data",
            description="Wipe the database and populate it with a clean set of test data from 'seed.sql'.",
            inputSchema={"type": "object", "properties": {}}
        ),
        types.Tool(
            name="db_run_query",
            description="Run a read-only SQL SELECT query against the database and return the results.",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "The SELECT statement to execute."}
                },
                "required": ["query"]
            }
        ),
    ]

@server.call_tool()
async def handle_call_tool(name: str, arguments: dict) -> list:
    """Executes the logic for the database tools."""
    try:
        if name == "db_get_schema":
            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute("SELECT name, sql FROM sqlite_master WHERE type='table';")
            tables = cursor.fetchall()
            conn.close()
            if not tables:
                return [types.TextContent(type="text", text="No tables found in the database.")]
            
            schema_text = "📚 Database Schema:\n\n" + "\n\n".join([f"-- {table['name']}\n{table['sql']};" for table in tables])
            return [types.TextContent(type="text", text=schema_text)]

        if name == "db_seed_test_data":
            seed_script_path = SCRIPTS_PATH / "seed.sql"
            if not seed_script_path.exists():
                return [types.TextContent(type="text", text=f"❌ Error: Seed script not found at {seed_script_path}")]
            
            conn = get_db_connection()
            cursor = conn.cursor()
            with open(seed_script_path, "r") as f:
                cursor.executescript(f.read())
            conn.commit()
            conn.close()
            return [types.TextContent(type="text", text="✅ Database successfully seeded with test data.")]

        if name == "db_run_query":
            query = arguments.get("query", "")
            if not query.strip().upper().startswith("SELECT"):
                return [types.TextContent(type="text", text="❌ Safety Warning: This tool only supports SELECT queries.")]
            
            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute(query)
            rows = cursor.fetchall()
            conn.close()

            if not rows:
                return [types.TextContent(type="text", text="✅ Query executed successfully and returned no rows.")]
            
            # Format the output as a Markdown table
            headers = rows[0].keys()
            table = "| " + " | ".join(headers) + " |\n"
            table += "| " + " | ".join(["---"] * len(headers)) + " |\n"
            for row in rows:
                table += "| " + " | ".join([str(value) for value in row]) + " |\n"

            return [types.TextContent(type="text", text=f"📊 Query Results:\n\n{table}")]

    except Exception as e:
        return [types.TextContent(type="text", text=f"❌ An error occurred: {e}")]

    return []

async def main():
    print("Starting Homie Database Specialist MCP Server...")
    print(f"Connecting to database at: {DB_PATH}")
    async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="homie-database",
                server_version="0.1.0",
                capabilities=types.ServerCapabilities(tools=types.ToolsCapability())
            )
        )

if __name__ == "__main__":
    asyncio.run(main())