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
    Supports: Movies, TV Shows, Documents, Photos, Archives, and more.
    """
    
    def __init__(self):
        self.movie_patterns = [
            # Pattern: Title.Year.Quality.Format
            r'(.+?)[\.\s](\d{4})[\.\s]',
            # Pattern: Title (Year)
            r'(.+?)\s*\((\d{4})\)',
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
    
    def analyze_file(self, file_path: str) -> Dict[str, Any]:
        """
        Analyze a single file and return rich metadata.
        
        Args:
            file_path: Path to the file to analyze
            
        Returns:
            Dictionary with content metadata
        """
        try:
            if not os.path.exists(file_path):
                return {
                    'success': False,
                    'error': f'File not found: {file_path}'
                }
            
            file_ext = Path(file_path).suffix.lower()
            file_name = Path(file_path).name
            
            # Determine file category and analyze accordingly
            if file_ext in ['.mkv', '.mp4', '.avi', '.mov', '.wmv']:
                return self._analyze_video(file_name, file_path)
            elif file_ext in ['.pdf']:
                return self._analyze_pdf(file_path)
            elif file_ext in ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff']:
                return self._analyze_photo(file_path)
            elif file_ext in ['.doc', '.docx', '.txt', '.rtf']:
                return self._analyze_document(file_path)
            else:
                return {
                    'success': True,
                    'content_type': 'Generic',
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
    
    def _analyze_video(self, file_name: str, file_path: str) -> Dict[str, Any]:
        """Analyze video files (movies and TV shows)"""
        # Try movie patterns first
        for pattern in self.movie_patterns:
            match = re.search(pattern, file_name, re.IGNORECASE)
            if match:
                title = match.group(1).replace('.', ' ').replace('_', ' ').strip()
                year = int(match.group(2))
                
                # Determine genre from filename keywords (basic approach)
                genre = self._detect_genre(file_name)
                
                return {
                    'success': True,
                    'content_type': 'Movie',
                    'title': title,
                    'year': year,
                    'genre': genre,
                    'description': f'{title} ({year})',
                    'keywords': self._extract_keywords(file_name),
                    'confidence_score': 0.90
                }
        
        # Try TV show patterns
        for pattern in self.tv_show_patterns:
            match = re.search(pattern, file_name, re.IGNORECASE)
            if match:
                show_name = match.group(1).replace('.', ' ').replace('_', ' ').strip()
                season = int(match.group(2))
                episode = int(match.group(3))
                
                return {
                    'success': True,
                    'content_type': 'TVShow',
                    'show_name': show_name,
                    'season': season,
                    'episode': episode,
                    'description': f'{show_name} - S{season:02d}E{episode:02d}',
                    'confidence_score': 0.92
                }
        
        # Generic video file
        return {
            'success': True,
            'content_type': 'Video',
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
                    'content_type': 'Document',
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
                    'content_type': 'Contract',
                    'document_category': 'Contract',
                    'confidence_score': 0.85
                }
            else:
                return {
                    'success': True,
                    'content_type': 'Document',
                    'document_category': 'General',
                    'confidence_score': 0.70
                }
                
        except Exception as e:
            logger.warning(f"Error analyzing PDF: {e}")
            return {
                'success': True,
                'content_type': 'Document',
                'confidence_score': 0.5
            }
    
    def _analyze_invoice(self, text: str, file_path: str) -> Dict[str, Any]:
        """Extract invoice-specific information"""
        result = {
            'success': True,
            'content_type': 'Invoice',
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
                'content_type': 'Photo',
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
                'content_type': 'Photo',
                'confidence_score': 0.8
            }
    
    def _analyze_document(self, file_path: str) -> Dict[str, Any]:
        """Analyze general documents"""
        return {
            'success': True,
            'content_type': 'Document',
            'document_category': 'General',
            'confidence_score': 0.75
        }
    
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

