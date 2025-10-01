#!/usr/bin/env python3
"""
Homie Code Intelligence MCP Server
Provides tools to analyze the structure of the Python backend code using ASTs.
"""

import asyncio
import ast
from pathlib import Path

import mcp.server.stdio
import mcp.types as types
from mcp.server import Server
from mcp.server.models import InitializationOptions

server = Server("homie-code-intel")

# --- IMPORTANT ---
# Set the path to your Python backend's root folder.
PROJECT_ROOT = Path("~/Projects/Homie/backend").expanduser()

# --- AST Visitor Classes ---

class FunctionCallVisitor(ast.NodeVisitor):
    """An AST visitor that finds all calls to a specific function."""
    def __init__(self, function_name):
        self.function_name = function_name
        self.calls = []

    def visit_Call(self, node):
        func_name = ''
        if isinstance(node.func, ast.Name):
            func_name = node.func.id
        elif isinstance(node.func, ast.Attribute):
            func_name = node.func.attr
        
        if func_name == self.function_name:
            self.calls.append(f"L{node.lineno}")
        self.generic_visit(node)

class ClassMethodVisitor(ast.NodeVisitor):
    """An AST visitor that lists all methods in a specific class."""
    def __init__(self, class_name):
        self.class_name = class_name
        self.methods = []

    def visit_ClassDef(self, node):
        if node.name == self.class_name:
            for item in node.body:
                if isinstance(item, ast.FunctionDef):
                    self.methods.append(f"- {item.name}")
        self.generic_visit(node)

# --- Server Logic ---

def parse_file(file_path: Path):
    """Safely parse a Python file into an AST."""
    try:
        with open(file_path, "r", encoding="utf-8") as source:
            return ast.parse(source.read(), filename=str(file_path))
    except (SyntaxError, FileNotFoundError, UnicodeDecodeError) as e:
        print(f"Could not parse {file_path}: {e}")
        return None

@server.list_tools()
async def handle_list_tools() -> list[types.Tool]:
    """Defines the code intelligence tools."""
    return [
        types.Tool(
            name="find_function_usage",
            description="Analyzes the codebase to find all call sites of a specific Python function.",
            inputSchema={
                "type": "object",
                "properties": {
                    "function_name": {"type": "string", "description": "The name of the function to search for (e.g., 'get_user_by_id')."}
                },
                "required": ["function_name"]
            }
        ),
        types.Tool(
            name="list_class_methods",
            description="Analyzes a file to list all methods within a specific Python class.",
            inputSchema={
                "type": "object",
                "properties": {
                    "class_name": {"type": "string", "description": "The name of the class to inspect."},
                    "file_path": {"type": "string", "description": "The relative path to the file containing the class."}
                },
                "required": ["class_name", "file_path"]
            }
        )
    ]

@server.call_tool()
async def handle_call_tool(name: str, arguments: dict) -> list:
    """Executes the logic for the analysis tools."""
    if name == "find_function_usage":
        function_name = arguments.get("function_name")
        if not function_name:
            return [types.TextContent(type="text", text="❌ Error: function_name is required.")]

        results = []
        py_files = list(PROJECT_ROOT.rglob("*.py"))
        for file_path in py_files:
            tree = parse_file(file_path)
            if tree:
                visitor = FunctionCallVisitor(function_name)
                visitor.visit(tree)
                if visitor.calls:
                    relative_path = file_path.relative_to(PROJECT_ROOT)
                    locations = ", ".join(visitor.calls)
                    results.append(f"- **{relative_path}**: Found at lines {locations}")
        
        if not results:
            return [types.TextContent(type="text", text=f"✅ No usages of function '{function_name}' found in the project.")]

        output = f"🔍 Found usages of function `{function_name}` in the following files:\n\n" + "\n".join(results)
        return [types.TextContent(type="text", text=output)]

    if name == "list_class_methods":
        class_name = arguments.get("class_name")
        file_path_str = arguments.get("file_path")
        if not class_name or not file_path_str:
            return [types.TextContent(type="text", text="❌ Error: class_name and file_path are required.")]

        file_path = PROJECT_ROOT / file_path_str
        tree = parse_file(file_path)
        if not tree:
            return [types.TextContent(type="text", text=f"❌ Could not parse the file at '{file_path_str}'.")]

        visitor = ClassMethodVisitor(class_name)
        visitor.visit(tree)

        if not visitor.methods:
            return [types.TextContent(type="text", text=f"✅ No class named '{class_name}' found or it has no methods in '{file_path_str}'.")]

        output = f"📋 Methods in class `{class_name}` (from `{file_path_str}`):\n\n" + "\n".join(visitor.methods)
        return [types.TextContent(type="text", text=output)]

    return []

async def main():
    print("Starting Homie Code Intelligence MCP Server...")
    print(f"Analyzing project root: {PROJECT_ROOT}")
    async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
        # --- THIS BLOCK IS NOW CORRECTED ---
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="homie-code-intel",
                server_version="0.1.0",
                capabilities=types.ServerCapabilities(tools=types.ToolsCapability())
            )
        )

if __name__ == "__main__":
    asyncio.run(main())