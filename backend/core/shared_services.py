#!/usr/bin/env python3
"""
Shared Services - Common utilities and shared resources
Provides AI API key management and other shared functionality
"""

import logging
import os
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, Any
from dotenv import load_dotenv
import google.generativeai as genai

logger = logging.getLogger('SharedServices')


class AIResponse:
    """Unified response wrapper for different AI providers"""
    def __init__(self, text: str):
        self.text = text


class AIModelWrapper:
    """Wrapper to provide uniform interface for different AI providers"""
    def __init__(self, provider: str, model, model_name: str):
        self.provider = provider
        self.model = model
        self.model_name = model_name
    
    def generate_content(self, prompt: str) -> AIResponse:
        """Generate content using the configured AI provider"""
        if self.provider == 'kimi':
            # Kimi uses OpenAI-compatible API
            response = self.model.chat.completions.create(
                model=self.model_name,
                messages=[{"role": "user", "content": prompt}],
                temperature=0.7
            )
            return AIResponse(response.choices[0].message.content)
        else:
            # Gemini
            response = self.model.generate_content(prompt)
            return AIResponse(response.text)


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
        self._current_model_name: Optional[str] = None
        self._model_discovery_attempted: bool = False
        self._config_file: Optional[Path] = None
        
        # Load environment variables
        self._load_environment()
        
        # Setup persistent config
        self._setup_config_file()
        
        # Initialize AI service (lightweight at startup)
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
            
            # Get AI provider and API key
            self._ai_provider = os.getenv('AI_PROVIDER', 'gemini').lower()  # 'gemini' or 'kimi'
            
            if self._ai_provider == 'kimi':
                self._ai_api_key = os.getenv('KIMI_API_KEY')
                if not self._ai_api_key:
                    logger.warning("⚠️ KIMI_API_KEY not found in environment")
                else:
                    masked_key = f"{self._ai_api_key[:8]}...{self._ai_api_key[-4:]}"
                    logger.info(f"🔑 Kimi AI API key loaded: {masked_key}")
            else:  # default to gemini
                self._ai_api_key = os.getenv('GEMINI_API_KEY')
                if not self._ai_api_key:
                    logger.warning("⚠️ GEMINI_API_KEY not found in environment")
                else:
                    masked_key = f"{self._ai_api_key[:8]}...{self._ai_api_key[-4:]}"
                    logger.info(f"🔑 Gemini AI API key loaded: {masked_key}")
            
        except Exception as e:
            logger.error(f"❌ Error loading environment: {e}")
            raise
    
    def _setup_config_file(self):
        """Setup persistent configuration file for runtime state"""
        try:
            # Use backend/data directory for persistent config
            data_dir = os.getenv("HOMIE_DATA_DIR", str(Path(__file__).resolve().parents[1] / "data"))
            config_dir = Path(data_dir) / "config"
            config_dir.mkdir(parents=True, exist_ok=True)
            self._config_file = config_dir / "ai_service.json"
            logger.info(f"📋 AI config file: {self._config_file}")
        except Exception as e:
            logger.warning(f"⚠️ Could not setup config file: {e}")
            self._config_file = None
    
    def _load_last_working_model(self) -> Optional[str]:
        """Load the last working model name from persistent config"""
        if not self._config_file or not self._config_file.exists():
            return None
        
        try:
            import json
            with open(self._config_file, 'r') as f:
                config = json.load(f)
                model_name = config.get('last_working_model')
                if model_name:
                    logger.info(f"📖 Loaded last working model: {model_name}")
                return model_name
        except Exception as e:
            logger.warning(f"⚠️ Could not load model config: {e}")
            return None
    
    def _save_working_model(self, model_name: str):
        """Save the working model name to persistent config"""
        if not self._config_file:
            return
        
        try:
            import json
            config = {
                'last_working_model': model_name,
                'last_updated': datetime.now().isoformat()
            }
            with open(self._config_file, 'w') as f:
                json.dump(config, f, indent=2)
            logger.info(f"💾 Saved working model: {model_name}")
        except Exception as e:
            logger.warning(f"⚠️ Could not save model config: {e}")
    
    def _initialize_ai(self):
        """Initialize AI service (Gemini or Kimi K2)"""
        try:
            if not self._ai_api_key:
                logger.warning("⚠️ No AI API key available, AI features will be disabled")
                return
            
            if self._ai_provider == 'kimi':
                self._initialize_kimi()
            else:
                self._initialize_gemini()
            
        except Exception as e:
            logger.error(f"❌ Error initializing AI service: {e}")
            self._ai_model = None
    
    def _initialize_gemini(self):
        """Initialize Google Gemini AI service"""
        # Configure Gemini
        genai.configure(api_key=self._ai_api_key)
        
        # Priority 1: User-specified model (highest priority)
        user_model = os.getenv('GEMINI_MODEL')
        if user_model:
            logger.info(f"🎯 Using user-specified Gemini model: {user_model}")
            model = genai.GenerativeModel(user_model)
            self._ai_model = AIModelWrapper('gemini', model, user_model)
            self._current_model_name = user_model
            logger.info(f"🤖 Gemini AI service configured with {user_model}")
            return
        
        # Priority 2: Last working model from persistent config
        last_model = self._load_last_working_model()
        if last_model:
            try:
                model = genai.GenerativeModel(last_model)
                self._ai_model = AIModelWrapper('gemini', model, last_model)
                self._current_model_name = last_model
                logger.info(f"🤖 Gemini AI service configured with last working model: {last_model}")
                return
            except Exception as e:
                logger.warning(f"⚠️ Last working model '{last_model}' failed: {e}")
        
        # Priority 3: Known good default (fallback)
        try:
            model = genai.GenerativeModel('gemini-flash-latest')
            self._ai_model = AIModelWrapper('gemini', model, 'gemini-flash-latest')
            self._current_model_name = 'gemini-flash-latest'
            logger.info("🤖 Gemini AI service configured with default: gemini-flash-latest")
        except Exception as e:
            logger.warning(f"⚠️ Default model setup failed: {e}")
            self._ai_model = None
    
    def _initialize_kimi(self):
        """Initialize Kimi K2 AI service (OpenAI-compatible API)"""
        try:
            from openai import OpenAI
            
            # Kimi uses OpenAI-compatible API
            base_url = os.getenv('KIMI_BASE_URL', 'https://api.moonshot.ai/v1')
            model_name = os.getenv('KIMI_MODEL', 'kimi-k2-0905-preview')
            
            client = OpenAI(
                api_key=self._ai_api_key,
                base_url=base_url
            )
            self._ai_model = AIModelWrapper('kimi', client, model_name)
            self._current_model_name = model_name
            logger.info(f"🤖 Kimi AI service configured with {model_name}")
            
        except ImportError:
            logger.error("❌ openai package not installed. Run: pip install openai")
            self._ai_model = None
        except Exception as e:
            logger.error(f"❌ Error initializing Kimi AI: {e}")
            self._ai_model = None
    
    def _discover_and_select_model(self):
        """Discover available models and select the best one (called on-demand)"""
        if self._model_discovery_attempted:
            return  # Don't retry discovery multiple times
        
        self._model_discovery_attempted = True
        logger.info("🔍 Discovering available Gemini models...")
        
        try:
            available_models = [
                m for m in genai.list_models() 
                if 'generateContent' in m.supported_generation_methods
            ]
            
            if not available_models:
                logger.error("❌ No models with generateContent support found")
                return
            
            logger.info(f"📋 Found {len(available_models)} compatible models")
            
            # Score and rank models by preference keywords
            def score_model(model_name: str) -> int:
                """Score models based on preference (higher = better)"""
                name_lower = model_name.lower()
                score = 0
                
                # Prefer 'flash' models (faster, cheaper)
                if 'flash' in name_lower:
                    score += 100
                
                # Prefer 'latest' aliases
                if 'latest' in name_lower:
                    score += 50
                
                # Prefer higher version numbers (2.5 > 2.0 > 1.5)
                if '2.5' in name_lower or '2-5' in name_lower:
                    score += 30
                elif '2.0' in name_lower or '2-0' in name_lower:
                    score += 20
                elif '1.5' in name_lower or '1-5' in name_lower:
                    score += 10
                
                # Avoid experimental/preview models
                if 'exp' in name_lower or 'preview' in name_lower:
                    score -= 20
                
                return score
            
            # Sort models by score (best first)
            ranked_models = sorted(
                available_models,
                key=lambda m: score_model(m.name),
                reverse=True
            )
            
            # Try models in ranked order
            for model in ranked_models[:5]:  # Try top 5 models
                model_name = model.name
                try:
                    logger.info(f"🔍 Trying model: {model_name}")
                    test_model = genai.GenerativeModel(model_name)
                    # Quick validation test
                    test_response = test_model.generate_content("Hi")
                    if test_response and test_response.text:
                        self._ai_model = test_model
                        self._current_model_name = model_name
                        self._save_working_model(model_name)  # Persist the working model
                        logger.info(f"✅ AI service recovered with {model_name}")
                        return
                except Exception as e:
                    logger.warning(f"⚠️ Model {model_name} failed: {str(e)[:100]}")
                    continue
            
            # If all failed, log available models for debugging
            logger.error("❌ All models failed. Available models:")
            for m in ranked_models[:10]:
                logger.error(f"   - {m.name}")
            
        except Exception as e:
            logger.error(f"❌ Model discovery failed: {e}")
    
    def get_working_ai_model(self):
        """Get a working AI model, with automatic recovery if needed"""
        # If we already have a model, return it
        if self._ai_model:
            return self._ai_model
        
        # If no model and haven't tried discovery yet, do it now
        if not self._model_discovery_attempted:
            self._discover_and_select_model()
        
        return self._ai_model
    
    @property
    def ai_api_key(self) -> Optional[str]:
        """Get AI API key"""
        return self._ai_api_key
    
    @property
    def ai_model(self):
        """Get configured AI model with automatic recovery"""
        return self.get_working_ai_model()
    
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
                'details': f'{self._ai_provider.upper()}_API_KEY not configured'
            }
        
        try:
            # Simple test prompt
            response = self._ai_model.generate_content("Say 'AI test successful'")
            
            return {
                'success': True,
                'message': 'AI connection test successful',
                'response': response.text.strip(),
                'provider': self._ai_provider,
                'model': self._current_model_name
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