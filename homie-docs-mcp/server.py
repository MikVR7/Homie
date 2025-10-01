#!/usr/bin/env python3
"""
Homie Documentation MCP Server
Automatically manages and provides access to all Homie documentation
"""

from mcp.server import Server
from mcp.server.models import InitializationOptions
import mcp.server.stdio
import mcp.types as types
from pathlib import Path
import asyncio
from datetime import datetime
from typing import Dict, List
import re

server = Server("homie-docs")

# Your actual docs structure
BASE_DIR = Path("/home/mikele/Projects/Homie/💡project-docs")
DOCS_DIR = BASE_DIR / "docs"
DIAGRAMS_DIR = BASE_DIR / "diagrams"
WARP_DIR = BASE_DIR / ".warp"

# Documentation memory (loaded on startup)
docs_cache = {}
diagrams_cache = {}

def load_all_documentation():
    """Load all documentation files into memory"""
    global docs_cache, diagrams_cache
    
    # Load markdown docs
    if DOCS_DIR.exists():
        for doc_file in DOCS_DIR.glob("*.md"):
            with open(doc_file, 'r', encoding='utf-8') as f:
                docs_cache[doc_file.stem] = {
                    'content': f.read(),
                    'path': str(doc_file),
                    'category': categorize_doc(doc_file.stem)
                }
    
    # Load warp context
    warp_context = WARP_DIR / "context.md"
    if warp_context.exists():
        with open(warp_context, 'r', encoding='utf-8') as f:
            docs_cache['WARP_CONTEXT'] = {
                'content': f.read(),
                'path': str(warp_context),
                'category': 'context'
            }
    
    # Load diagram references (XML files)
    if DIAGRAMS_DIR.exists():
        for diagram_file in DIAGRAMS_DIR.glob("*.xml"):
            diagrams_cache[diagram_file.stem] = str(diagram_file)

def categorize_doc(doc_name: str) -> str:
    """Categorize documents for better organization"""
    if doc_name in ['ARCHITECTURE', 'TERMINAL_COMMAND_ARCHITECTURE', 'ABSTRACT_COMMAND_SYSTEM']:
        return 'architecture'
    elif doc_name in ['CENTRALIZED_MEMORY', 'USB_DRIVE_MEMORY_DETAILS']:
        return 'memory'
    elif doc_name in ['DEVELOPMENT', 'DEPLOYMENT', 'PRODUCTION_CHECKLIST']:
        return 'development'
    elif doc_name in ['TODO', 'HISTORY']:
        return 'tracking'
    elif doc_name in ['GENERAL_RULES', 'CSV_IMPORT_GUIDE', 'ICONS_AND_ASSETS']:
        return 'guidelines'
    else:
        return 'general'

# Load docs on startup
load_all_documentation()

@server.list_resources()
async def handle_list_resources() -> list[types.Resource]:
    """Expose all documentation as resources - AI sees these automatically!"""
    resources = []
    
    # Add all markdown documentation
    for doc_name, doc_data in docs_cache.items():
        category = doc_data['category']
        resources.append(
            types.Resource(
                uri=f"homie://docs/{doc_name}",
                name=f"{doc_name.replace('_', ' ').title()}",
                description=f"[{category.upper()}] Documentation for {doc_name}",
                mimeType="text/markdown"
            )
        )
    
    # Add diagram references
    for diagram_name in diagrams_cache.keys():
        resources.append(
            types.Resource(
                uri=f"homie://diagrams/{diagram_name}",
                name=f"Diagram: {diagram_name.replace('_', ' ').title()}",
                description=f"Architecture diagram: {diagram_name}",
                mimeType="application/xml"
            )
        )
    
    return resources

@server.read_resource()
async def handle_read_resource(uri: str) -> str:
    """AI can read any doc automatically"""
    if uri.startswith("homie://docs/"):
        doc_name = uri.replace("homie://docs/", "")
        doc_data = docs_cache.get(doc_name)
        if doc_data:
            return doc_data['content']
    elif uri.startswith("homie://diagrams/"):
        diagram_name = uri.replace("homie://diagrams/", "")
        diagram_path = diagrams_cache.get(diagram_name)
        if diagram_path:
            return f"Diagram location: {diagram_path}\nUse draw.io or similar to view/edit this diagram."
    
    return "Documentation not found"

