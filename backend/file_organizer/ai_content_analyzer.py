#!/usr/bin/env python3
"""
AI Content Analyzer - Phase 5 Advanced AI Features
Provides rich metadata extraction for various file types
"""

import hashlib
import logging
import os
import re
import zipfile
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple

logger = logging.getLogger('AIContentAnalyzer')


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
            
            # Try AI-powered analysis first if available and enabled
            if use_ai and self.shared_services and self.shared_services.is_ai_available():
                ai_result = self._analyze_with_ai(file_path, file_name, file_ext, file_exists)
                if ai_result and ai_result.get('success'):
                    return ai_result
            
            # Determine file category and analyze accordingly
            if file_ext in ['.mkv', '.mp4', '.avi', '.mov', '.wmv']:
                # Video files can be analyzed from filename alone
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
    
    def _analyze_with_ai(self, file_path: str, file_name: str, file_ext: str, file_exists: bool) -> Optional[Dict[str, Any]]:
        """
        Use AI (Gemini) to intelligently categorize and extract metadata from files.
        Supports dynamic categories like: movies, tv_shows, music, ebooks, tutorials, 
        projects, assets (3d_models, brushes, plugins), documents, etc.
        """
        try:
            if not self.shared_services or not self.shared_services.ai_model:
                return None
            
            # Build context for AI
            parent_dir = Path(file_path).parent.name
            file_size_info = ""
            if file_exists:
                try:
                    size = os.path.getsize(file_path)
                    file_size_info = f", size: {size} bytes"
                except:
                    pass
            
            prompt = f"""Analyze this file and categorize it with rich metadata.

Filename: {file_name}
Extension: {file_ext}
Parent Directory: {parent_dir}
File Exists: {file_exists}{file_size_info}

Identify the content type and extract relevant metadata. Consider these categories:
- movie: Movies/films (extract: title, year, quality, release_group)
- tv_show: TV series episodes (extract: show_name, season, episode)
- music: Audio files (extract: artist, album, title, year)
- ebook: Books/PDFs (extract: title, author, format)
- tutorial: Educational content (extract: topic, instructor, platform)
- course: Online courses/training
- project: Programming projects (extract: project_type like dotnet/unity/flutter/rust, language)
- asset_3d: 3D models, meshes, textures
- asset_brush: Brushes for digital art
- asset_plugin: Software plugins/extensions
- asset_font: Font files
- document: General documents (extract: document_type like invoice/contract/receipt)
- image: Photos and images
- archive: Compressed files
- audio_sample: Sound effects, samples
- video_raw: Raw footage, screen recordings
- unknown: Cannot determine

Return ONLY valid JSON with this structure (no markdown, no extra text):
{{
  "success": true,
  "content_type": "category_name",
  "confidence_score": 0.0-1.0,
  "metadata": {{
    "key": "value pairs specific to the category"
  }},
  "description": "brief description",
  "suggested_folder": "suggested organization folder"
}}

Focus on accuracy. Use filename patterns, extensions, and context clues."""

            # Call Gemini
            response = self.shared_services.ai_model.generate_content(prompt)
            
            if not response or not response.text:
                return None
            
            # Parse AI response
            response_text = response.text.strip()
            
            # Remove markdown code blocks if present
            if response_text.startswith('```'):
                response_text = response_text.split('```')[1]
                if response_text.startswith('json'):
                    response_text = response_text[4:]
                response_text = response_text.strip()
            
            import json
            result = json.loads(response_text)
            
            # Flatten metadata into main result
            if 'metadata' in result:
                metadata = result.pop('metadata')
                result.update(metadata)
            
            logger.info(f"🤖 AI analysis for {file_name}: {result.get('content_type')} (confidence: {result.get('confidence_score')})")
            return result
            
        except Exception as e:
            logger.warning(f"AI analysis failed for {file_name}: {e}")
            return None
    
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
    
    def suggest_alternatives(self, file_path: str, current_analysis: Dict[str, Any], current_destination: str) -> Dict[str, Any]:
        """
        Suggest alternative destinations for a file using AI.
        """
        try:
            if not self.shared_services or not self.shared_services.is_ai_available():
                logger.warning("AI not available, using fallback for suggestions.")
                return self._suggest_alternatives_fallback(file_path, current_analysis, current_destination)

            file_name = Path(file_path).name
            
            prompt = f"""Given the file '{file_name}' and its analysis, suggest 3-5 diverse alternative organization destinations.
            The user disagreed with the current suggestion.

            Current Suggestion:
            - Destination: "{current_destination}"
            - Analysis: {json.dumps(current_analysis, indent=2)}

            Provide a variety of suggestions based on different organizational strategies:
            - By document/content type (e.g., 'Contracts', 'Invoices', 'Photos', 'Tutorials')
            - By project name or company (e.g., 'Project_X/Assets', 'Client_A/Invoices')
            - By date (e.g., '2023/2023-10_October')
            - By status or purpose (e.g., 'Archive/Old_Contracts', 'Action_Required/Invoices')

            For each alternative, provide a destination path, a brief reason, and a confidence score (0.0 to 1.0).
            The destination path should be based on the current destination's parent folder. For example if the current destination is '/home/user/Desktop/Dest/Documents/file.pdf', the base for suggestions should be '/home/user/Desktop/Dest/'.

            Return ONLY valid JSON in this structure (no markdown, no extra text):
            {{
              "success": true,
              "alternatives": [
                {{
                  "destination": "/path/to/Alternative_A/file.ext",
                  "reason": "Reason for this suggestion.",
                  "confidence": 0.9
                }},
                {{
                  "destination": "/path/to/Alternative_B/file.ext",
                  "reason": "Another reason.",
                  "confidence": 0.8
                }}
              ]
            }}
            """

            response = self.shared_services.ai_model.generate_content(prompt)
            if not response or not response.text:
                raise ValueError("AI returned empty response")

            response_text = response.text.strip()
            if response_text.startswith('```'):
                response_text = response_text.split('```')[1]
                if response_text.startswith('json'):
                    response_text = response_text[4:]
                response_text = response_text.strip()

            import json
            result = json.loads(response_text)
            
            logger.info(f"🤖 AI suggestions for {file_name} generated successfully.")
            return result

        except Exception as e:
            logger.error(f"Error generating AI suggestions for {file_path}: {e}", exc_info=True)
            return self._suggest_alternatives_fallback(file_path, current_analysis, current_destination)

    def _suggest_alternatives_fallback(self, file_path: str, current_analysis: Dict[str, Any], current_destination: str) -> Dict[str, Any]:
        """Fallback for generating suggestions without AI."""
        alternatives = []
        p = Path(file_path)
        dest_path = Path(current_destination)
        base_dest = dest_path.parent.parent # /.../Destination/Category -> /.../Destination/
        
        # 1. Suggestion based on content type
        content_type = current_analysis.get('content_type', 'General').capitalize()
        if content_type:
            alternatives.append({
                "destination": str(base_dest / content_type / p.name),
                "reason": f"Categorize by content type: {content_type}",
                "confidence": 0.75
            })

        # 2. Suggestion based on file extension
        ext_folder = p.suffix[1:].upper() + "_Files" if p.suffix else "Other_Files"
        alternatives.append({
            "destination": str(base_dest / ext_folder / p.name),
            "reason": f"Group by file type ({p.suffix})",
            "confidence": 0.65
        })

        # 3. Suggestion based on date
        try:
            mtime = p.stat().st_mtime
            date = datetime.fromtimestamp(mtime)
            year_folder = date.strftime('%Y')
            month_folder = date.strftime('%Y-%m')
            alternatives.append({
                "destination": str(base_dest / "Dated" / year_folder / month_folder / p.name),
                "reason": f"Organize by modification date ({month_folder})",
                "confidence": 0.60
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

