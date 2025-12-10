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
    
    def _parse_ai_error(self, error: Exception) -> dict:
        """
        Parse AI error and return structured error information.
        
        Returns:
            Dictionary with error_type, message, user_message, code
        """
        error_str = str(error).lower()
        
        # Authentication errors
        if '401' in error_str or 'unauthorized' in error_str or 'invalid authentication' in error_str or 'invalid api key' in error_str:
            return {
                'error_type': 'authentication_error',
                'message': str(error),
                'user_message': 'Invalid API key. Please check your AI provider configuration.',
                'code': 401
            }
        
        # Insufficient credits / payment required
        if '402' in error_str or 'insufficient' in error_str or 'quota' in error_str or 'credits' in error_str or 'billing' in error_str:
            return {
                'error_type': 'insufficient_credits',
                'message': str(error),
                'user_message': 'Insufficient AI credits. Please add funds to your AI provider account.',
                'code': 402
            }
        
        # Rate limit errors
        if '429' in error_str or 'rate limit' in error_str or 'too many requests' in error_str:
            return {
                'error_type': 'rate_limit',
                'message': str(error),
                'user_message': 'Too many requests. Please wait a moment and try again.',
                'code': 429
            }
        
        # Model not found
        if '404' in error_str or 'not found' in error_str or 'model' in error_str:
            return {
                'error_type': 'model_not_found',
                'message': str(error),
                'user_message': 'AI model not found. Please check your model configuration.',
                'code': 404
            }
        
        # Timeout errors
        if 'timeout' in error_str or '504' in error_str or '503' in error_str:
            return {
                'error_type': 'timeout',
                'message': str(error),
                'user_message': 'AI request timed out. Please try again with fewer files.',
                'code': 504
            }
        
        # Server errors
        if '500' in error_str or '502' in error_str or 'server error' in error_str:
            return {
                'error_type': 'server_error',
                'message': str(error),
                'user_message': 'AI service is temporarily unavailable. Please try again later.',
                'code': 500
            }
        
        # Generic error
        return {
            'error_type': 'unknown_error',
            'message': str(error),
            'user_message': f'AI request failed: {str(error)[:100]}',
            'code': 500
        }
    
    def _call_ai_with_recovery(self, prompt):
        """
        SINGLE SOURCE OF TRUTH for AI calls with automatic model recovery.
        Handles deprecated/failed models by discovering and retrying with a working model.
        
        Args:
            prompt: The prompt string to send to the AI
            
        Returns:
            AI response object
            
        Raises:
            Exception: If AI is unavailable or both attempts fail (with structured error info)
        """
        if not self.shared_services or not self.shared_services.is_ai_available():
            error = Exception("AI service not available")
            error.error_details = {
                'error_type': 'service_unavailable',
                'message': 'AI service not initialized',
                'user_message': 'AI service is not configured. Please check your API key in settings.',
                'code': 503
            }
            raise error
        
        try:
            return self.shared_services.ai_model.generate_content(prompt)
        except Exception as first_error:
            # Parse error details
            error_details = self._parse_ai_error(first_error)
            
            # Don't retry on authentication or credit errors
            if error_details['error_type'] in ['authentication_error', 'insufficient_credits']:
                first_error.error_details = error_details
                raise first_error
            
            # Try recovery for other errors
            logger.warning(f"AI model failed, attempting recovery: {str(first_error)[:100]}")
            self.shared_services._model_discovery_attempted = False  # Reset flag to allow retry
            self.shared_services._discover_and_select_model()
            
            # Retry with recovered model
            recovered_model = self.shared_services.ai_model
            if not recovered_model:
                first_error.error_details = error_details
                raise first_error
            
            logger.info("🔄 Retrying with recovered model...")
            try:
                return recovered_model.generate_content(prompt)
            except Exception as second_error:
                # Attach error details to exception
                second_error.error_details = self._parse_ai_error(second_error)
                raise second_error
    
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
            
            # Non-AI path for specific calls that disable AI.
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
    
    def _build_prompt_for_batch(self, file_paths: List[str], existing_folders: List[str] = None, ai_context: str = None, files_metadata: Dict[str, Dict] = None, source_path: str = None, granularity: int = 1) -> Dict[str, Any]:
        """
        Build the AI prompt for batch analysis WITHOUT sending it to AI.
        Used for token counting and by analyze_files_batch.
        
        Returns dict with:
            - prompt: The complete prompt string
            - source_folders: List of source folder paths (for response parsing)
            - dest_folders: List of destination folder paths (for response parsing)
            - file_list_for_ai: List of file entries sent to AI (for response parsing)
            - files_by_folder: Dict of files grouped by folder (for logging)
        """
        # This is the same logic as analyze_files_batch but only builds the prompt
        # We'll extract the prompt building logic here
        
        # STEP 1: Detect archives
        archives_info = {}
        for fp in file_paths:
            if Path(fp).suffix.lower() in ['.rar', '.zip', '.7z']:
                archive_content = self._quick_archive_peek(fp)
                archives_info[fp] = archive_content
        
        # STEP 2: Build compact file list
        root_path = source_path if source_path else None
        if root_path:
            root_path = str(Path(root_path).resolve())
        
        files_by_folder = {}
        for fp in file_paths:
            if root_path:
                try:
                    rel_path = Path(fp).relative_to(root_path)
                    folder = str(rel_path.parent) if str(rel_path.parent) != '.' else '.'
                    filename = rel_path.name
                except ValueError:
                    folder = '.'
                    filename = fp
            else:
                folder = '.'
                filename = fp
            
            if folder not in files_by_folder:
                files_by_folder[folder] = []
            
            file_info = {'file': filename}
            
            try:
                if os.path.exists(fp):
                    size_bytes = os.path.getsize(fp)
                    size_mb = round(size_bytes / (1024 * 1024), 1)
                    file_info['size'] = size_mb
            except Exception:
                pass
            
            meta = {}
            if fp in archives_info:
                meta['archive'] = archives_info[fp]
            
            if files_metadata and fp in files_metadata:
                metadata = files_metadata[fp]
                if metadata:
                    if 'size' in metadata:
                        size_mb = round(metadata['size'] / (1024 * 1024), 1)
                        file_info['size'] = size_mb
                    if 'image' in metadata and metadata['image']:
                        meta['img'] = {k: v for k, v in metadata['image'].items() if v is not None and k != 'format'}
                    elif 'video' in metadata and metadata['video']:
                        meta['vid'] = {k: v for k, v in metadata['video'].items() if v is not None and k != 'format'}
                    elif 'audio' in metadata and metadata['audio']:
                        meta['aud'] = {k: v for k, v in metadata['audio'].items() if v is not None and k != 'format'}
                    elif 'document' in metadata and metadata['document']:
                        meta['doc'] = {k: v for k, v in metadata['document'].items() if v is not None}
                    elif 'source_code' in metadata and metadata['source_code']:
                        meta['code'] = {k: v for k, v in metadata['source_code'].items() if v is not None}
            
            if meta:
                file_info['meta'] = meta
            
            files_by_folder[folder].append(file_info)
        
        # Build indexed lists
        source_folders = []
        dest_folders = []
        file_list_for_ai = []
        
        for folder in sorted(files_by_folder.keys()):
            full_folder = str(Path(root_path) / folder) if root_path and folder != '.' else (root_path if folder == '.' else folder)
            if full_folder not in source_folders:
                source_folders.append(full_folder)
        
        if ai_context:
            import re
            dest_pattern = r'(/[^\s]+)\s+\(drive:'
            for match in re.finditer(dest_pattern, ai_context):
                dest_path = match.group(1)
                if dest_path not in dest_folders:
                    dest_folders.append(dest_path)
        
        for folder in sorted(files_by_folder.keys()):
            src_folder_idx = source_folders.index(str(Path(root_path) / folder) if root_path and folder != '.' else (root_path if folder == '.' else folder))
            for file_info in files_by_folder[folder]:
                file_entry = {
                    'file': file_info['file'],
                    'src': src_folder_idx,
                    'size': file_info.get('size')
                }
                if 'meta' in file_info:
                    file_entry['meta'] = file_info['meta']
                file_list_for_ai.append(file_entry)
        
        # Build context sections (same as analyze_files_batch)
        context_section = ""
        if ai_context:
            context_section = f"""
{ai_context}

CRITICAL: USE EXISTING DESTINATIONS FIRST!
- ALWAYS check if a file type matches an existing destination
- For images: Use ImagesSorted destination (dest index from DESTINATION FOLDERS list)
- For documents: Use main Destination folder (dest index from DESTINATION FOLDERS list)
- DO NOT create "Documents" subfolder if main destination exists
- DO NOT create "Images" subfolder if ImagesSorted destination exists
- Only create subfolders for specific organization (like "Projects/V2K")

CONCRETE EXAMPLES with current destinations:
- Image file → {{"type": 0, "dest": 1}} (use ImagesSorted directly)
- Document file → {{"type": 0, "dest": 0}} (use Destination directly, NO "Documents" subfolder)
- Project file → {{"type": 0, "dest": 0, "subfolder": "Projects/V2K"}} (subfolder OK for projects)
- Software file → {{"type": 0, "dest": 0, "subfolder": "Software"}} (subfolder OK for software)
"""
        
        has_archives = bool(archives_info)
        archive_handling_rules = ""
        if has_archives:
            archive_handling_rules = """

ARCHIVE HANDLING:
- Only unpack archives if it makes sense (e.g., projects, mixed content that should be organized separately)
- Keep archives packed if they're complete units (e.g., game installers, software packages, backup archives)
- If unpacking: detect garbage files (.DS_Store, Thumbs.db, *.tmp, *.cache) → action: "delete"
- If unpacking: clean filenames with garbage prefixes (LSJF8089_, IMG_20250115_, Copy_of_) → action: "rename"
- Projects in archives: Keep project files together, extract to single project folder

PROJECT CONTEXT AWARENESS:
- Check known destinations for project names
- Match files to projects by name patterns (e.g., "V2K_test_image.jpg" → V2K project)
- Suggest organizing related files near their projects
- Example: If "V2K" project exists at /Projects/V2K/, put "V2K_logo.png" in /Projects/V2K/assets/
- Don't mess up project structure - add to appropriate subfolder (assets/, docs/, etc.)

FILENAME CLEANING:
- LSJF8089MyDiary.pdf → MyDiary.pdf
- Copy_of_document.pdf → document.pdf
- document (1).pdf → document.pdf
- IMG_20250115_143022.jpg → keep (or use EXIF date if available)
"""
        
        metadata_context = ""
        has_metadata = any(
            'meta' in file_info
            for folder_files in files_by_folder.values()
            for file_info in folder_files
        )
        
        if has_metadata:
            metadata_context = """
METADATA KEYS:
- img: date_taken, camera_model, location (organize by event/trip)
- vid: duration, width, height (movies vs clips)
- aud: artist, album, genre (music organization)
- doc: title, author, created, page_count (ebooks vs documents)
- archive: files[], type, exe (project detection)
- code: language (organize by tech stack)

Use metadata when available, prefer over filename guessing.

EBOOK DETECTION:
- PDFs with title + author + page_count (>50 pages) → likely ebook
- Suggest destination: "eBooks" or "Books" (not generic "Documents")
- Rename to: "[Title] - [Author].pdf" (clean, readable format)
- Example: "46i6iryjdhfsgsd_sanet.st.pdf" with title="Open Circuits", author="Eric Schlaepfer & Windell H. Oskay" → rename to "Open Circuits - Eric Schlaepfer & Windell H. Oskay.pdf"
"""
        
        # Build granularity rules
        if granularity == 1:
            granularity_rules = """
ORGANIZATION LEVEL: BROAD (Level 1)
- Use ONLY broad categories: "Documents", "Images", "Videos", "Projects", "Software", "Music", "Archives"
- Group similar files together - don't create specific subfolders
- Projects go in "Projects" folder (e.g., "Projects/V2K")
- Keep it simple - user will add detail later if needed
"""
        elif granularity == 2:
            granularity_rules = """
ORGANIZATION LEVEL: BALANCED (Level 2)
- Use broad categories with some specificity when clear patterns emerge
- Examples: "Documents/Finance", "Images/Personal", "Projects/V2K", "Videos/Movies"
- Only add subfolder if there's a clear grouping (e.g., multiple invoices → Finance)
- Don't over-categorize - balance between broad and specific
"""
        else:
            granularity_rules = """
ORGANIZATION LEVEL: DETAILED (Level 3)
- Create specific subfolders for clear organization
- Examples: "Documents/Finance/Invoices", "Images/Personal/Family", "Projects/V2K/Assets"
- Group by type, date, project, or topic as appropriate
- Maximize organization for easy retrieval
"""
        
        granularity_rules += """
GENERAL RULES:
- NO underscores in folder names (use spaces or single words)
- Projects should always go under "Projects" parent folder
- Keep folder names clear and intuitive
"""
        
        # Build action type mapping
        action_types = ["move", "rename", "unpack", "delete"]
        
        total_files = sum(len(files) for files in files_by_folder.values())
        
        # Build the complete prompt
        prompt = f"""Analyze {total_files} files and suggest organization.

SOURCE FOLDERS:
{json.dumps(source_folders, indent=2)}

DESTINATION FOLDERS:
{json.dumps(dest_folders, indent=2)}

ACTION TYPES:
{json.dumps(action_types, indent=2)}

{context_section}

{metadata_context}

{granularity_rules}

{archive_handling_rules}

FILES:
{json.dumps(file_list_for_ai, indent=2)}

Return ONLY valid JSON using indices:
{{
  "results": [
    {{
      "file": 0,
      "actions": [
        {{"type": 0, "dest": 1}}
      ]
    }},
    {{
      "file": 5,
      "actions": [
        {{"type": 1, "new_name": "report.pdf"}},
        {{"type": 0, "dest": 1, "subfolder": "Documents"}}
      ]
    }},
    {{
      "file": 8,
      "actions": [
        {{"type": 2, "dest": 1, "subfolder": "Projects/MyProject"}},
        {{"type": 3}}
      ]
    }},
    {{
      "file": 10,
      "actions": [
        {{"type": 3}}
      ]
    }}
  ]
}}

RESPONSE FORMAT:
- file: index from FILES list (integer)
- actions: array of actions to perform IN ORDER
  - type: index from ACTION TYPES (0=move, 1=rename, 2=unpack, 3=delete)
  - dest: index from DESTINATION FOLDERS (for move/unpack)
  - subfolder: optional subfolder path under destination
  - new_name: new filename (for rename only)

COMMON PATTERNS:
- Simple move: [{{"type": 0, "dest": 1}}]
- Rename + move: [{{"type": 1, "new_name": "..."}}, {{"type": 0, "dest": 1}}]
- Unpack + delete: [{{"type": 2, "dest": 1}}, {{"type": 3}}]
- Just delete: [{{"type": 3}}]

NO "reason" field - reasons are generated separately on-demand
"""
        
        return {
            'prompt': prompt,
            'source_folders': source_folders,
            'dest_folders': dest_folders,
            'file_list_for_ai': file_list_for_ai,
            'files_by_folder': files_by_folder
        }
    
    def analyze_files_batch(self, file_paths: List[str], existing_folders: List[str] = None, ai_context: str = None, files_metadata: Dict[str, Dict] = None, source_path: str = None, granularity: int = 1) -> Dict[str, Any]:
        """
        Analyze multiple files in a single AI call (MUCH faster than individual calls).
        Returns only folder suggestions, no reasons (reasons generated on-demand).
        Includes intelligent archive handling and duplicate detection.
        
        Args:
            file_paths: List of file paths to analyze
            existing_folders: List of folder names that already exist in destination (for context-aware organization)
            ai_context: Optional context string with known destinations and drives from AIContextBuilder
            files_metadata: Optional dict mapping file paths to their metadata (size, dates, type-specific info)
            source_path: Optional source folder path (for relative path optimization)
            granularity: Organization granularity level (1=broad, 2=balanced, 3=detailed)
            
        Returns:
            {
                'success': True/False,
                'results': {
                    'file_path': {'suggested_folder': 'path', 'action': 'move/delete/unpack'},
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
            # Build prompt using shared method (DRY principle)
            prompt_data = self._build_prompt_for_batch(
                file_paths=file_paths,
                existing_folders=existing_folders,
                ai_context=ai_context,
                files_metadata=files_metadata,
                source_path=source_path,
                granularity=granularity
            )
            
            # Extract data from prompt builder
            prompt = prompt_data['prompt']
            source_folders = prompt_data['source_folders']
            dest_folders = prompt_data['dest_folders']
            file_list_for_ai = prompt_data['file_list_for_ai']
            files_by_folder = prompt_data['files_by_folder']
            
            total_files = len(file_paths)
            
            # Log to terminal (clean summary)
            CYAN = '\033[96m'
            RESET = '\033[0m'
            logger.info(f"{CYAN}🤖 Analyzing {total_files} files with AI{RESET}")
            
            # Log full prompt to AI log file
            ai_logger.info("=" * 80)
            ai_logger.info(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} - AI PROMPT")
            ai_logger.info("=" * 80)
            ai_logger.info(f"Files: {total_files}")
            ai_logger.info(f"Folders: {len(files_by_folder)}")
            ai_logger.info(f"Context: {len(ai_context) if ai_context else 0} chars")
            ai_logger.info(f"Prompt length: {len(prompt)} chars")
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
            indexed_results = result.get('results', [])
            
            # Action type mapping
            action_types = ["move", "rename", "unpack", "delete"]
            
            # Convert indexed format back to full path format
            results = {}
            for item in indexed_results:
                file_idx = item.get('file')
                actions = item.get('actions', [])
                
                if file_idx is None or file_idx >= len(file_list_for_ai):
                    logger.warning(f"Invalid file index: {file_idx}")
                    continue
                
                if not actions:
                    logger.warning(f"No actions specified for file index {file_idx}")
                    continue
                
                # Get file info from indexed list
                file_info = file_list_for_ai[file_idx]
                filename = file_info['file']
                source_idx = file_info['src']
                
                # Build full source path
                src_folder = source_folders[source_idx]
                file_path = str(Path(src_folder) / filename)
                
                # Process actions array
                processed_actions = []
                suggested_folder = None
                new_name = None
                
                for action in actions:
                    action_type_idx = action.get('type')
                    
                    # Validate action type index
                    if action_type_idx is None or action_type_idx >= len(action_types):
                        logger.warning(f"Invalid action type index: {action_type_idx}")
                        continue
                    
                    action_type = action_types[action_type_idx]
                    
                    if action_type == 'move':
                        # Extract destination from move action
                        dest_idx = action.get('dest')
                        if dest_idx is not None and dest_idx < len(dest_folders):
                            suggested_folder = dest_folders[dest_idx]
                            if 'subfolder' in action:
                                suggested_folder = str(Path(suggested_folder) / action['subfolder'])
                        elif 'subfolder' in action:
                            suggested_folder = action['subfolder']
                        
                        processed_actions.append({
                            'type': 'move',
                            'destination': suggested_folder
                        })
                    
                    elif action_type == 'rename':
                        new_name = action.get('new_name')
                        processed_actions.append({
                            'type': 'rename',
                            'new_name': new_name
                        })
                    
                    elif action_type == 'unpack':
                        # Extract destination from unpack action
                        dest_idx = action.get('dest')
                        unpack_dest = None
                        if dest_idx is not None and dest_idx < len(dest_folders):
                            unpack_dest = dest_folders[dest_idx]
                            if 'subfolder' in action:
                                unpack_dest = str(Path(unpack_dest) / action['subfolder'])
                        elif 'subfolder' in action:
                            unpack_dest = action['subfolder']
                        
                        processed_actions.append({
                            'type': 'unpack',
                            'destination': unpack_dest
                        })
                    
                    elif action_type == 'delete':
                        processed_actions.append({
                            'type': 'delete'
                        })
                
                # Build result object with actions array only
                file_result = {
                    'actions': processed_actions
                }
                
                results[file_path] = file_result
            
            # Log success to terminal
            logger.info(f"{GREEN}✅ AI analysis complete ({len(results)} results){RESET}")
            for file_path, file_result in results.items():
                actions = file_result.get('actions', [])
                action_summary = ', '.join([f"{a['type']}" for a in actions])
                logger.debug(f"  {Path(file_path).name}: actions=[{action_summary}]")
            
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
            
            # Include error details if available
            error_response = {'success': False, 'error': error_msg}
            if hasattr(e, 'error_details'):
                error_response['error_details'] = e.error_details
            
            return error_response
    
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
            
            prompt = (
                f'You are organizing the "{folder_name}" folder. Add ONE level of granularity.\n\n'
                'CRITICAL RULES:\n'
                '1. You can create subfolders, but ONLY ONE LEVEL deep\n'
                '2. NOT ALL items need to go into subfolders - only organize items where it makes sense\n'
                '3. Items that do not need subcategorization should stay in current folder (return null)\n\n'
                f'Current folder: {folder_name}\n'
                'Items to analyze:\n'
                f'{json.dumps(items, indent=2)}\n\n'
                'Examples of good decisions:\n'
                f'- If you see 10 contracts and 2 random notes: move contracts to "Contracts/" subfolder, leave notes in "{folder_name}/"\n'
                '- If you see 5 photos from 2024 and 3 from 2025: create "2024/" and "2025/" subfolders\n'
                f'- If you see 3 random unrelated files: leave them all in "{folder_name}/" (no subfolder needed)\n\n'
                'Return ONLY valid JSON (no markdown):\n'
                '{\n'
                '  "suggestions": {\n'
                '    "full_item_path": {\n'
                '      "subfolder": "SubfolderName"  // or null if item should stay in current folder\n'
                '    },\n'
                '    ...\n'
                '  }\n'
                '}\n\n'
                'Be smart and practical. Only create subfolders when there is a clear benefit.'
            )

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
        Use AI to intelligently categorize and extract metadata from files.
        Supports dynamic categories: movies, tv_shows, music, ebooks, tutorials,
        projects, assets, documents, etc.
        
        Returns dict with success field. If success=False, includes error field.
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
            archive_path: Path to archive file (ZIP, RAR, 7-Zip)
            
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
        """Analyze 7-Zip archive"""
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
        
        source_exts = ['.cs', '.py', '.java', '.js', '.ts', '.cpp', '.c', '.dart', '.go', '.rb']
        project_exts = ['.csproj', '.sln', '.json', '.yaml', '.yml', '.xml', '.config']
        image_exts = ['.jpg', '.jpeg', '.png', '.gif', '.bmp']
        doc_exts = ['.pdf', '.doc', '.docx', '.txt']
        exe_exts = ['.exe', '.dll', '.so', '.dylib']
        
        if ext in source_exts:
            return 'SourceCode'
        elif ext in project_exts:
            return 'ProjectFile'
        elif ext in image_exts:
            return 'Image'
        elif ext in doc_exts:
            return 'Document'
        elif ext in exe_exts:
            return 'Executable'
        else:
            return 'Other'