@server.list_tools()
async def handle_list_tools() -> list[types.Tool]:
    """Tools for managing your documentation"""
    return [
        types.Tool(
            name="update_doc",
            description="Update existing documentation when code changes",
            inputSchema={
                "type": "object",
                "properties": {
                    "doc_name": {
                        "type": "string", 
                        "enum": list(docs_cache.keys()),
                        "description": "Which document to update"
                    },
                    "section": {"type": "string", "description": "Section heading to update (or 'new' for new section)"},
                    "content": {"type": "string", "description": "New/updated content"},
                    "reason": {"type": "string", "description": "What code change triggered this update"}
                },
                "required": ["doc_name", "section", "content", "reason"]
            }
        ),
        types.Tool(
            name="add_todo",
            description="Add item to TODO.md",
            inputSchema={
                "type": "object",
                "properties": {
                    "category": {
                        "type": "string",
                        "enum": ["High Priority", "Features", "Bugs", "Optimization", "Documentation"],
                        "description": "TODO category"
                    },
                    "item": {"type": "string", "description": "TODO item description"},
                    "context": {"type": "string", "description": "Why this is needed"}
                },
                "required": ["category", "item"]
            }
        ),
        types.Tool(
            name="update_history",
            description="Add entry to HISTORY.md when significant changes are made",
            inputSchema={
                "type": "object",
                "properties": {
                    "date": {"type": "string", "description": "Date (YYYY-MM-DD)"},
                    "changes": {"type": "array", "items": {"type": "string"}, "description": "List of changes"},
                    "version": {"type": "string", "description": "Version if applicable"}
                }
            }
        ),
        types.Tool(
            name="check_docs_sync",
            description="Check if docs need updating based on code changes",
            inputSchema={
                "type": "object",
                "properties": {
                    "changed_files": {"type": "array", "items": {"type": "string"}},
                    "change_summary": {"type": "string"}
                }
            }
        ),
        types.Tool(
            name="get_doc_overview",
            description="Get overview of all documentation",
            inputSchema={"type": "object", "properties": {}}
        ),
        types.Tool(
            name="update_warp_context",
            description="Update the .warp/context.md file with new context",
            inputSchema={
                "type": "object",
                "properties": {
                    "context": {"type": "string", "description": "New context to add"},
                    "replace": {"type": "boolean", "description": "Replace existing or append", "default": False}
                }
            }
        ),
        types.Tool(
            name="create_new_doc",
            description="Create a new documentation file when a new module/feature needs its own documentation",
            inputSchema={
                "type": "object",
                "properties": {
                    "filename": {
                        "type": "string", 
                        "description": "Name of the new doc file (without .md extension, will be UPPERCASED)"
                    },
                    "title": {"type": "string", "description": "Document title for the header"},
                    "initial_content": {"type": "string", "description": "Initial documentation content"},
                    "category": {
                        "type": "string",
                        "enum": ["architecture", "memory", "development", "module", "feature", "guide", "reference"],
                        "description": "Category of documentation"
                    },
                    "reason": {"type": "string", "description": "Why this new documentation is needed"}
                },
                "required": ["filename", "title", "initial_content", "category", "reason"]
            }
        ),
        types.Tool(
            name="should_create_new_doc",
            description="Analyze if a new documentation file should be created",
            inputSchema={
                "type": "object",
                "properties": {
                    "topic": {"type": "string", "description": "What needs to be documented"},
                    "scope": {"type": "string", "description": "How big/complex is this topic"},
                    "existing_docs": {"type": "array", "items": {"type": "string"}, "description": "Which existing docs are related"}
                }
            }
        )
    ]

