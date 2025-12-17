#!/usr/bin/env python3
"""
User Settings Manager

Manages user-specific settings for file naming conventions and AI behavior.
Integrates with the AI analysis system to apply user preferences.
"""

import logging
import sqlite3
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, Optional

logger = logging.getLogger('UserSettingsManager')

class UserSettingsManager:
    """
    Manages user settings for file naming and organization preferences.
    """
    
    def __init__(self, db_path: str):
        """
        Initialize the UserSettingsManager.
        
        Args:
            db_path: Path to the SQLite database
        """
        self.db_path = db_path
        self._ensure_database_exists()
    
    def _ensure_database_exists(self):
        """Ensure the database and tables exist"""
        try:
            conn = sqlite3.connect(self.db_path)
            conn.close()
        except Exception as e:
            logger.error(f"Database connection failed: {e}")
            raise
    
    def get_file_naming_settings(self, user_id: str = "dev_user") -> Dict[str, Any]:
        """
        Get file naming settings for a user.
        
        Args:
            user_id: User identifier
            
        Returns:
            Dictionary with file naming settings (simplified format)
        """
        try:
            conn = sqlite3.connect(self.db_path)
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            
            cursor.execute("""
                SELECT * FROM user_file_naming_settings 
                WHERE user_id = ?
            """, (user_id,))
            
            row = cursor.fetchone()
            conn.close()
            
            if row:
                return {
                    'enableAIRenaming': True,  # Default to True since column doesn't exist yet
                    'documentNaming': row['document_naming'],
                    'imageNaming': row['image_naming'],
                    'mediaNaming': row['media_naming'],
                    'codeNaming': row['code_naming'],
                    'removeSpecialChars': True,  # Default values since columns don't exist yet
                    'removeSpaces': False,
                    'lowercaseExtensions': True,
                    'maxFilenameLength': 100,
                    # Custom template fields (use dict access since row is sqlite3.Row)
                    'documentCustomTemplate': row['document_custom_template'] if 'document_custom_template' in row.keys() else '',
                    'imageCustomTemplate': row['image_custom_template'] if 'image_custom_template' in row.keys() else '',
                    'mediaCustomTemplate': row['media_custom_template'] if 'media_custom_template' in row.keys() else '',
                    'codeCustomTemplate': row['code_custom_template'] if 'code_custom_template' in row.keys() else ''
                }
            else:
                # Return default settings
                return self._get_default_settings()
                
        except Exception as e:
            logger.error(f"Error getting file naming settings for user {user_id}: {e}")
            return self._get_default_settings()
    
    def save_file_naming_settings(self, user_id: str, settings: Dict[str, Any]) -> bool:
        """
        Save file naming settings for a user.
        
        Args:
            user_id: User identifier
            settings: Settings dictionary (simplified format)
            
        Returns:
            True if successful, False otherwise
        """
        try:
            # Validate settings
            if not self._validate_settings(settings):
                logger.error("Settings validation failed")
                return False
            
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Use INSERT OR REPLACE to handle both new and existing users
            cursor.execute("""
                INSERT OR REPLACE INTO user_file_naming_settings (
                    user_id, enable_ai_renaming, document_naming, image_naming,
                    media_naming, code_naming, remove_special_chars, remove_spaces,
                    lowercase_extensions, max_filename_length, 
                    document_custom_template, image_custom_template, 
                    media_custom_template, code_custom_template, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                user_id,
                settings.get('enableAIRenaming', True),
                settings.get('documentNaming', 'KeepOriginal'),
                settings.get('imageNaming', 'KeepOriginal'),
                settings.get('mediaNaming', 'KeepOriginal'),
                settings.get('codeNaming', 'KeepOriginal'),
                settings.get('removeSpecialChars', True),
                settings.get('removeSpaces', False),
                settings.get('lowercaseExtensions', True),
                settings.get('maxFilenameLength', 100),
                settings.get('documentCustomTemplate', ''),
                settings.get('imageCustomTemplate', ''),
                settings.get('mediaCustomTemplate', ''),
                settings.get('codeCustomTemplate', ''),
                datetime.now().isoformat()
            ))
            
            conn.commit()
            conn.close()
            
            logger.info(f"File naming settings saved for user {user_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error saving file naming settings for user {user_id}: {e}")
            return False
    
    def generate_file_naming_prompt(self, user_id: str = "dev_user") -> str:
        """
        Generate AI prompt based on user's file naming settings - SIMPLIFIED VERSION.
        
        Args:
            user_id: User identifier
            
        Returns:
            AI prompt string with naming instructions
        """
        settings = self.get_file_naming_settings(user_id)
        
        prompt = "When renaming files, follow these rules:\n\n"
        
        # Document files
        doc_rule = self._get_naming_description(
            settings.get('documentNaming', 'KeepOriginal'),
            settings.get('documentCustomTemplate', '')
        )
        prompt += f"📄 Document files (.pdf, .docx, .txt): {doc_rule}\n"
        
        # Image files
        img_rule = self._get_naming_description(
            settings.get('imageNaming', 'KeepOriginal'),
            settings.get('imageCustomTemplate', '')
        )
        prompt += f"🖼️ Image files (.jpg, .png, .gif): {img_rule}\n"
        
        # Media files
        media_rule = self._get_media_naming_description(
            settings.get('mediaNaming', 'KeepOriginal'),
            settings.get('mediaCustomTemplate', '')
        )
        prompt += f"🎵 Media files (.mp3, .mp4, .avi): {media_rule}\n"
        
        # Code files
        code_rule = self._get_naming_description(
            settings.get('codeNaming', 'KeepOriginal'),
            settings.get('codeCustomTemplate', '')
        )
        prompt += f"💻 Code files (.js, .py, .cs): {code_rule}\n\n"
        
        prompt += "Always preserve the original file extension and ensure the new name is descriptive and meaningful."
        
        return prompt
    
    def _get_default_settings(self) -> Dict[str, Any]:
        """Get default file naming settings"""
        return {
            'enableAIRenaming': True,
            'documentNaming': 'KeepOriginal',
            'imageNaming': 'KeepOriginal',
            'mediaNaming': 'KeepOriginal',
            'codeNaming': 'KeepOriginal',
            'removeSpecialChars': True,
            'removeSpaces': False,
            'lowercaseExtensions': True,
            'maxFilenameLength': 100,
            'documentCustomTemplate': '',
            'imageCustomTemplate': '',
            'mediaCustomTemplate': '',
            'codeCustomTemplate': ''
        }
    
    def _validate_settings(self, settings: Dict[str, Any]) -> bool:
        """Validate settings values"""
        try:
            # Valid naming conventions
            valid_conventions = {
                'KeepOriginal', 'CamelCase', 'PascalCase', 'SnakeCase', 
                'KebabCase', 'ContentBased', 'DateBased', 'FunctionBased', 'CUSTOM_TEMPLATE'
            }
            
            valid_media_conventions = {
                'KeepOriginal', 'ArtistDashTitle', 'TitleDashArtist',
                'ArtistUnderscoreTitle', 'TitleUnderscoreArtist', 'ContentBased', 'CUSTOM_TEMPLATE'
            }
            
            # Check naming conventions
            if settings.get('documentNaming') not in valid_conventions:
                return False
            if settings.get('imageNaming') not in valid_conventions:
                return False
            if settings.get('mediaNaming') not in valid_media_conventions:
                return False
            if settings.get('codeNaming') not in valid_conventions:
                return False
            
            # Check filename length
            max_length = settings.get('maxFilenameLength', 100)
            if not isinstance(max_length, int) or max_length < 20 or max_length > 255:
                return False
            
            return True
            
        except Exception as e:
            logger.error(f"Settings validation error: {e}")
            return False
    
    def _get_naming_description(self, convention: str, custom_template: str = "") -> str:
        """Convert naming convention enum to description"""
        if convention == "CUSTOM_TEMPLATE":
            return f"Use custom template: {custom_template}" if custom_template else "Use custom template (not configured)"
        
        descriptions = {
            "KeepOriginal": "Keep original name",
            "CamelCase": "Use camelCase (firstWordLowercase)",
            "PascalCase": "Use PascalCase (FirstWordUppercase)",
            "SnakeCase": "Use snake_case (words_separated_by_underscores)",
            "KebabCase": "Use kebab-case (words-separated-by-hyphens)",
            "ContentBased": "Create descriptive names based on file content",
            "DateBased": "Use date-based naming (YYYY-MM-DD format)",
            "FunctionBased": "Name based on primary function or purpose"
        }
        return descriptions.get(convention, "Keep original name")
    
    def _get_media_naming_description(self, convention: str, custom_template: str = "") -> str:
        """Convert media naming convention enum to description"""
        if convention == "CUSTOM_TEMPLATE":
            return f"Use custom template: {custom_template}" if custom_template else "Use custom template (not configured)"
        
        descriptions = {
            "KeepOriginal": "Keep original name",
            "ArtistDashTitle": "Format as 'Artist - Title'",
            "TitleDashArtist": "Format as 'Title - Artist'",
            "ArtistUnderscoreTitle": "Format as 'Artist_Title'",
            "TitleUnderscoreArtist": "Format as 'Title_Artist'",
            "ContentBased": "Create descriptive names based on content"
        }
        return descriptions.get(convention, "Keep original name")