#!/usr/bin/env python3
"""
Template Processing Engine

Processes custom naming templates with variables for file renaming.
Supports universal variables and file-type-specific variables.
"""

import re
import logging
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, Optional

logger = logging.getLogger('TemplateProcessor')

class TemplateProcessor:
    """
    Processes custom naming templates with variable substitution.
    """
    
    def __init__(self):
        """Initialize the template processor"""
        pass
    
    def process_template(self, template: str, file_info: Dict[str, Any]) -> str:
        """
        Process template variables and return final filename.
        
        Args:
            template: Template string like "{date:yyyy-MM-dd} - {folder} - {ai_description}"
            file_info: Dict with file metadata and AI analysis
            
        Returns:
            Processed filename string
        """
        if not template or not template.strip():
            return file_info.get('original_name_no_ext', 'unnamed')
        
        try:
            result = template.strip()
            
            # Process date variables first (they have complex patterns)
            result = self._process_date_variables(result, file_info)
            
            # Process EXIF date variables
            result = self._process_exif_date_variables(result, file_info)
            
            # Process simple variables
            result = self._process_simple_variables(result, file_info)
            
            # Clean up the result
            result = self._clean_filename(result)
            
            return result
            
        except Exception as e:
            logger.error(f"Template processing error: {e}")
            # Fallback to original name
            return file_info.get('original_name_no_ext', 'unnamed')
    
    def _process_date_variables(self, template: str, file_info: Dict[str, Any]) -> str:
        """Process {date:format} variables"""
        date_pattern = r'\{date:([^}]+)\}'
        
        for match in re.finditer(date_pattern, template):
            format_str = match.group(1)
            try:
                # Convert Python strftime format
                python_format = self._convert_date_format(format_str)
                formatted_date = datetime.now().strftime(python_format)
                template = template.replace(match.group(0), formatted_date)
            except Exception as e:
                logger.warning(f"Date formatting error for '{format_str}': {e}")
                # Fallback to ISO date
                template = template.replace(match.group(0), datetime.now().strftime('%Y-%m-%d'))
        
        return template
    
    def _process_exif_date_variables(self, template: str, file_info: Dict[str, Any]) -> str:
        """Process {exif_date:format} variables"""
        exif_date_pattern = r'\{exif_date:([^}]+)\}'
        
        for match in re.finditer(exif_date_pattern, template):
            format_str = match.group(1)
            
            # Get EXIF date from file_info
            exif_date_str = file_info.get('date_taken') or file_info.get('created_date')
            
            if exif_date_str:
                try:
                    # Parse EXIF date (usually in format: 2022:09:13 12:53:27)
                    if ':' in exif_date_str and len(exif_date_str) >= 10:
                        # Convert EXIF format to Python datetime
                        exif_date = datetime.strptime(exif_date_str[:19], '%Y:%m:%d %H:%M:%S')
                    else:
                        # Try ISO format
                        exif_date = datetime.fromisoformat(exif_date_str.replace('Z', '+00:00'))
                    
                    python_format = self._convert_date_format(format_str)
                    formatted_date = exif_date.strftime(python_format)
                    template = template.replace(match.group(0), formatted_date)
                except Exception as e:
                    logger.warning(f"EXIF date parsing error: {e}")
                    # Fallback to current date
                    python_format = self._convert_date_format(format_str)
                    formatted_date = datetime.now().strftime(python_format)
                    template = template.replace(match.group(0), formatted_date)
            else:
                # No EXIF date available, use current date
                python_format = self._convert_date_format(format_str)
                formatted_date = datetime.now().strftime(python_format)
                template = template.replace(match.group(0), formatted_date)
        
        return template
    
    def _process_simple_variables(self, template: str, file_info: Dict[str, Any]) -> str:
        """Process simple {variable} substitutions"""
        
        # Universal variables
        variables = {
            'folder': file_info.get('parent_folder', ''),
            'ai_description': file_info.get('ai_description', ''),
            'original_name': file_info.get('original_name_no_ext', ''),
            
            # Image variables
            'dimensions': file_info.get('dimensions', ''),
            'camera_model': file_info.get('camera_model', ''),
            'width': str(file_info.get('width', '')),
            'height': str(file_info.get('height', '')),
            
            # Media variables
            'artist': file_info.get('artist', ''),
            'title': file_info.get('title', ''),
            'album': file_info.get('album', ''),
            'year': str(file_info.get('year', '')),
            'genre': file_info.get('genre', ''),
            'duration': str(file_info.get('duration', '')),
            
            # Code variables
            'main_function': file_info.get('main_function', ''),
            'language': file_info.get('language', ''),
            'framework': file_info.get('framework', ''),
            
            # Document variables
            'author': file_info.get('author', ''),
            'page_count': str(file_info.get('page_count', '')),
        }
        
        # Replace variables
        for var_name, var_value in variables.items():
            if var_value:  # Only replace if value exists
                template = template.replace(f'{{{var_name}}}', str(var_value))
            else:
                # Remove empty variables
                template = template.replace(f'{{{var_name}}}', '')
        
        return template
    
    def _convert_date_format(self, format_str: str) -> str:
        """
        Convert frontend date format to Python strftime format.
        
        Frontend uses: yyyy-MM-dd HH:mm:ss
        Python uses: %Y-%m-%d %H:%M:%S
        """
        # Use regex to replace patterns precisely
        import re
        
        result = format_str
        
        # Year patterns
        result = re.sub(r'yyyy', '%Y', result)
        result = re.sub(r'yy', '%y', result)
        
        # Month patterns (process longest first)
        result = re.sub(r'MMMM', '%B', result)  # Full month name
        result = re.sub(r'MMM', '%b', result)   # Abbreviated month name  
        result = re.sub(r'MM', '%m', result)    # Month as number (01-12)
        
        # Day patterns
        result = re.sub(r'dd', '%d', result)    # Day with leading zero
        
        # Hour patterns (24-hour)
        result = re.sub(r'HH', '%H', result)    # Hour with leading zero
        
        # Minute patterns
        result = re.sub(r'mm', '%M', result)    # Minute with leading zero
        
        # Second patterns
        result = re.sub(r'ss', '%S', result)    # Second with leading zero
        
        return result
    
    def _clean_filename(self, filename: str) -> str:
        """
        Clean the processed filename by removing invalid characters and extra spaces.
        """
        if not filename:
            return 'unnamed'
        
        # Remove multiple spaces and dashes
        filename = re.sub(r'\s+', ' ', filename)
        filename = re.sub(r'-+', '-', filename)
        filename = re.sub(r'_+', '_', filename)
        
        # Remove leading/trailing spaces and separators
        filename = filename.strip(' -_')
        
        # Remove invalid filename characters (keep basic punctuation)
        filename = re.sub(r'[<>:"/\\|?*]', '', filename)
        
        # Ensure we have something
        if not filename or filename.isspace():
            return 'unnamed'
        
        return filename
    
    def get_available_variables(self, file_type: str) -> Dict[str, str]:
        """
        Get available variables for a specific file type.
        
        Args:
            file_type: 'document', 'image', 'media', or 'code'
            
        Returns:
            Dict mapping variable names to descriptions
        """
        universal_vars = {
            'date:format': 'Current date with custom format (e.g., {date:yyyy-MM-dd})',
            'folder': 'Parent folder name',
            'ai_description': 'AI-generated description',
            'original_name': 'Original filename without extension'
        }
        
        type_specific_vars = {
            'image': {
                'exif_date:format': 'Photo date from EXIF with custom format',
                'dimensions': 'Image dimensions (e.g., "1920x1080")',
                'camera_model': 'Camera model from EXIF',
                'width': 'Image width in pixels',
                'height': 'Image height in pixels'
            },
            'media': {
                'artist': 'Artist/performer name',
                'title': 'Song/video title',
                'album': 'Album name',
                'year': 'Release year',
                'genre': 'Genre/category',
                'duration': 'Duration in seconds'
            },
            'code': {
                'main_function': 'Primary function name',
                'language': 'Programming language',
                'framework': 'Framework/library used'
            },
            'document': {
                'author': 'Document author',
                'page_count': 'Number of pages'
            }
        }
        
        result = universal_vars.copy()
        if file_type in type_specific_vars:
            result.update(type_specific_vars[file_type])
        
        return result


# Convenience function for direct use
def process_template(template: str, file_info: Dict[str, Any]) -> str:
    """
    Process a template with file information.
    
    Args:
        template: Template string with variables
        file_info: File metadata and analysis results
        
    Returns:
        Processed filename
    """
    processor = TemplateProcessor()
    return processor.process_template(template, file_info)