@server.call_tool()
async def handle_call_tool(name: str, arguments: dict) -> list:
    if name == "update_doc":
        doc_name = arguments.get("doc_name")
        section = arguments.get("section")
        content = arguments.get("content")
        reason = arguments.get("reason")
        
        if doc_name not in docs_cache:
            return [types.TextContent(type="text", text=f"❌ Document {doc_name} not found")]
        
        doc_path = Path(docs_cache[doc_name]['path'])
        existing = doc_path.read_text(encoding='utf-8')
        
        # Smart section update
        if section == "new":
            # Add new section at the end
            updated = existing.rstrip() + f"\n\n## {content.split(chr(10))[0] if chr(10) in content else content}\n"
            if chr(10) in content:
                updated += '\n'.join(content.split(chr(10))[1:]) + "\n"
        elif f"## {section}" in existing or f"### {section}" in existing:
            # Update existing section
            lines = existing.split('\n')
            new_lines = []
            in_section = False
            section_level = 0
            
            for line in lines:
                if f"## {section}" in line or f"### {section}" in line:
                    in_section = True
                    section_level = line.count('#')
                    new_lines.append(line)
                    new_lines.append("")
                    new_lines.append(content)
                    new_lines.append("")
                elif in_section and line.startswith('#') and line.count('#') <= section_level:
                    in_section = False
                    new_lines.append(line)
                elif not in_section:
                    new_lines.append(line)
            
            updated = '\n'.join(new_lines)
        else:
            # Add as new section
            lines = existing.split('\n')
            inserted = False
            new_lines = []
            
            for i, line in enumerate(lines):
                if not inserted and i > 0 and line.startswith('## '):
                    new_lines.append(f"## {section}\n")
                    new_lines.append(content)
                    new_lines.append("")
                    inserted = True
                new_lines.append(line)
            
            if not inserted:
                new_lines.append("")
                new_lines.append(f"## {section}")
                new_lines.append("")
                new_lines.append(content)
            
            updated = '\n'.join(new_lines)
        
        # Add update timestamp as comment
        timestamp = f"\n<!-- Last updated: {datetime.now().strftime('%Y-%m-%d %H:%M')} - Reason: {reason} -->"
        if "<!-- Last updated:" in updated:
            # Replace existing timestamp
            updated = re.sub(r'<!-- Last updated:.*?-->', timestamp, updated)
        else:
            updated = updated.rstrip() + timestamp + "\n"
        
        # Save and update cache
        doc_path.write_text(updated, encoding='utf-8')
        docs_cache[doc_name]['content'] = updated
        
        return [types.TextContent(
            type="text",
            text=f"✅ Updated {doc_name} - Section: {section}\nReason: {reason}"
        )]
    
    elif name == "add_todo":
        category = arguments.get("category")
        item = arguments.get("item")
        context = arguments.get("context", "")
        
        todo_path = DOCS_DIR / "TODO.md"
        existing = todo_path.read_text(encoding='utf-8') if todo_path.exists() else "# TODO\n\n"
        
        # Find or create category section
        if f"## {category}" not in existing:
            existing += f"\n## {category}\n"
        
        # Add item under category
        lines = existing.split('\n')
        new_lines = []
        added = False
        for line in lines:
            new_lines.append(line)
            if not added and line == f"## {category}":
                timestamp = datetime.now().strftime('%Y-%m-%d')
                new_lines.append(f"- [ ] {item} ({timestamp})")
                if context:
                    new_lines.append(f"  - Context: {context}")
                added = True
        
        updated = '\n'.join(new_lines)
        todo_path.write_text(updated, encoding='utf-8')
        
        if 'TODO' in docs_cache:
            docs_cache['TODO']['content'] = updated
        else:
            docs_cache['TODO'] = {
                'content': updated,
                'path': str(todo_path),
                'category': 'tracking'
            }
        
        return [types.TextContent(
            type="text",
            text=f"✅ Added to TODO under {category}: {item}"
        )]
    
    elif name == "update_history":
        date = arguments.get("date", datetime.now().strftime('%Y-%m-%d'))
        changes = arguments.get("changes", [])
        version = arguments.get("version", "")
        
        history_path = DOCS_DIR / "HISTORY.md"
        existing = history_path.read_text(encoding='utf-8') if history_path.exists() else "# HISTORY\n\n"
        
        # Create history entry
        entry = f"\n## {date}"
        if version:
            entry += f" - Version {version}"
        entry += "\n\n"
        for change in changes:
            entry += f"- {change}\n"
        
        # Add at the top after the main header
        lines = existing.split('\n')
        insert_index = 2  # Default position
        for i, line in enumerate(lines):
            if line.startswith('# '):
                insert_index = i + 2  # After header and blank line
                break
        
        lines.insert(insert_index, entry.strip())
        updated = '\n'.join(lines)
        
        history_path.write_text(updated, encoding='utf-8')
        
        if 'HISTORY' in docs_cache:
            docs_cache['HISTORY']['content'] = updated
        else:
            docs_cache['HISTORY'] = {
                'content': updated,
                'path': str(history_path),
                'category': 'tracking'
            }
        
        return [types.TextContent(
            type="text",
            text=f"✅ Added history entry for {date}"
        )]
    
    elif name == "check_docs_sync":
        changed_files = arguments.get("changed_files", [])
        change_summary = arguments.get("change_summary", "")
        
        suggestions = []
        
        # Analyze which docs might need updating based on changed files
        for file in changed_files:
            file_lower = file.lower()
            if "command" in file_lower or "terminal" in file_lower:
                suggestions.append("TERMINAL_COMMAND_ARCHITECTURE.md or ABSTRACT_COMMAND_SYSTEM.md")
            if "memory" in file_lower or "storage" in file_lower:
                suggestions.append("CENTRALIZED_MEMORY.md or USB_DRIVE_MEMORY_DETAILS.md")
            if any(x in file_lower for x in ["ui", "view", "window", "avalonia"]):
                suggestions.append("ARCHITECTURE.md - UI Components section")
            if "csv" in file_lower or "import" in file_lower:
                suggestions.append("CSV_IMPORT_GUIDE.md")
            if any(x in file_lower for x in ["deploy", "build", "release"]):
                suggestions.append("DEPLOYMENT.md or PRODUCTION_CHECKLIST.md")
        
        # Also check based on summary
        if change_summary:
            summary_lower = change_summary.lower()
            if "architecture" in summary_lower:
                suggestions.append("ARCHITECTURE.md")
            if "rule" in summary_lower:
                suggestions.append("GENERAL_RULES.md")
            if "icon" in summary_lower or "asset" in summary_lower:
                suggestions.append("ICONS_AND_ASSETS.md")
        
        # Remove duplicates
        suggestions = list(set(suggestions))
        
        result = "📝 Docs that might need updating:\n"
        if suggestions:
            result += "\n".join(f"• {s}" for s in suggestions)
        else:
            result = "✅ No obvious documentation updates needed"
        
        return [types.TextContent(type="text", text=result)]
    
    elif name == "get_doc_overview":
        overview = "📚 **Homie Documentation Overview**\n\n"
        
        # Group by category
        categories = {}
        for doc_name, doc_data in docs_cache.items():
            cat = doc_data['category']
            if cat not in categories:
                categories[cat] = []
            categories[cat].append(doc_name)
        
        for cat, docs in categories.items():
            overview += f"**{cat.upper()}:**\n"
            for doc in sorted(docs):
                size = len(docs_cache[doc]['content'])
                overview += f"  • {doc}: {size:,} characters\n"
            overview += "\n"
        
        if diagrams_cache:
            overview += f"**DIAGRAMS:** {len(diagrams_cache)} diagrams available\n"
            for diagram in sorted(diagrams_cache.keys()):
                overview += f"  • {diagram}\n"
        
        return [types.TextContent(type="text", text=overview)]
    
    elif name == "update_warp_context":
        context = arguments.get("context")
        replace = arguments.get("replace", False)
        
        warp_path = WARP_DIR / "context.md"
        
        if replace:
            content = context
        else:
            existing = warp_path.read_text(encoding='utf-8') if warp_path.exists() else ""
            content = existing + f"\n\n{context}\n"
        
        warp_path.parent.mkdir(exist_ok=True)
        warp_path.write_text(content, encoding='utf-8')
        
        docs_cache['WARP_CONTEXT'] = {
            'content': content,
            'path': str(warp_path),
            'category': 'context'
        }
        
        return [types.TextContent(
            type="text",
            text="✅ Updated .warp/context.md"
        )]
    
    elif name == "create_new_doc":
        filename = arguments.get("filename").upper().replace(" ", "_")
        title = arguments.get("title")
        initial_content = arguments.get("initial_content")
        category = arguments.get("category")
        reason = arguments.get("reason")
        
        # Check if doc already exists
        if filename in docs_cache:
            return [types.TextContent(
                type="text",
                text=f"⚠️ Document {filename}.md already exists. Use update_doc instead."
            )]
        
        # Create the document
        doc_path = DOCS_DIR / f"{filename}.md"
        
        # Create markdown with standard structure
        content = f"""# {title}

> Created: {datetime.now().strftime('%Y-%m-%d')}  
> Category: {category}  
> Reason: {reason}

## Overview

{initial_content}

## Details

_To be expanded as the feature develops._

## Related Documentation

"""
        # Add links to related docs based on category
        if category == "architecture":
            content += "- [Main Architecture](ARCHITECTURE.md)\n"
            content += "- [Terminal Command Architecture](TERMINAL_COMMAND_ARCHITECTURE.md)\n"
        elif category == "memory":
            content += "- [Centralized Memory](CENTRALIZED_MEMORY.md)\n"
            content += "- [USB Drive Memory](USB_DRIVE_MEMORY_DETAILS.md)\n"
        elif category in ["module", "feature"]:
            content += "- [Architecture](ARCHITECTURE.md)\n"
            content += "- [Development Guidelines](DEVELOPMENT.md)\n"
        elif category == "guide":
            content += "- [General Rules](GENERAL_RULES.md)\n"
            content += "- [CSV Import Guide](CSV_IMPORT_GUIDE.md)\n"
        
        content += f"""

## Implementation Status

- [ ] Design documented
- [ ] Code implemented
- [ ] Tests written
- [ ] Integration complete

## Notes

_Additional notes and considerations will be added here._

<!-- Last updated: {datetime.now().strftime('%Y-%m-%d %H:%M')} -->
"""
        
        # Save the new file
        doc_path.write_text(content, encoding='utf-8')
        
        # Add to cache
        docs_cache[filename] = {
            'content': content,
            'path': str(doc_path),
            'category': category
        }
        
        # Also update HISTORY.md to note new doc creation
        history_path = DOCS_DIR / "HISTORY.md"
        if history_path.exists():
            history = history_path.read_text(encoding='utf-8')
            entry = f"\n### {datetime.now().strftime('%Y-%m-%d')}\n- Created new documentation: {filename}.md - {title}\n  - Reason: {reason}\n"
            
            # Insert after header
            lines = history.split('\n')
            for i, line in enumerate(lines):
                if line.startswith('# '):
                    lines.insert(i + 2, entry.strip())
                    break
            history_path.write_text('\n'.join(lines), encoding='utf-8')
        
        return [types.TextContent(
            type="text",
            text=f"""✅ Created new documentation file: {filename}.md
📁 Location: {doc_path}
📑 Category: {category}
📝 Title: {title}

The new document is now available to the AI and has been added to the documentation cache."""
        )]
    
    elif name == "should_create_new_doc":
        topic = arguments.get("topic")
        scope = arguments.get("scope")
        existing_docs = arguments.get("existing_docs", [])
        
        # Decision logic
        reasons_for_new = []
        reasons_against = []
        
        # Check if topic is substantial enough
        topic_lower = topic.lower()
        if any(word in topic_lower for word in ["module", "system", "manager", "service"]):
            reasons_for_new.append("This appears to be a major component")
        
        scope_lower = scope.lower()
        if any(word in scope_lower for word in ["feature", "large", "complex", "major"]):
            reasons_for_new.append("The scope is significant enough")
        
        if len(existing_docs) == 0:
            reasons_for_new.append("No existing documentation covers this")
        elif len(existing_docs) > 2:
            reasons_for_new.append("This touches many areas and deserves its own doc")
        
        # Check against creating new docs
        if any(word in scope_lower for word in ["minor", "small", "trivial"]):
            reasons_against.append("Scope might be too small for dedicated doc")
        
        if any(doc in existing_docs for doc in ["GENERAL_RULES", "DEVELOPMENT"]):
            reasons_against.append("Might fit better as a section in existing docs")
        
        # Make recommendation
        should_create = len(reasons_for_new) > len(reasons_against)
        
        recommendation = f"""📊 Analysis for: {topic}

✅ Reasons to create new doc:
{chr(10).join(f'  • {r}' for r in reasons_for_new) if reasons_for_new else '  • None'}

❌ Reasons against:
{chr(10).join(f'  • {r}' for r in reasons_against) if reasons_against else '  • None'}

💡 Recommendation: {'CREATE NEW DOCUMENTATION FILE' if should_create else 'UPDATE EXISTING DOCUMENTATION'}"""
        
        if should_create:
            suggested_name = topic.upper().replace(' ', '_')[:30]
            recommendation += f"\n\nSuggested filename: {suggested_name}.md"
        else:
            recommendation += f"\n\nSuggest updating: {', '.join(existing_docs[:2]) if existing_docs else 'Create appropriate section in existing docs'}"
        
        return [types.TextContent(type="text", text=recommendation)]

async def main():
    print("Starting Homie Documentation MCP Server...")
    print(f"Docs directory: {DOCS_DIR}")
    print(f"Loaded {len(docs_cache)} documents and {len(diagrams_cache)} diagrams")
    
    async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="homie-docs",
                server_version="0.1.0",
                capabilities=types.ServerCapabilities(
                    resources=types.ResourcesCapability(subscribe=False),
                    tools=types.ToolsCapability()
                )
            )
        )

if __name__ == "__main__":
    asyncio.run(main())