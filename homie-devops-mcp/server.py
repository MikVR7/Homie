#!/usr/bin/env python3
"""
Homie DevOps MCP Server
Provides tools to build and manage Docker images for the project.
"""

import asyncio
import subprocess
from pathlib import Path

import mcp.server.stdio
import mcp.types as types
from mcp.server import Server
from mcp.server.models import InitializationOptions

server = Server("homie-devops")

# This must be the directory containing your Dockerfile
PROJECT_ROOT = Path("~/Projects/Homie/backend").expanduser()

def run_command(command: list[str]) -> str:
    try:
        result = subprocess.run(
            command,
            cwd=PROJECT_ROOT,
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout if result.stdout else "Command executed successfully with no output."
    except subprocess.CalledProcessError as e:
        return f"❌ Command failed:\n\n{e.stderr}"
    except FileNotFoundError:
        return f"❌ Error: Command '{command[0]}' not found. Is Docker installed and in your PATH?"

@server.list_tools()
async def handle_list_tools() -> list[types.Tool]:
    return [
        types.Tool(
            name="docker_build_image",
            description="Build a Docker image from the Dockerfile in the backend project.",
            inputSchema={
                "type": "object",
                "properties": {
                    "image_name": {"type": "string", "description": "The name for the Docker image (e.g., 'homie-backend')."},
                    "tag": {"type": "string", "description": "The tag for the image, often a version number (e.g., '1.0.0' or 'latest')."}
                },
                "required": ["image_name", "tag"]
            }
        ),
        types.Tool(
            name="docker_list_images",
            description="List all Docker images available on the local machine.",
            inputSchema={"type": "object", "properties": {}}
        ),
    ]

@server.call_tool()
async def handle_call_tool(name: str, arguments: dict) -> list:
    if name == "docker_build_image":
        image_name = arguments.get("image_name")
        tag = arguments.get("tag")
        full_image_name = f"{image_name}:{tag}"
        output = run_command(["docker", "build", "-t", full_image_name, "."])
        return [types.TextContent(type="text", text=f"🏗️ Docker Build Results for `{full_image_name}`:\n\n```\n{output}\n```")]
    
    if name == "docker_list_images":
        output = run_command(["docker", "images"])
        return [types.TextContent(type="text", text=f"🖼️ Available Docker Images:\n\n```\n{output}\n```")]

    return []

async def main():
    print("Starting Homie DevOps MCP Server...")
    print(f"Using Docker build context at: {PROJECT_ROOT}")
    async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="homie-devops",
                server_version="0.1.0",
                capabilities=types.ServerCapabilities(tools=types.ToolsCapability())
            )
        )

if __name__ == "__main__":
    asyncio.run(main())
