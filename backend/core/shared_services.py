#!/usr/bin/env python3
"""
Shared Services - Common utilities and shared resources
Provides AI API key management and other shared functionality
"""

import logging
import os
from pathlib import Path
from typing import Optional, Dict, Any
from dotenv import load_dotenv
import google.generativeai as genai

logger = logging.getLogger('SharedServices')


class SharedServices:
    """
    Shared services and utilities used across all modules
    
    Responsibilities:
    - AI API key management and configuration
    - Common environment variables
    - Shared database connections (if needed)
    - Common utilities and helpers
    """
    
    def __init__(self):
        self._ai_api_key: Optional[str] = None
        self._ai_model = None
        self._config: Dict[str, Any] = {}
        
        # Load environment variables
        self._load_environment()
        
        # Initialize AI service
        self._initialize_ai()
        
        logger.info("🔧 Shared Services initialized")
    
    def _load_environment(self):
        """Load environment variables from .env file"""
        try:
            # Look for .env file in project root
            project_root = Path(__file__).parent.parent.parent
            env_file = project_root / '.env'
            
            if env_file.exists():
                load_dotenv(env_file)
                logger.info(f"📄 Loaded environment from: {env_file}")
            else:
                logger.warning("⚠️ No .env file found, using system environment variables")
            
            # Load common configuration
            self._config = {
                'debug': os.getenv('DEBUG', 'false').lower() == 'true',
                'host': os.getenv('HOST', '0.0.0.0'),
                'port': int(os.getenv('PORT', '8000')),
                'data_dir': os.getenv('DATA_DIR', 'backend/data'),
                'log_level': os.getenv('LOG_LEVEL', 'INFO'),
            }
            
            # Get AI API key
            self._ai_api_key = os.getenv('GEMINI_API_KEY')
            
            if not self._ai_api_key:
                logger.warning("⚠️ GEMINI_API_KEY not found in environment")
            else:
                # Mask the key for logging
                masked_key = f"{self._ai_api_key[:8]}...{self._ai_api_key[-4:]}"
                logger.info(f"🔑 AI API key loaded: {masked_key}")
            
        except Exception as e:
            logger.error(f"❌ Error loading environment: {e}")
            raise
    
    def _initialize_ai(self):
        """Initialize Google Gemini AI service"""
        try:
            if not self._ai_api_key:
                logger.warning("⚠️ No AI API key available, AI features will be disabled")
                return
            
            # Configure Gemini
            genai.configure(api_key=self._ai_api_key)
            
            # Initialize model
            self._ai_model = genai.GenerativeModel('gemini-1.5-flash')
            
            logger.info("🤖 AI service initialized (Gemini 1.5 Flash)")
            
        except Exception as e:
            logger.error(f"❌ Error initializing AI service: {e}")
            self._ai_model = None
    
    @property
    def ai_api_key(self) -> Optional[str]:
        """Get AI API key"""
        return self._ai_api_key
    
    @property
    def ai_model(self):
        """Get configured AI model"""
        return self._ai_model
    
    @property
    def config(self) -> Dict[str, Any]:
        """Get configuration dictionary"""
        return self._config.copy()
    
    def get_config(self, key: str, default: Any = None) -> Any:
        """Get specific configuration value"""
        return self._config.get(key, default)
    
    def is_ai_available(self) -> bool:
        """Check if AI service is available"""
        return self._ai_model is not None
    
    async def test_ai_connection(self) -> Dict[str, Any]:
        """Test AI service connection"""
        if not self.is_ai_available():
            return {
                'success': False,
                'error': 'AI service not initialized',
                'details': 'GEMINI_API_KEY not configured'
            }
        
        try:
            # Simple test prompt
            response = self._ai_model.generate_content("Say 'AI test successful'")
            
            return {
                'success': True,
                'message': 'AI connection test successful',
                'response': response.text.strip(),
                'model': 'gemini-1.5-flash'
            }
            
        except Exception as e:
            logger.error(f"❌ AI connection test failed: {e}")
            return {
                'success': False,
                'error': 'AI connection test failed',
                'details': str(e)
            }
    
    def get_data_dir(self) -> Path:
        """Get data directory path"""
        data_dir = Path(self._config['data_dir'])
        data_dir.mkdir(parents=True, exist_ok=True)
        return data_dir
    
    def get_module_data_dir(self, module_name: str) -> Path:
        """Get module-specific data directory"""
        module_dir = self.get_data_dir() / module_name
        module_dir.mkdir(parents=True, exist_ok=True)
        return module_dir
    
    def format_file_size(self, size_bytes: int) -> str:
        """Format file size in human-readable format"""
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if size_bytes < 1024.0:
                return f"{size_bytes:.1f} {unit}"
            size_bytes /= 1024.0
        return f"{size_bytes:.1f} PB"
    
    def sanitize_filename(self, filename: str) -> str:
        """Sanitize filename for cross-platform compatibility"""
        # Remove invalid characters
        invalid_chars = '<>:"/\\|?*'
        for char in invalid_chars:
            filename = filename.replace(char, '_')
        
        # Remove leading/trailing dots and spaces
        filename = filename.strip('. ')
        
        # Limit length
        if len(filename) > 255:
            name, ext = os.path.splitext(filename)
            max_name_len = 255 - len(ext)
            filename = name[:max_name_len] + ext
        
        return filename
    
    def extract_file_category(self, file_path: str) -> str:
        """Extract file category based on extension"""
        ext = Path(file_path).suffix.lower()
        
        categories = {
            # Documents
            '.pdf': 'Documents',
            '.doc': 'Documents', '.docx': 'Documents',
            '.txt': 'Documents', '.rtf': 'Documents',
            '.odt': 'Documents', '.pages': 'Documents',
            
            # Images
            '.jpg': 'Images', '.jpeg': 'Images', '.png': 'Images',
            '.gif': 'Images', '.bmp': 'Images', '.tiff': 'Images',
            '.webp': 'Images', '.svg': 'Images',
            
            # Videos
            '.mp4': 'Videos', '.mkv': 'Videos', '.avi': 'Videos',
            '.mov': 'Videos', '.wmv': 'Videos', '.flv': 'Videos',
            '.webm': 'Videos', '.m4v': 'Videos',
            
            # Audio
            '.mp3': 'Audio', '.wav': 'Audio', '.flac': 'Audio',
            '.aac': 'Audio', '.ogg': 'Audio', '.m4a': 'Audio',
            
            # Archives
            '.zip': 'Archives', '.rar': 'Archives', '.7z': 'Archives',
            '.tar': 'Archives', '.gz': 'Archives', '.bz2': 'Archives',
            
            # Software
            '.exe': 'Software', '.msi': 'Software', '.dmg': 'Software',
            '.deb': 'Software', '.rpm': 'Software', '.iso': 'Software',
        }
        
        return categories.get(ext, 'Other')
    
    def detect_series_info(self, filename: str) -> Optional[Dict[str, str]]:
        """Detect if filename is a TV series episode"""
        import re
        
        # Common series patterns
        patterns = [
            r'(.+)[.\s]+S(\d+)E(\d+)',  # Series.Name.S01E01
            r'(.+)[.\s]+Season[.\s]*(\d+)[.\s]*Episode[.\s]*(\d+)',  # Season 1 Episode 1
            r'(.+)[.\s]+(\d+)x(\d+)',  # Series.Name.1x01
        ]
        
        for pattern in patterns:
            match = re.search(pattern, filename, re.IGNORECASE)
            if match:
                series_name = match.group(1).replace('.', ' ').strip()
                season = match.group(2).zfill(2)
                episode = match.group(3).zfill(2)
                
                return {
                    'series_name': series_name,
                    'season': season,
                    'episode': episode,
                    'season_folder': f"Season {int(season)}"
                }
        
        return None
    
    async def shutdown(self):
        """Shutdown shared services"""
        logger.info("🛑 Shutting down Shared Services...")
        
        # Close AI model if needed
        self._ai_model = None
        
        logger.info("✅ Shared Services shut down")