#!/usr/bin/env python3
"""
AI Content Analyzer - Phase 5 Advanced AI Features
Provides rich metadata extraction for various file types
"""

import hashlib
import json
import logging
import os
import re
import zipfile
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
from logging.handlers import RotatingFileHandler

logger = logging.getLogger('AIContentAnalyzer')

# Setup dedicated AI interactions logger
ai_logger = logging.getLogger('AIInteractions')
ai_logger.setLevel(logging.INFO)
ai_logger.propagate = False  # Don't send to root logger

# Create logs directory
log_dir = Path(__file__).parent.parent / 'logs'
log_dir.mkdir(exist_ok=True)

# Add rotating file handler (max 10MB, keep 5 backups)
ai_log_file = log_dir / 'ai_interactions.log'
ai_handler = RotatingFileHandler(
    ai_log_file,
    maxBytes=10 * 1024 * 1024,  # 10MB
    backupCount=5
)
ai_handler.setFormatter(logging.Formatter('%(message)s'))
ai_logger.addHandler(ai_handler)


class AIContentAnalyzer:
    """
    Analyzes file content to extract rich metadata using AI and various techniques.
    Uses Google Gemini for intelligent categorization with regex fallbacks.
    Supports dynamic categories: Movies, TV Shows, Music, eBooks, Tutorials, Projects, Assets, etc.
    """
    
    def __init__(self, shared_services=None):
        self.shared_services = shared_services
        self.movie_patterns = [
            # Pattern: Title.Year.Quality.Format (most common torrent/release format)
            r'^(.+?)[\.\s](\d{4})[\.\s]',
            # Pattern: Title (Year)
            r'^(.+?)\s*\((\d{4})\)',
            # Pattern: Title Year (no separator)
            r'^(.+?)\s+(\d{4})[\.\s]',
        ]
        
        self.tv_show_patterns = [
            # Pattern: Show.S01E05
            r'(.+?)[\.\s]S(\d+)E(\d+)',
            # Pattern: Show.1x05
            r'(.+?)[\.\s](\d+)x(\d+)',
        ]
        
        self.project_indicators = {
            'DotNet': ['.csproj', '.sln', '.cs', '.vb'],
            'Flutter': ['pubspec.yaml', '.dart', 'flutter'],
            'Unity': ['.unity', 'Assets/', 'ProjectSettings/'],
            'TypeScript': ['package.json', '.tsx', '.ts', 'tsconfig.json'],
            'React': ['package.json', '.jsx', 'react'],
            'Python': ['requirements.txt', '.py', 'setup.py', '__init__.py'],
            'Java': ['.java', 'pom.xml', 'build.gradle'],
            'NodeJS': ['package.json', 'node_modules/', '.js'],
        }
    
    def _quick_archive_peek(self, archive_path: str) -> Dict[str, Any]:
        """
        Quickly peek inside an archive to see what it contains.
        Returns summary without extracting.
        """
        try:
            if not os.path.exists(archive_path):
                return {'error': 'File not found'}
            
            file_ext = Path(archive_path).suffix.lower()
            file_list = []
            
            if file_ext == '.zip':
                with zipfile.ZipFile(archive_path, 'r') as zf:
                    file_list = [f for f in zf.namelist() if not f.endswith('/')]
            elif file_ext == '.rar':
                try:
                    import rarfile
                    with rarfile.RarFile(archive_path, 'r') as rf:
                        file_list = [f for f in rf.namelist() if not f.endswith('/')]
                except ImportError:
                    return {'error': 'RAR support not available', 'file_count': '?'}
            elif file_ext == '.7z':
                try:
                    import py7zr
                    with py7zr.SevenZipFile(archive_path, 'r') as szf:
                        file_list = [f for f in szf.getnames() if not f.endswith('/')]
                except ImportError:
                    return {'error': '7z support not available', 'file_count': '?'}
            
            # Analyze contents
            if not file_list:
                return {'file_count': 0, 'summary': 'Empty archive'}
            
            # Get file types
            extensions = {}
            for f in file_list:
                ext = Path(f).suffix.lower()
                extensions[ext] = extensions.get(ext, 0) + 1
            
            # Determine main content type
            video_exts = {'.mkv', '.mp4', '.avi', '.mov', '.wmv'}
            audio_exts = {'.mp3', '.flac', '.wav', '.m4a'}
            image_exts = {'.jpg', '.jpeg', '.png', '.gif'}
            
            main_type = 'mixed'
            if any(ext in video_exts for ext in extensions.keys()):
                main_type = 'video'
            elif any(ext in audio_exts for ext in extensions.keys()):
                main_type = 'audio'
            elif any(ext in image_exts for ext in extensions.keys()):
                main_type = 'images'
            
            # Get sample filenames (first 3)
            sample_files = [Path(f).name for f in file_list[:3]]
            
            return {
                'file_count': len(file_list),
                'main_type': main_type,
                'extensions': dict(extensions),
                'sample_files': sample_files
            }
            
        except Exception as e:
            logger.warning(f"Error peeking into archive {archive_path}: {e}")
            return {'error': str(e)}
    
    def _call_ai_with_recovery(self, prompt):
        """
        SINGLE SOURCE OF TRUTH for AI calls with automatic model recovery.
        Handles deprecated/failed models by discovering and retrying with a working model.
        
        Args:
            prompt: The prompt string to send to the AI
            
        Returns:
            AI response object
            
        Raises:
            Exception: If AI is unavailable or both attempts fail
        """
        if not self.shared_services or not self.shared_services.is_ai_available():
            raise Exception("AI service not available")
        
        try:
            return self.shared_services.ai_model.generate_content(prompt)
        except Exception as first_error:
            # If model fails (e.g., deprecated), try discovery and retry once
            logger.warning(f"AI model failed, attempting recovery: {str(first_error)[:100]}")
            self.shared_services._model_discovery_attempted = False  # Reset flag to allow retry
            self.shared_services._discover_and_select_model()
            
            # Retry with recovered model
            recovered_model = self.shared_services.ai_model
            if not recovered_model:
                raise first_error
            
            logger.info("🔄 Retrying with recovered model...")
            return recovered_model.generate_content(prompt)
    
    def analyze_file(self, file_path: str, use_ai: bool = True) -> Dict[str, Any]:
        """
        Analyze a single file and return rich metadata.
        
        Args:
            file_path: Path to the file to analyze
            use_ai: If True, use AI for intelligent categorization (default: True)
            
        Returns:
            Dictionary with content metadata
        """
        try:
            file_ext = Path(file_path).suffix.lower()
            file_name = Path(file_path).name
            file_exists = os.path.exists(file_path)
            
            # If AI is requested, it is now required. No more fallbacks.
            if use_ai:
                if not self.shared_services or not self.shared_services.is_ai_available():
                    return {'success': False, 'error': 'AI service is not available or configured. Please check GEMINI_API_KEY in .env file.'}
                
                ai_result = self._analyze_with_ai(file_path, file_name, file_ext, file_exists)
                # _analyze_with_ai now always returns a dict with 'success' field
                return ai_result
            
            # Non-AI path remains for legacy or specific calls that disable AI.
            if file_ext in ['.mkv', '.mp4', '.avi', '.mov', '.wmv']:
                return self._analyze_video(file_name, file_path)
            elif file_ext in ['.pdf']:
                # PDF requires file to exist for content extraction
                if file_exists:
                    return self._analyze_pdf(file_path)
                else:
                    return {
                        'success': True,
                        'content_type': 'document',
                        'document_category': 'PDF',
                        'confidence_score': 0.7,
                        'note': 'File not accessible for content analysis'
                    }
            elif file_ext in ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff']:
                # Images require file to exist for EXIF extraction
                if file_exists:
                    return self._analyze_photo(file_path)
                else:
                    return {
                        'success': True,
                        'content_type': 'image',
                        'confidence_score': 0.8,
                        'note': 'File not accessible for EXIF analysis'
                    }
            elif file_ext in ['.zip', '.rar', '.7z']:
                # Archives require file to exist for content listing
                if file_exists:
                    return self._analyze_archive_for_content(file_path)
                else:
                    return {
                        'success': True,
                        'content_type': 'archive',
                        'archive_type': file_ext[1:],
                        'confidence_score': 0.7,
                        'note': 'File not accessible for content listing'
                    }
            elif file_ext in ['.doc', '.docx', '.txt', '.rtf']:
                return self._analyze_document(file_path)
            else:
                return {
                    'success': True,
                    'content_type': 'unknown',
                    'file_name': file_name,
                    'file_extension': file_ext,
                    'confidence_score': 0.5
                }
                
        except Exception as e:
            logger.error(f"Error analyzing file {file_path}: {e}", exc_info=True)
            return {
                'success': False,
                'error': str(e)
            }
    
    def analyze_files_batch(self, file_paths: List[str], existing_folders: List[str] = None, ai_context: str = None) -> Dict[str, Any]:
        """
        Analyze multiple files in a single AI call (MUCH faster than individual calls).
        Returns only folder suggestions, no reasons (reasons generated on-demand).
        Includes intelligent archive handling and duplicate detection.
        
        Args:
            file_paths: List of file paths to analyze
            existing_folders: List of folder names that already exist in destination (for context-aware organization)
            ai_context: Optional context string with known destinations and drives from AIContextBuilder
            
        Returns:
            {
                'success': True/False,
                'results': {
                    'file_path': {'suggested_folder': 'path', 'content_type': 'type', 'action': 'move/delete/unpack'},
                    ...
                },
                'error': 'error message if failed'
            }
        """
        if not self.shared_services or not self.shared_services.is_ai_available():
            return {'success': False, 'error': 'AI service not available'}
        
        if not file_paths:
            return {'success': True, 'results': {}}
        
        try:
            # STEP 1: Detect archives and analyze their contents
            archives_info = {}
            for fp in file_paths:
                if Path(fp).suffix.lower() in ['.rar', '.zip', '.7z']:
                    archive_content = self._quick_archive_peek(fp)
                    archives_info[fp] = archive_content
            
            # STEP 2: Build file list for AI with archive context
            file_list = []
            for fp in file_paths:
                file_info = {
                    'path': fp,
                    'name': Path(fp).name,
                    'extension': Path(fp).suffix.lower()
                }
                
                # Add archive content info if available
                if fp in archives_info:
                    file_info['is_archive'] = True
                    file_info['archive_contents'] = archives_info[fp]
                
                file_list.append(file_info)
            
            # Build context-aware prompt with known destinations and drives
            context_section = ""
            
            # Add AI context (known destinations and drives) if provided
            if ai_context:
                context_section = f"""
{ai_context}

IMPORTANT: You have access to known destinations above!
- When a file matches a known destination category, return the FULL PATH to that destination
- Example: If "Images" destination is "/home/user/Pictures", return "/home/user/Pictures" not just "Images"
- You can also create subfolders within known destinations if needed
- Choose based on drive availability, space, and usage frequency
- Only suggest new folders under the destination root if no suitable known destination exists
"""
            
            # Add existing folders context (folders in the destination root)
            existing_folders_context = ""
            if existing_folders:
                existing_folders_context = f"""
EXISTING FOLDERS in destination root:
{json.dumps(existing_folders, indent=2)}

IMPORTANT: Reuse these folder names when appropriate! If a file fits into an existing category, use that exact folder name.
"""
            
            # Analyze file diversity to determine appropriate granularity
            file_extensions = set(f['extension'] for f in file_list)
            all_same_type = len(file_extensions) == 1
            
            granularity_rule = ""
            if all_same_type and len(file_list) > 3:
                # All files are same type (e.g., all PDFs) → Allow more specific categories
                granularity_rule = """
GRANULARITY RULE: All files are the SAME TYPE, so you can use MORE SPECIFIC categories.
- For PDFs: Use categories like "Personal", "Health", "Finance", "Work", "Contracts", etc.
- For images: Use categories like "Vacation", "Family", "Work", "Screenshots", etc.
- For videos: Use categories like "Movies", "Tutorials", "Personal", etc.

BUT still keep it to ONE level - no nested paths!
"""
            else:
                # Mixed file types → Use broad generic categories
                granularity_rule = """
GRANULARITY RULE: Files are MIXED TYPES, so use BROAD, GENERIC categories.
- Use simple categories: "Documents", "Images", "Photos", "Videos", "Software", "Media", "Music", "Books"
- NO specific subcategories yet - the user will add those later with "Add Granularity"
"""
            
            # Check if any archives exist
            has_archives = any(f.get('is_archive') for f in file_list)
            archive_handling_rules = ""
            
            if has_archives:
                archive_handling_rules = """

ARCHIVE HANDLING RULES:
1. **Duplicate Detection**: If an archive filename matches an extracted file (e.g., "movie.rar" + "movie.mkv"):
   - Set archive action to "delete" (it's redundant)
   - Only organize the extracted file
   
2. **Unknown Archive Content**: If archive name doesn't reveal its content OR you're unsure:
   - Set action to "unpack" (needs analysis)
   - Put in a "ToReview" or "Archives" folder temporarily
   
3. **Known Archive Content**: If you know what's inside from the filename or content peek:
   - Set action to "move" and organize by content type
   - Example: "MovieName.rar" containing "MovieName.mkv" → suggest "delete" for .rar

For archives, you MUST include an "action" field: "move", "delete", or "unpack"
"""
            
            prompt = f"""Analyze these {len(file_list)} files and suggest the best folder structure for each.

{context_section}

{existing_folders_context}

{granularity_rule}

CRITICAL RULES FOR FOLDER NAMES:
1. NO underscores, NO compound names like "Legal_Documents" or "Personal_Photos"
2. NO nested paths like "Documents/Contracts" - just ONE level
3. Keep names simple and clear

✅ GOOD Examples (generic): "Documents", "Images", "Photos", "Videos", "Software", "Media"
✅ GOOD Examples (specific, when all same type): "Finance", "Health", "Personal", "Vacation", "Movies"
❌ BAD Examples: "Legal_Documents", "Personal_Photos", "Plans_Drawings", "Videos_Movies"

{archive_handling_rules}

Files to analyze:
{json.dumps(file_list, indent=2)}

Return ONLY valid JSON (no markdown) with this structure:
{{
  "results": {{
    "full_file_path": {{
      "suggested_folder": "FolderName or /full/path/to/known/destination",
      "content_type": "brief_type_description",
      "action": "move"  // or "delete" or "unpack" (for archives only)
    }},
    ...
  }}
}}

IMPORTANT for suggested_folder:
- If using a known destination, return the FULL PATH (e.g., "/home/user/Pictures")
- If creating a new folder, return just the folder name (e.g., "Images")
- You can append subfolders to known destinations (e.g., "/home/user/Pictures/Vacation")

Remember: If folders exist, REUSE them. If files are mixed, use GENERIC categories. If all same type, use SPECIFIC categories.
For archives: detect duplicates and suggest deletion OR suggest unpacking if content is unknown."""

            # Log to terminal (clean summary)
            CYAN = '\033[96m'
            RESET = '\033[0m'
            logger.info(f"{CYAN}🤖 Analyzing {len(file_list)} files with AI{RESET}")
            
            # Log full prompt to AI log file
            ai_logger.info("=" * 80)
            ai_logger.info(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} - AI PROMPT")
            ai_logger.info("=" * 80)
            ai_logger.info(f"Files: {len(file_list)}")
            ai_logger.info(f"Context: {len(ai_context) if ai_context else 0} chars")
            ai_logger.info(f"Existing folders: {len(existing_folders) if existing_folders else 0}")
            ai_logger.info("")
            ai_logger.info(prompt)
            ai_logger.info("")
            
            # Call AI with recovery (using shared method)
            try:
                response = self._call_ai_with_recovery(prompt)
            except Exception as e:
                return {'success': False, 'error': f'AI analysis failed: {str(e)}'}
            
            if not response or not response.text:
                return {'success': False, 'error': 'AI returned empty response'}
            
            # Parse response
            response_text = response.text.strip()
            
            # Log to terminal (clean summary)
            GREEN = '\033[92m'
            RESET = '\033[0m'
            
            # Log full response to AI log file
            ai_logger.info("=" * 80)
            ai_logger.info(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} - AI RESPONSE")
            ai_logger.info("=" * 80)
            ai_logger.info(f"Length: {len(response_text)} characters")
            ai_logger.info("")
            ai_logger.info(response_text)
            ai_logger.info("")
            ai_logger.info("")
            
            if response_text.startswith('```'):
                response_text = response_text.split('```')[1]
                if response_text.startswith('json'):
                    response_text = response_text[4:]
                response_text = response_text.strip()
            
            result = json.loads(response_text)
            results = result.get('results', {})
            
            # Log success to terminal
            logger.info(f"{GREEN}✅ AI analysis complete ({len(results)} results){RESET}")
            for file_path, file_result in results.items():
                if file_result:
                    suggested_folder = file_result.get('suggested_folder', 'MISSING')
                    action = file_result.get('action', 'move')
                    content_type = file_result.get('content_type', 'unknown')
                    logger.debug(f"  {Path(file_path).name}: folder='{suggested_folder}', action='{action}', type='{content_type}'")
                    
                    # Warn about missing or null suggested_folder
                    if 'suggested_folder' not in file_result:
                        logger.warning(f"AI result missing 'suggested_folder' for {file_path}: {file_result}")
                    elif file_result.get('suggested_folder') is None:
                        logger.warning(f"AI returned None for 'suggested_folder' for {file_path}: {file_result}")
            
            return {
                'success': True,
                'results': results
            }
            
        except json.JSONDecodeError as e:
            error_msg = f"AI returned invalid JSON: {str(e)}"
            logger.error(error_msg)
            return {'success': False, 'error': error_msg}
        except Exception as e:
            error_msg = f"Batch analysis error: {str(e)}"
            logger.error(error_msg)
            return {'success': False, 'error': error_msg}
    
    def add_granularity(self, folder_path: str, items: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Add ONE level of granularity to items in a folder.
        AI decides which items should go into subfolders and which should stay.
        
        Args:
            folder_path: The folder being organized (e.g., "/Destination/Documents")
            items: List of items with 'path', 'name', 'is_file', 'is_dir', 'extension'
            
        Returns:
            {
                'success': True/False,
                'suggestions': {
                    'item_path': {'subfolder': 'SubfolderName' or None},
                    ...
                }
            }
        """
        if not self.shared_services or not self.shared_services.is_ai_available():
            return {'success': False, 'error': 'AI service is not available or configured.'}
        
        try:
            folder_name = Path(folder_path).name
            
            prompt = f"""You are organizing the "{folder_name}" folder. Add ONE level of granularity.

CRITICAL RULES:
1. You can create subfolders, but ONLY ONE LEVEL deep
2. NOT ALL items need to go into subfolders - only organize items where it makes sense
3. Items that don't need subcategorization should stay in the current folder (return null for subfolder)

Current folder: {folder_name}
Items to analyze:
{json.dumps(items, indent=2)}

Examples of good decisions:
- If you see 10 contracts and 2 random notes → move contracts to "Contracts/" subfolder, leave notes in "{folder_name}/"
- If you see 5 photos from 2024 and 3 from 2025 → create "2024/" and "2025/" subfolders
- If you see 3 random unrelated files → leave them all in "{folder_name}/" (no subfolder needed)

Return ONLY valid JSON (no markdown):
{{
  "suggestions": {{
    "full_item_path": {{
      "subfolder": "SubfolderName"  // or null if item should stay in current folder
    }},
    ...
  }}
}}

Be smart and practical. Only create subfolders when there's a clear benefit."""

            # Call AI with recovery
            try:
                response = self._call_ai_with_recovery(prompt)
            except Exception as e:
                return {'success': False, 'error': f'AI analysis failed: {str(e)}'}
            
            if not response or not response.text:
                return {'success': False, 'error': 'AI returned empty response'}
            
            # Parse response
            response_text = response.text.strip()
            if response_text.startswith('```'):
                response_text = response_text.split('```')[1]
                if response_text.startswith('json'):
                    response_text = response_text[4:]
                response_text = response_text.strip()
            
            result = json.loads(response_text)
            return {
                'success': True,
                'suggestions': result.get('suggestions', {})
            }
            
        except json.JSONDecodeError as e:
            error_msg = f"AI returned invalid JSON: {str(e)}"
            logger.error(error_msg)
            return {'success': False, 'error': error_msg}
        except Exception as e:
            error_msg = f"Add granularity error: {str(e)}"
            logger.error(error_msg)
            return {'success': False, 'error': error_msg}
    
    def _analyze_with_ai(self, file_path: str, file_name: str, file_ext: str, file_exists: bool) -> Dict[str, Any]:
        """
        Use AI (Gemini) to intelligently categorize and extract metadata from files.
        Supports dynamic categories like: movies, tv_shows, music, ebooks, tutorials, 
        projects, assets (3d_models, brushes, plugins), documents, etc.
        
        Returns a dict with 'success' field. If success=False, includes 'error' field with details.
        """
        try:
            if not self.shared_services or not self.shared_services.ai_model:
                return {
                    'success': False,
                    'error': 'AI service not initialized. Please check GEMINI_API_KEY in .env file.'
                }
            
            # Build context for AI
            parent_dir = Path(file_path).parent.name
            file_size_info = ""
            if file_exists:
                try:
                    size = os.path.getsize(file_path)
                    file_size_info = f", size: {size} bytes"
                except:
                    pass
            
            prompt = f"""Analyze this file and determine the best way to organize it.

Filename: {file_name}
Extension: {file_ext}
Parent Directory: {parent_dir}
File Exists: {file_exists}{file_size_info}

Your task:
1. Identify what type of file this is (movie, document, invoice, photo, project file, etc.)
2. Extract any relevant metadata from the filename and context
3. Decide the BEST folder structure for organizing this file

IMPORTANT: You have COMPLETE FREEDOM to create any folder structure you want. Think about:
- Specific sub-categories (e.g., "Documents/Financial/Invoices/2024" instead of just "Documents")
- Project names (e.g., "Projects/WebsiteRedesign/Assets")
- Time-based organization (e.g., "Photos/2024/October" or "Archives/2023")
- Company or client names (e.g., "Clients/AcmeCorp/Contracts")
- Any other logical grouping that makes sense

Examples of good folder suggestions:
- "Movies/Action/2024" for an action movie from 2024
- "Documents/Financial/Invoices/CompanyName" for a company invoice
- "Projects/MyApp/Documentation" for project documentation
- "Photos/Vacation/Italy_2024" for vacation photos
- "Archives/OldProjects/2020" for old archived projects

Return ONLY valid JSON with this structure (no markdown, no extra text):
{{
  "success": true,
  "content_type": "descriptive_type",
  "confidence_score": 0.0-1.0,
  "metadata": {{
    "key": "value pairs with any relevant info you extracted"
  }},
  "description": "brief description of what this file is",
  "suggested_folder": "Your/Custom/Folder/Path",
  "reason": "A clear, user-friendly explanation of why this file should be organized this way. Explain your folder choice."
}}

Be creative and intelligent with your folder suggestions. Use the filename and context to create the most logical organization structure."""

            # Call Gemini with automatic recovery on model failure (using shared method)
            try:
                response = self._call_ai_with_recovery(prompt)
            except Exception as e:
                return {
                    'success': False,
                    'error': f'AI analysis failed: {str(e)}'
                }
            
            if not response or not response.text:
                return {
                    'success': False,
                    'error': 'AI returned empty response. The API may be rate-limited or unavailable.'
                }
            
            # Parse AI response
            response_text = response.text.strip()
            
            # Remove markdown code blocks if present
            if response_text.startswith('```'):
                response_text = response_text.split('```')[1]
                if response_text.startswith('json'):
                    response_text = response_text[4:]
                response_text = response_text.strip()
            
            result = json.loads(response_text)
            
            # Flatten metadata into main result
            if 'metadata' in result:
                metadata = result.pop('metadata')
                result.update(metadata)
            
            logger.info(f"🤖 AI analysis for {file_name}: {result.get('content_type')} (confidence: {result.get('confidence_score')})")
            return result
            
        except json.JSONDecodeError as e:
            error_msg = f"AI returned invalid JSON: {str(e)}"
            logger.warning(f"AI analysis failed for {file_name}: {error_msg}")
            return {'success': False, 'error': error_msg}
        except Exception as e:
            error_msg = f"AI analysis error: {str(e)}"
            logger.warning(f"AI analysis failed for {file_name}: {error_msg}")
            return {'success': False, 'error': error_msg}
    
    def _analyze_video(self, file_name: str, file_path: str) -> Dict[str, Any]:
        """Analyze video files (movies and TV shows)"""
        # Try movie patterns first
        for pattern in self.movie_patterns:
            match = re.search(pattern, file_name, re.IGNORECASE)
            if match:
                title = match.group(1).replace('.', ' ').replace('_', ' ').strip()
                year = int(match.group(2))
                
                # Extract quality information
                quality = self._extract_quality(file_name)
                
                # Extract release group
                release_group = self._extract_release_group(file_name)
                
                # Determine genre from filename keywords (basic approach)
                genre = self._detect_genre(file_name)
                
                result = {
                    'success': True,
                    'content_type': 'movie',
                    'title': title,
                    'year': year,
                    'confidence_score': 0.90
                }
                
                # Add optional fields
                if quality:
                    result['quality'] = quality
                if release_group:
                    result['release_group'] = release_group
                if genre and genre != 'Unknown':
                    result['genre'] = genre
                
                result['description'] = f'{title} ({year})'
                result['keywords'] = self._extract_keywords(file_name)
                
                return result
        
        # Try TV show patterns
        for pattern in self.tv_show_patterns:
            match = re.search(pattern, file_name, re.IGNORECASE)
            if match:
                show_name = match.group(1).replace('.', ' ').replace('_', ' ').strip()
                season = int(match.group(2))
                episode = int(match.group(3))
                
                return {
                    'success': True,
                    'content_type': 'tvshow',
                    'show_name': show_name,
                    'season': season,
                    'episode': episode,
                    'description': f'{show_name} - S{season:02d}E{episode:02d}',
                    'confidence_score': 0.92
                }
        
        # Generic video file
        return {
            'success': True,
            'content_type': 'video',
            'title': file_name,
            'confidence_score': 0.60
        }
    
    def _analyze_pdf(self, file_path: str) -> Dict[str, Any]:
        """Analyze PDF documents (invoices, receipts, general documents)"""
        try:
            # Try to extract text from PDF
            from PyPDF2 import PdfReader
            
            reader = PdfReader(file_path)
            if len(reader.pages) == 0:
                return {
                    'success': True,
                    'content_type': 'document',
                    'confidence_score': 0.5
                }
            
            # Extract text from first page
            first_page_text = reader.pages[0].extract_text().lower()
            
            # Detect document type based on keywords
            if any(keyword in first_page_text for keyword in ['invoice', 'rechnung', 'factura', 'bill']):
                return self._analyze_invoice(first_page_text, file_path)
            elif any(keyword in first_page_text for keyword in ['contract', 'vertrag', 'agreement']):
                return {
                    'success': True,
                    'content_type': 'contract',
                    'document_category': 'Contract',
                    'confidence_score': 0.85
                }
            else:
                return {
                    'success': True,
                    'content_type': 'document',
                    'document_category': 'General',
                    'confidence_score': 0.70
                }
                
        except Exception as e:
            logger.warning(f"Error analyzing PDF: {e}")
            return {
                'success': True,
                'content_type': 'document',
                'confidence_score': 0.5
            }
    
    def _analyze_invoice(self, text: str, file_path: str) -> Dict[str, Any]:
        """Extract invoice-specific information"""
        result = {
            'success': True,
            'content_type': 'invoice',
            'document_category': 'Invoice',
            'confidence_score': 0.88
        }
        
        # Try to extract company name (look for common patterns)
        company_patterns = [
            r'(?:from|von|de)[\s:]+([A-Z][A-Za-z\s&]+?)(?:\n|$)',
            r'([A-Z][A-Za-z\s&]{3,30})[\s\n]+(?:invoice|rechnung)',
        ]
        
        for pattern in company_patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                result['company'] = match.group(1).strip()
                break
        
        # Try to extract amount (look for currency patterns)
        amount_patterns = [
            r'(?:total|gesamt|sum|amount)[\s:]*(?:€|EUR|$)?\s*(\d+[.,]\d{2})',
            r'(\d+[.,]\d{2})\s*(?:€|EUR|$)',
        ]
        
        for pattern in amount_patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                amount_str = match.group(1).replace(',', '.')
                result['amount'] = float(amount_str)
                result['currency'] = 'EUR'
                break
        
        # Try to extract date
        date_patterns = [
            r'(\d{1,2}[./]\d{1,2}[./]\d{2,4})',
            r'(\d{4}-\d{2}-\d{2})',
        ]
        
        for pattern in date_patterns:
            match = re.search(pattern, text)
            if match:
                result['document_date'] = match.group(1)
                break
        
        return result
    
    def _analyze_photo(self, file_path: str) -> Dict[str, Any]:
        """Extract EXIF data from photos"""
        try:
            from PIL import Image
            from PIL.ExifTags import TAGS
            
            image = Image.open(file_path)
            exif_data = image._getexif()
            
            result = {
                'success': True,
                'content_type': 'image',
                'confidence_score': 1.0
            }
            
            if exif_data:
                # Extract relevant EXIF tags
                for tag_id, value in exif_data.items():
                    tag = TAGS.get(tag_id, tag_id)
                    
                    if tag == 'DateTimeOriginal':
                        result['date_taken'] = str(value)
                    elif tag == 'Model':
                        result['camera_model'] = str(value)
                    elif tag == 'Make':
                        result['camera_make'] = str(value)
                    elif tag == 'GPSInfo':
                        result['has_gps_data'] = True
            
            return result
            
        except Exception as e:
            logger.warning(f"Error extracting EXIF data: {e}")
            return {
                'success': True,
                'content_type': 'image',
                'confidence_score': 0.8
            }
    
    def _analyze_document(self, file_path: str) -> Dict[str, Any]:
        """Analyze general documents"""
        return {
            'success': True,
            'content_type': 'document',
            'document_category': 'General',
            'confidence_score': 0.75
        }
    
    def _analyze_archive_for_content(self, archive_path: str) -> Dict[str, Any]:
        """
        Simplified archive analysis for content batch endpoint.
        Lists contents without deep project detection.
        """
        try:
            if not os.path.exists(archive_path):
                return {
                    'success': False,
                    'error': f'Archive not found: {archive_path}'
                }
            
            file_ext = Path(archive_path).suffix.lower()
            
            if file_ext == '.zip':
                with zipfile.ZipFile(archive_path, 'r') as zip_file:
                    file_list = zip_file.namelist()
                    file_count = len([f for f in file_list if not f.endswith('/')])
                    total_size = sum(info.file_size for info in zip_file.infolist() if not info.is_dir())
            elif file_ext == '.rar':
                try:
                    import rarfile
                    with rarfile.RarFile(archive_path, 'r') as rar_file:
                        file_list = rar_file.namelist()
                        file_count = len([f for f in file_list if not f.endswith('/')])
                        total_size = sum(info.file_size for info in rar_file.infolist() if not info.isdir())
                except ImportError:
                    return {
                        'success': True,
                        'content_type': 'archive',
                        'archive_type': 'rar',
                        'error': 'RAR support not available',
                        'confidence_score': 0.6
                    }
            elif file_ext == '.7z':
                try:
                    import py7zr
                    with py7zr.SevenZipFile(archive_path, 'r') as sz_file:
                        file_list = sz_file.getnames()
                        file_count = len([f for f in file_list if not f.endswith('/')])
                        total_size = sum(info.uncompressed for info in sz_file.list() if not info.is_directory)
                except ImportError:
                    return {
                        'success': True,
                        'content_type': 'archive',
                        'archive_type': '7z',
                        'error': '7z support not available',
                        'confidence_score': 0.6
                    }
            else:
                return {
                    'success': False,
                    'error': f'Unsupported archive format: {file_ext}'
                }
            
            # Get a sample of files (first 20)
            sample_files = [f for f in file_list if not f.endswith('/')][:20]
            
            return {
                'success': True,
                'content_type': 'archive',
                'archive_type': file_ext[1:],  # Remove the dot
                'file_count': file_count,
                'total_size': total_size,
                'sample_files': sample_files,
                'confidence_score': 1.0
            }
            
        except Exception as e:
            logger.warning(f"Error analyzing archive: {e}")
            return {
                'success': True,
                'content_type': 'archive',
                'error': str(e),
                'confidence_score': 0.5
            }
    
    def _extract_quality(self, filename: str) -> Optional[str]:
        """Extract video quality information from filename"""
        filename_lower = filename.lower()
        
        # Quality patterns (in order of preference)
        quality_patterns = [
            (r'2160p', '2160p'),
            (r'4k', '4K'),
            (r'1080p', '1080p'),
            (r'720p', '720p'),
            (r'480p', '480p'),
            (r'telesync|ts|telecine', 'TELESYNC'),
            (r'cam|camrip', 'CAM'),
            (r'hdrip', 'HDRip'),
            (r'brrip|blu-?ray', 'BluRay'),
            (r'web-?dl|webdl', 'WEB-DL'),
            (r'webrip', 'WEBRip'),
            (r'dvdrip', 'DVDRip'),
        ]
        
        for pattern, quality in quality_patterns:
            if re.search(pattern, filename_lower):
                return quality
        
        return None
    
    def _extract_release_group(self, filename: str) -> Optional[str]:
        """Extract release group from filename (usually after last dash)"""
        # Pattern: -GROUPNAME at end (before extension)
        match = re.search(r'-([A-Za-z0-9]+)(?:\.[a-z0-9]{2,4})?$', filename, re.IGNORECASE)
        if match:
            return match.group(1)
        
        return None
    
    def _detect_genre(self, filename: str) -> str:
        """Detect movie genre from filename keywords"""
        filename_lower = filename.lower()
        
        if any(word in filename_lower for word in ['action', 'fight', 'war']):
            return 'Action'
        elif any(word in filename_lower for word in ['horror', 'scary', 'zombie']):
            return 'Horror'
        elif any(word in filename_lower for word in ['comedy', 'funny']):
            return 'Comedy'
        elif any(word in filename_lower for word in ['romance', 'love']):
            return 'Romance'
        elif any(word in filename_lower for word in ['sci-fi', 'scifi', 'space']):
            return 'Science Fiction'
        else:
            return 'Unknown'
    
    def _extract_keywords(self, filename: str) -> List[str]:
        """Extract keywords from filename"""
        # Remove common separators and extract words
        words = re.findall(r'\b[A-Za-z]{3,}\b', filename)
        # Filter out common words and quality indicators
        stop_words = {'the', 'and', 'for', 'with', 'from', '1080p', '720p', 'bluray', 'hdtv', 'web'}
        keywords = [w.lower() for w in words if w.lower() not in stop_words]
        return keywords[:10]  # Limit to 10 keywords
    
    def scan_duplicates(self, file_paths: List[str]) -> Dict[str, Any]:
        """
        Scan files for duplicates based on content hash.
        
        Args:
            file_paths: List of file paths to scan
            
        Returns:
            Dictionary with duplicate groups
        """
        try:
            # Step 1: Group files by size (performance optimization)
            files_by_size = {}
            for file_path in file_paths:
                if not os.path.exists(file_path):
                    continue
                
                size = os.path.getsize(file_path)
                if size not in files_by_size:
                    files_by_size[size] = []
                files_by_size[size].append(file_path)
            
            # Step 2: Calculate hashes only for files with same size
            hash_to_files = {}
            for size, files in files_by_size.items():
                if len(files) < 2:
                    continue  # Skip files with unique size
                
                for file_path in files:
                    file_hash = self._calculate_file_hash(file_path)
                    if file_hash not in hash_to_files:
                        hash_to_files[file_hash] = []
                    hash_to_files[file_hash].append(file_path)
            
            # Step 3: Build duplicate groups
            duplicate_groups = []
            total_wasted_space = 0
            total_duplicate_files = 0
            
            for file_hash, files in hash_to_files.items():
                if len(files) < 2:
                    continue  # Not a duplicate
                
                file_size = os.path.getsize(files[0])
                wasted_space = file_size * (len(files) - 1)
                total_wasted_space += wasted_space
                total_duplicate_files += len(files) - 1
                
                # Analyze each file and recommend which to keep
                file_infos = []
                for file_path in files:
                    info = self._get_file_info_for_duplicate(file_path)
                    file_infos.append(info)
                
                # Sort by recommendation score (higher is better)
                file_infos.sort(key=lambda x: x['_score'], reverse=True)
                file_infos[0]['is_recommended_to_keep'] = True
                file_infos[0]['recommendation_reason'] = self._get_keep_reason(file_infos[0])
                
                for i in range(1, len(file_infos)):
                    file_infos[i]['is_recommended_to_keep'] = False
                    file_infos[i]['recommendation_reason'] = self._get_delete_reason(file_infos[i], file_infos[0])
                
                # Remove internal scoring
                for info in file_infos:
                    del info['_score']
                
                duplicate_groups.append({
                    'file_hash': file_hash,
                    'file_size': file_size,
                    'wasted_space': wasted_space,
                    'files': file_infos
                })
            
            return {
                'success': True,
                'total_files_scanned': len(file_paths),
                'duplicate_groups_found': len(duplicate_groups),
                'total_duplicate_files': total_duplicate_files,
                'total_wasted_space': total_wasted_space,
                'duplicate_groups': duplicate_groups
            }
            
        except Exception as e:
            logger.error(f"Error scanning duplicates: {e}", exc_info=True)
            return {
                'success': False,
                'error': str(e)
            }
    
    def suggest_alternatives(self, rejected_operation: Dict[str, Any]) -> Dict[str, Any]:
        """
        Suggest alternative destinations for a file using AI.
        """
        try:
            file_path = rejected_operation['source']
            current_analysis = self.analyze_file(file_path)

            if not self.shared_services or not self.shared_services.is_ai_available():
                return {'success': False, 'error': 'AI service is not available or configured.'}

            file_name = Path(file_path).name
            base_path = Path(rejected_operation['destination']).parent.parent

            # json is already imported at the top of the file
            prompt = f"""
            The user rejected an automatic file organization suggestion. Your task is to provide 2-4 diverse and intelligent alternative destinations.

            File Information:
            - Filename: "{file_name}"
            - Rejected Destination: "{rejected_operation['destination']}"
            - Reason for Rejection: The user disagreed with the category.
            - Content Analysis: {json.dumps(current_analysis, indent=2)}

            Instructions:
            1.  Generate suggestions based on the 'Content Analysis'.
            2.  All new destination paths MUST start with the base path: "{base_path}/"
            3.  Provide a variety of organizational strategies. Examples:
                - By a more specific content type (e.g., a 'document' could be an 'Invoice', 'Contract', or 'Resume').
                - By a topic or project name mentioned in the content (e.g., 'ProjectAlpha', 'Client_AcmeCorp').
                - By the year or date (e.g., 'Invoices/2024/', 'Photos/2023-10-October/').

            Example Scenarios:
            - If a PDF was rejected from '/Docs/', you could suggest '/Invoices/' or '/Contracts/'.
            - If 'ProjectX_Report.pdf' was rejected from '/Documents/', a good alternative is '/ProjectX/Reports/'.

            Return ONLY a valid JSON object with the following structure. Do not include any other text or markdown.
            {{
              "success": true,
              "alternatives": [
                {{
                  "destination": "{base_path}/Alternative_A/{file_name}",
                  "reason": "A brief, user-friendly explanation for this suggestion."
                }},
                {{
                  "destination": "{base_path}/Alternative_B/{file_name}",
                  "reason": "Another explanation."
                }}
              ]
            }}
            """

            response = self.shared_services.ai_model.generate_content(prompt)
            if not response or not response.text:
                logger.error("AI returned an empty response for `suggest-alternatives`.")
                return {'success': False, 'error': 'AI returned an empty response.'}

            response_text = response.text.strip()
            logger.debug(f"AI raw response for alternatives: {response_text}")

            if response_text.startswith('```'):
                response_text = response_text.split('```')[1]
                if response_text.startswith('json'):
                    response_text = response_text[4:]
                response_text = response_text.strip()

            result = json.loads(response_text)
            
            # Convert to FileOperation format
            final_alternatives = []
            for alt in result.get('alternatives', []):
                final_alternatives.append({
                    'source': file_path,
                    'destination': alt['destination'],
                    'reason': alt['reason'],
                    'type': 'move'
                })
            
            logger.info(f"🤖 AI suggestions for {file_name} generated successfully.")
            return {"success": True, "alternatives": final_alternatives}

        except Exception as e:
            logger.error(f"Error generating AI suggestions for {rejected_operation['source']}: {e}", exc_info=True)
            return {'success': False, 'error': f'An exception occurred while generating AI suggestions: {e}'}

    def _suggest_alternatives_fallback(self, rejected_operation: Dict[str, Any], current_analysis: Dict[str, Any]) -> Dict[str, Any]:
        """Fallback for generating suggestions without AI."""
        # This method is now deprecated and will be removed in a future refactor.
        # For now, it remains to avoid breaking other parts of the system that might call it directly.
        alternatives = []
        source_path = rejected_operation['source']
        p = Path(source_path)
        dest_path = Path(rejected_operation['destination'])
        base_dest = dest_path.parent.parent
        
        # 1. Suggestion based on content type
        content_type = current_analysis.get('content_type', 'General').capitalize()
        if content_type:
            alternatives.append({
                "source": source_path,
                "destination": str(base_dest / content_type / p.name),
                "reason": f"Categorize by content type: {content_type}",
                "type": "move"
            })

        # 2. Suggestion based on file extension
        ext_folder = p.suffix[1:].upper() + "_Files" if p.suffix else "Other_Files"
        alternatives.append({
            "source": source_path,
            "destination": str(base_dest / ext_folder / p.name),
            "reason": f"Group by file type ({p.suffix})",
            "type": "move"
        })

        # 3. Suggestion based on date
        try:
            mtime = p.stat().st_mtime
            date = datetime.fromtimestamp(mtime)
            year_folder = date.strftime('%Y')
            month_folder = date.strftime('%Y-%m')
            alternatives.append({
                "source": source_path,
                "destination": str(base_dest / "Dated" / year_folder / month_folder / p.name),
                "reason": f"Organize by modification date ({month_folder})",
                "type": "move"
            })
        except FileNotFoundError:
            pass

        return {"success": True, "alternatives": alternatives}
        
    def _calculate_file_hash(self, file_path: str) -> str:
        """Calculate SHA256 hash of a file"""
        sha256_hash = hashlib.sha256()
        with open(file_path, 'rb') as f:
            # Read file in chunks to handle large files
            for byte_block in iter(lambda: f.read(4096), b''):
                sha256_hash.update(byte_block)
        return sha256_hash.hexdigest()
    
    def _get_file_info_for_duplicate(self, file_path: str) -> Dict[str, Any]:
        """Get file information for duplicate detection"""
        path = Path(file_path)
        stat = os.stat(file_path)
        
        # Calculate score for recommendation
        score = 0
        
        # Prefer newer files
        score += stat.st_mtime / 1000000000  # Normalize timestamp
        
        # Prefer files not in temp/downloads folders
        path_lower = str(path).lower()
        if any(word in path_lower for word in ['temp', 'tmp', 'download', 'trash', 'recycle']):
            score -= 100
        
        # Penalize files with "copy", "backup" in name
        name_lower = path.name.lower()
        if any(word in name_lower for word in ['copy', 'backup', 'duplicate', '(1)', '(2)']):
            score -= 50
        
        return {
            'file_path': file_path,
            'file_name': path.name,
            'directory': str(path.parent),
            'last_modified': datetime.fromtimestamp(stat.st_mtime).isoformat(),
            '_score': score  # Internal scoring
        }
    
    def _get_keep_reason(self, file_info: Dict) -> str:
        """Generate reason for keeping this file"""
        reasons = []
        
        # Check if newest
        reasons.append("Most recent file")
        
        # Check location
        if not any(word in file_info['directory'].lower() for word in ['temp', 'download', 'trash']):
            reasons.append("in good location")
        
        # Check filename
        if not any(word in file_info['file_name'].lower() for word in ['copy', 'backup']):
            reasons.append("clean filename")
        
        return " - ".join(reasons) if reasons else "Recommended to keep"
    
    def _get_delete_reason(self, file_info: Dict, keep_file: Dict) -> str:
        """Generate reason for deleting this file"""
        if 'copy' in file_info['file_name'].lower() or 'backup' in file_info['file_name'].lower():
            return "Duplicate copy, can be safely deleted"
        
        if file_info['last_modified'] < keep_file['last_modified']:
            return "Older duplicate, can be safely deleted"
        
        return "Duplicate file, can be safely deleted"
    
    def analyze_archive(self, archive_path: str) -> Dict[str, Any]:
        """
        Analyze archive contents without extracting.
        Detects project types and categorizes files.
        
        Args:
            archive_path: Path to ZIP/RAR/7z file
            
        Returns:
            Dictionary with archive analysis
        """
        try:
            if not os.path.exists(archive_path):
                return {
                    'success': False,
                    'error': f'Archive not found: {archive_path}'
                }
            
            file_ext = Path(archive_path).suffix.lower()
            
            if file_ext == '.zip':
                return self._analyze_zip(archive_path)
            elif file_ext == '.rar':
                return self._analyze_rar(archive_path)
            elif file_ext == '.7z':
                return self._analyze_7z(archive_path)
            else:
                return {
                    'success': False,
                    'error': f'Unsupported archive format: {file_ext}'
                }
                
        except Exception as e:
            logger.error(f"Error analyzing archive: {e}", exc_info=True)
            return {
                'success': False,
                'error': str(e)
            }
    
    def _analyze_zip(self, archive_path: str) -> Dict[str, Any]:
        """Analyze ZIP archive"""
        with zipfile.ZipFile(archive_path, 'r') as zip_file:
            file_list = zip_file.namelist()
            total_size = sum(info.file_size for info in zip_file.infolist())
            
            return self._analyze_archive_contents(archive_path, file_list, total_size)
    
    def _analyze_rar(self, archive_path: str) -> Dict[str, Any]:
        """Analyze RAR archive"""
        try:
            import rarfile
            with rarfile.RarFile(archive_path, 'r') as rar_file:
                file_list = rar_file.namelist()
                total_size = sum(info.file_size for info in rar_file.infolist())
                
                return self._analyze_archive_contents(archive_path, file_list, total_size)
        except Exception as e:
            logger.warning(f"RAR support not available: {e}")
            return {
                'success': False,
                'error': 'RAR support not available'
            }
    
    def _analyze_7z(self, archive_path: str) -> Dict[str, Any]:
        """Analyze 7z archive"""
        try:
            import py7zr
            with py7zr.SevenZipFile(archive_path, 'r') as sz_file:
                file_list = sz_file.getnames()
                total_size = sum(info.uncompressed for info in sz_file.list())
                
                return self._analyze_archive_contents(archive_path, file_list, total_size)
        except Exception as e:
            logger.warning(f"7z support not available: {e}")
            return {
                'success': False,
                'error': '7z support not available'
            }
    
    def _analyze_archive_contents(self, archive_path: str, file_list: List[str], total_size: int) -> Dict[str, Any]:
        """Analyze the contents of an archive"""
        # Detect project type
        detected_project = self._detect_project_type(file_list)
        
        # Categorize files
        contains_executables = any(f.endswith(('.exe', '.dll', '.so', '.dylib')) for f in file_list)
        contains_source_code = any(f.endswith(('.cs', '.py', '.java', '.js', '.ts', '.cpp', '.c', '.dart')) for f in file_list)
        
        # Determine recommended action
        if detected_project:
            recommended_action = 'Extract'
        elif contains_executables:
            recommended_action = 'KeepArchived'
        elif contains_source_code:
            recommended_action = 'Extract'
        else:
            recommended_action = 'ReviewManually'
        
        # Build file info list (limit to first 100 files for performance)
        files = []
        for file_path in file_list[:100]:
            if file_path.endswith('/'):  # Skip directories
                continue
            
            files.append({
                'relative_path': file_path,
                'file_name': Path(file_path).name,
                'size': 0,  # Size not easily available without extracting
                'suggested_category': self._categorize_file(file_path)
            })
        
        return {
            'success': True,
            'archive_path': archive_path,
            'total_size': total_size,
            'file_count': len(file_list),
            'contains_executables': contains_executables,
            'contains_source_code': contains_source_code,
            'detected_project_type': detected_project,
            'recommended_action': recommended_action,
            'files': files
        }
    
    def _detect_project_type(self, file_list: List[str]) -> Optional[str]:
        """Detect project type from file list"""
        file_list_lower = [f.lower() for f in file_list]
        
        for project_type, indicators in self.project_indicators.items():
            matches = 0
            for indicator in indicators:
                if any(indicator.lower() in f for f in file_list_lower):
                    matches += 1
            
            # If at least 2 indicators match, consider it that project type
            if matches >= 2:
                return project_type
        
        return None
    
    def _categorize_file(self, file_path: str) -> str:
        """Categorize a file based on its extension"""
        ext = Path(file_path).suffix.lower()
        
        if ext in ['.cs', '.py', '.java', '.js', '.ts', '.cpp', '.c', '.dart', '.go', '.rb']:
            return 'SourceCode'
        elif ext in ['.csproj', '.sln', '.json', '.yaml', '.yml', '.xml', '.config']:
            return 'ProjectFile'
        elif ext in ['.jpg', '.jpeg', '.png', '.gif', '.bmp']:
            return 'Image'
        elif ext in ['.pdf', '.doc', '.docx', '.txt']:
            return 'Document'
        elif ext in ['.exe', '.dll', '.so', '.dylib']:
            return 'Executable'
        else:
            return 'Other'

