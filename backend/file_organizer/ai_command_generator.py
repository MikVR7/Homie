#!/usr/bin/env python3
"""
AICommandGenerator

Builds prompts and requests AI for abstract operations. Returns operation lists.
"""

from __future__ import annotations

import json
import logging
import os
from pathlib import Path
from typing import Dict, Any, Optional, List

logger = logging.getLogger("AICommandGenerator")


class AICommandGenerator:
    def __init__(self, event_bus, shared_services):
        self.event_bus = event_bus
        self.shared_services = shared_services

    async def shutdown(self) -> None:
        # Nothing persistent yet
        return

    async def generate_operations(
        self,
        folder_path: str,
        history_provider,
        intent: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Generate AI-powered file organization operations."""
        try:
            # 1. Scan folder and analyze files
            logger.info(f"📁 Analyzing folder: {folder_path}")
            folder_analysis = await self._analyze_folder(folder_path)
            
            if not folder_analysis["files"]:
                return {
                    "success": True,
                    "folder": folder_path,
                    "intent": intent,
                    "operations": []
                }

            # 2. Get destination memory and history
            history = history_provider.get_folder_history(folder_path, limit=20)
            drive_status = await history_provider.get_drive_status()
            
            # 3. Build AI prompt with all context
            prompt = self._build_ai_prompt(
                folder_analysis=folder_analysis,
                folder_path=folder_path,
                intent=intent,
                history=history,
                drive_status=drive_status
            )
            
            # 4. Call AI for operations
            operations = await self._call_ai_for_operations(prompt)
            
            # 5. Validate and return
            return {
                "success": True,
                "folder": folder_path,
                "intent": intent,
                "operations": operations,
                "analysis": {
                    "total_files": len(folder_analysis["files"]),
                    "categories": folder_analysis["categories"],
                    "duplicates_found": folder_analysis["duplicates_count"],
                    "archives_found": folder_analysis["archives_count"]
                }
            }
            
        except Exception as e:
            logger.error(f"AI operation generation failed: {e}")
            return {"success": False, "error": str(e)}

    async def _analyze_folder(self, folder_path: str) -> Dict[str, Any]:
        """Scan folder and analyze all files."""
        try:
            folder = Path(folder_path).expanduser()
            if not folder.exists() or not folder.is_dir():
                raise ValueError(f"Invalid folder: {folder_path}")
            
            files = []
            categories = {}
            archives = []
            potential_duplicates = {}
            
            # Recursively scan all files
            for file_path in folder.rglob("*"):
                if file_path.is_file():
                    try:
                        file_info = await self._analyze_file(file_path)
                        files.append(file_info)
                        
                        # Track categories
                        category = file_info["category"]
                        categories[category] = categories.get(category, 0) + 1
                        
                        # Track archives
                        if category == "Archives":
                            archives.append(file_info)
                        
                        # Track potential duplicates by size
                        size = file_info["size"]
                        if size > 0:  # Skip empty files
                            if size not in potential_duplicates:
                                potential_duplicates[size] = []
                            potential_duplicates[size].append(file_info)
                            
                    except Exception as e:
                        logger.warning(f"Error analyzing file {file_path}: {e}")
                        continue
            
            # Find actual duplicates (same size + similar names)
            duplicates = []
            for size, files_with_size in potential_duplicates.items():
                if len(files_with_size) > 1:
                    duplicates.extend(files_with_size)
            
            return {
                "files": files,
                "categories": categories,
                "archives": archives,
                "archives_count": len(archives),
                "duplicates": duplicates,
                "duplicates_count": len(duplicates),
                "total_size": sum(f["size"] for f in files)
            }
            
        except Exception as e:
            logger.error(f"Folder analysis failed: {e}")
            raise

    async def _analyze_file(self, file_path: Path) -> Dict[str, Any]:
        """Analyze individual file."""
        try:
            stat = file_path.stat()
            category = self.shared_services.extract_file_category(str(file_path))
            
            file_info = {
                "name": file_path.name,
                "path": str(file_path),
                "relative_path": str(file_path.relative_to(file_path.parents[-2])) if len(file_path.parents) > 1 else file_path.name,
                "size": stat.st_size,
                "size_human": self.shared_services.format_file_size(stat.st_size),
                "category": category,
                "extension": file_path.suffix.lower(),
                "modified": stat.st_mtime,
                "is_hidden": file_path.name.startswith(".")
            }
            
            # Detect series info for videos
            if category == "Videos":
                series_info = self.shared_services.detect_series_info(file_path.name)
                if series_info:
                    file_info["series_info"] = series_info
            
            # Check if file is in a project directory
            if self._is_in_project(file_path):
                file_info["in_project"] = True
                file_info["project_root"] = str(self._find_project_root(file_path))
            
            return file_info
            
        except Exception as e:
            logger.error(f"File analysis failed for {file_path}: {e}")
            raise

    def _is_in_project(self, file_path: Path) -> bool:
        """Check if file is part of a code project (.git folder)."""
        for parent in file_path.parents:
            if (parent / ".git").exists():
                return True
        return False

    def _find_project_root(self, file_path: Path) -> Optional[Path]:
        """Find the root of a code project."""
        for parent in file_path.parents:
            if (parent / ".git").exists():
                return parent
        return None

    def _build_ai_prompt(
        self,
        folder_analysis: Dict[str, Any],
        folder_path: str,
        intent: Optional[str],
        history: List,
        drive_status: Dict[str, Any]
    ) -> str:
        """Build comprehensive AI prompt with all context."""
        
        files_summary = []
        for file_info in folder_analysis["files"][:50]:  # Limit to first 50 files
            summary = f"- {file_info['name']} ({file_info['size_human']}, {file_info['category']})"
            if file_info.get("series_info"):
                series = file_info["series_info"]
                summary += f" [Series: {series['series_name']} S{series['season']}E{series['episode']}]"
            if file_info.get("in_project"):
                summary += " [Project file]"
            files_summary.append(summary)
        
        history_text = "No previous activity" if not history else "\n".join([
            f"- {h.action_type}: {h.file_name} → {h.destination_path} ({'✓' if h.success else '✗'})"
            for h in history[-10:]  # Last 10 actions
        ])
        
        drives_text = "No drives detected" if not drive_status.get("drives") else "\n".join([
            f"- {drive['path']} ({drive.get('label', 'Unknown')}, {drive.get('size_human', 'Unknown size')})"
            for drive in drive_status["drives"]
        ])

        prompt = f"""You are a smart file organizer. Analyze this folder and generate file organization operations.

FOLDER TO ORGANIZE: {folder_path}
USER INTENT: {intent or "General organization"}

CURRENT FILES ({len(folder_analysis['files'])} total):
{chr(10).join(files_summary)}

CATEGORIES FOUND: {', '.join(f"{cat}({count})" for cat, count in folder_analysis['categories'].items())}

PREVIOUS ACTIONS:
{history_text}

AVAILABLE DRIVES:
{drives_text}

RULES:
1. Move files to logical destinations based on category (Movies, Series, Documents, etc.)
2. Create proper folder structures (e.g., "Series/Breaking Bad/Season 1/")
3. Clean filenames: remove "Sanet.st.", "www.example.com-", add proper spacing
4. Delete redundant archives ONLY if extracted content is obviously organized
5. Group project files together (anything with .git)
6. Respect user's previous organization patterns from history

OUTPUT FORMAT (JSON only, no other text):
{{
  "operations": [
    {{"type": "mkdir", "path": "/target/folder", "parents": true}},
    {{"type": "move", "src": "/source/file.ext", "dest": "/target/folder/Clean Name.ext"}},
    {{"type": "delete", "path": "/source/redundant.rar"}}
  ]
}}

Generate operations for efficient, intelligent file organization:"""

        return prompt

    async def _call_ai_for_operations(self, prompt: str) -> List[Dict[str, Any]]:
        """Call AI API and parse operations."""
        try:
            if not self.shared_services.is_ai_available():
                logger.warning("AI not available, returning empty operations")
                return []
            
            logger.info("🤖 Calling AI for file organization...")
            
            # Call Gemini API
            model = self.shared_services.ai_model
            response = model.generate_content(prompt)
            
            if not response or not response.text:
                logger.warning("Empty AI response")
                return []
            
            # Parse JSON response
            response_text = response.text.strip()
            
            # Clean up response (remove markdown code blocks if present)
            if response_text.startswith("```"):
                lines = response_text.split("\n")
                response_text = "\n".join(lines[1:-1])
            
            # Parse JSON
            try:
                ai_response = json.loads(response_text)
                operations = ai_response.get("operations", [])
                
                logger.info(f"✅ AI generated {len(operations)} operations")
                return operations
                
            except json.JSONDecodeError as e:
                logger.error(f"Failed to parse AI response as JSON: {e}")
                logger.error(f"AI response was: {response_text[:500]}...")
                return []
            
        except Exception as e:
            logger.error(f"AI API call failed: {e}")
            return []


