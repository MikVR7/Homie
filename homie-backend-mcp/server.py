#!/usr/bin/env python3
"""
Homie Backend Interaction MCP Server
Provides tools to test, lint, and manage the Python backend.
"""

import asyncio
import subprocess
from pathlib import Path

import mcp.server.stdio
import mcp.types as types
from mcp.server import Server
from mcp.server.models import InitializationOptions

server = Server("homie-backend")

# --- IMPORTANT ---
# Set the path to your Python backend's root folder.
# This is the directory where you would normally run 'pytest' or 'ruff'.
PROJECT_ROOT = Path("~/Projects/Homie/backend").expanduser()

def run_command(command: list[str]) -> str:
    """Helper to run a shell command in the project directory and return its output."""
    if not PROJECT_ROOT.exists():
        return f"Error: Project root directory not found at '{PROJECT_ROOT}'"
    try:
        # We use 'uv' to run commands to ensure they use the project's virtual environment if it exists
        # This makes it more robust.
        full_command = ["uv", "run", "--", *command]
        result = subprocess.run(
            full_command,
            cwd=PROJECT_ROOT,
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout if result.stdout else "Command executed successfully with no output."
    except subprocess.CalledProcessError as e:
        return f"❌ Command failed with exit code {e.returncode}:\n\nSTDOUT:\n{e.stdout}\n\nSTDERR:\n{e.stderr}"
    except FileNotFoundError:
        return f"❌ Error: Command 'uv' not found. Please ensure Astral's uv is installed and in your PATH."

@server.list_tools()
async def handle_list_tools() -> list[types.Tool]:
    """Defines the tools the AI can use."""
    return [
        types.Tool(
            name="run_tests",
            description="Run the Python backend test suite using pytest.",
            inputSchema={
                "type": "object",
                "properties": {
                    "test_path": {"type": "string", "description": "Optional: a specific test file or directory to run."}
                }
            }
        ),
        types.Tool(
            name="lint_code",
            description="Check a Python file for style issues and errors using the ruff linter.",
            inputSchema={
                "type": "object",
                "properties": {
                    "file_path": {"type": "string", "description": "The relative path to the Python file to lint."}
                },
                "required": ["file_path"]
            }
        ),
        types.Tool(
            name="check_dependencies",
            description="List all installed dependencies in the project's environment using 'uv pip list'.",
            inputSchema={"type": "object", "properties": {}}
        )
    ]

@server.call_tool()
async def handle_call_tool(name: str, arguments: dict) -> list:
    """Executes the logic for the tools."""
    output = ""
    if name == "run_tests":
        cmd = ["pytest"]
        if test_path := arguments.get("test_path"):
            cmd.append(test_path)
        output = run_command(cmd)
        return [types.TextContent(type="text", text=f"🧪 Pytest Results:\n\n```\n{output}\n```")]
    
    if name == "lint_code":
        file_path = arguments.get("file_path", "")
        if not file_path:
            return [types.TextContent(type="text", text="❌ Error: file_path is required for lint_code.")]
        output = run_command(["ruff", "check", file_path])
        return [types.TextContent(type="text", text=f"🎨 Ruff Linting Results for '{file_path}':\n\n```\n{output}\n```")]

    if name == "check_dependencies":
        output = run_command(["uv", "pip", "list"])
        return [types.TextContent(type="text", text=f"📦 Installed Backend Dependencies:\n\n```\n{output}\n```")]

    return [types.TextContent(type="text", text="Unknown tool called.")]

async def main():
    """The main entry point for the server."""
    print("Starting Homie Backend Interaction MCP Server...")
    print(f"Using project root: {PROJECT_ROOT}")
    
    async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="homie-backend",
                server_version="0.1.0",
                capabilities=types.ServerCapabilities(tools=types.ToolsCapability())
            )
        )

if __name__ == "__main__":
    asyncio.run(main())