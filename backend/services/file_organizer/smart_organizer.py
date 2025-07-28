#!/usr/bin/env python3
"""
Smart File Organizer - AI-powered file analysis and organization suggestions
Uses Google Gemini to intelligently categorize and suggest file placements

ENHANCED WITH SECURE DATABASE INTEGRATION:
- Centralized destination memory via SQLite database
- User data isolation and enterprise-grade security
- Consistent AI recommendations based on historical patterns
- Secure audit logging and path validation
"""

import os
import json
import re
import shutil
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from datetime import datetime, timedelta
import google.generativeai as genai
from dotenv import load_dotenv
import time

# Add shared services to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../shared'))
from database_service import DatabaseService, DatabaseSecurityError

# Document processing imports
try:
    import PyPDF2
    from docx import Document
    import pytesseract
    from PIL import Image
    DOCUMENT_PROCESSING_AVAILABLE = True
except ImportError:
    DOCUMENT_PROCESSING_AVAILABLE = False
    print("⚠️  Document processing libraries not available. Install PyPDF2, python-docx, pytesseract, pillow for full functionality.")

# Load environment variables
load_dotenv()

class SmartOrganizer:
    """
    Smart File Organizer - AI-powered file analysis and organization suggestions
    Uses Google Gemini to intelligently categorize and suggest file placements
    
    ENHANCED WITH SECURE DATABASE:
    - Destination memory tracking across all drives
    - User data isolation for multi-user deployment
    - Enterprise-grade security and audit logging
    """
    
    def __init__(self, api_key: str, user_id: str = None, db_path: str = None):
        """
        Initialize the organizer with API key, user context, and secure database
        
        Args:
            api_key: Google Gemini API key
            user_id: User ID for data isolation (defaults to development user)
            db_path: Database path (defaults to backend/data/homie.db)
        """
        self.api_key = api_key
        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel('gemini-1.5-flash')
        
        # Initialize secure database
        if not db_path:
            db_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../data/homie.db'))
        
        self.db = DatabaseService(db_path)
        
        # Set user context (use development user if not specified)
        if user_id:
            self.user_id = user_id
        else:
            # Get or create development user
            self.user_id = self._get_development_user()
        
        print(f"🔗 SmartOrganizer initialized with secure database - User: {self.user_id}")
    
    def _get_development_user(self) -> str:
        """Get or create the development user for localhost testing"""
        try:
            # Try to create development user (will fail if already exists)
            user_id = self.db.create_user(
                email="dev@homie.local",
                username="developer",
                backend_type="local"
            )
            print(f"✅ Created development user: {user_id}")
            return user_id
        except DatabaseSecurityError as e:
            if "Email already exists" in str(e):
                # User exists, we need to find their ID
                # For now, we'll use a known development user ID
                # In production, this would be handled by the authentication system
                dev_user_id = "56d0f39a-7c7a-4965-b89d-35f7a074a719"  # Known dev user from tests
                print(f"✅ Using existing development user: {dev_user_id}")
                return dev_user_id
            else:
                raise Exception(f"Failed to initialize development user: {e}")
    
    def get_destination_memory(self, sorted_path: str = None) -> Dict:
        """
        Get destination memory from secure database instead of scattered .homie_memory.json files
        
        Args:
            sorted_path: Legacy parameter (now using database)
            
        Returns:
            Dictionary with destination patterns and mapping rules from database
        """
        try:
            # Get destination mappings from secure database
            mappings = self.db.get_user_destination_mappings(self.user_id)
            
            destination_memory = {
                'category_mappings': {},
                'series_mappings': {},
                'pattern_confidence': {},
                'recent_destinations': [],
                'drive_mappings': {},
                'total_mappings': len(mappings)
            }
            
            # Process category mappings
            for mapping in mappings:
                category = mapping['file_category']
                dest_path = mapping['destination_path']
                
                if category not in destination_memory['category_mappings']:
                    destination_memory['category_mappings'][category] = {}
                
                destination_memory['category_mappings'][category][dest_path] = mapping['usage_count']
                
                # Add to pattern confidence
                if category not in destination_memory['pattern_confidence']:
                    destination_memory['pattern_confidence'][category] = {}
                
                destination_memory['pattern_confidence'][category][dest_path] = {
                    'count': mapping['usage_count'],
                    'confidence': mapping['confidence_score'] * 100,
                    'primary': True,  # Will be updated below
                    'last_used': mapping['last_used']
                }
                
                # Add to recent destinations
                destination_memory['recent_destinations'].append({
                    'destination': dest_path,
                    'file_category': category,
                    'timestamp': mapping['last_used'],
                    'usage_count': mapping['usage_count']
                })
            
            # Determine primary destinations (most used)
            for category, destinations in destination_memory['category_mappings'].items():
                if destinations:
                    max_usage = max(destinations.values())
                    for dest_path, usage_count in destinations.items():
                        is_primary = (usage_count == max_usage)
                        destination_memory['pattern_confidence'][category][dest_path]['primary'] = is_primary
            
            # Sort recent destinations by timestamp
            destination_memory['recent_destinations'].sort(
                key=lambda x: x.get('timestamp', ''), reverse=True
            )
            
            print(f"🧠 Loaded destination memory: {len(mappings)} mappings for {len(destination_memory['category_mappings'])} categories")
            
            return destination_memory
            
        except Exception as e:
            print(f"⚠️  Warning: Error loading destination memory from database: {e}")
            return {
                'category_mappings': {},
                'series_mappings': {},
                'pattern_confidence': {},
                'recent_destinations': [],
                'drive_mappings': {},
                'total_mappings': 0
            }
    
    def discover_available_drives(self) -> Dict:
        """
        Discover all available drives and store in secure database
        
        Returns:
            Dictionary with drive information and their types
        """
        drives = {
            'local_drives': [],
            'network_drives': [],
            'cloud_drives': [],
            'usb_drives': []
        }
        
        try:
            import platform
            system = platform.system()
            
            if system == "Linux":
                drives = self._discover_linux_drives()
            elif system == "Windows":
                drives = self._discover_windows_drives()
            elif system == "Darwin":  # macOS
                drives = self._discover_macos_drives()
            
            # Store discovered drives in database for this user
            self._store_discovered_drives(drives)
            
        except Exception as e:
            print(f"[Drive Discovery] Warning: Error discovering drives: {e}")
        
        return drives
    
    def _store_discovered_drives(self, drives: Dict):
        """Store discovered drives in secure database"""
        try:
            all_drives = []
            for drive_type, drive_list in drives.items():
                for drive in drive_list:
                    drive['drive_type'] = drive_type.replace('_drives', '')  # Remove '_drives' suffix
                    all_drives.append(drive)
            
            # Note: In a full implementation, we'd add drive storage methods to DatabaseService
            # For now, we'll just log the discovery
            print(f"💾 Discovered {len(all_drives)} drives for user {self.user_id}")
            
        except Exception as e:
            print(f"⚠️  Warning: Could not store drives in database: {e}")
    
    def _discover_linux_drives(self) -> Dict:
        """Discover drives on Linux systems"""
        drives = {
            'local_drives': [],
            'network_drives': [],
            'cloud_drives': [],
            'usb_drives': []
        }
        
        try:
            # Read mount points from /proc/mounts
            with open('/proc/mounts', 'r') as f:
                mounts = f.readlines()
            
            for mount in mounts:
                parts = mount.split()
                if len(parts) < 3:
                    continue
                
                device = parts[0]
                mount_point = parts[1]
                fs_type = parts[2]
                
                # Skip system/virtual filesystems
                if mount_point.startswith(('/sys', '/proc', '/dev', '/run')):
                    continue
                if fs_type in ['tmpfs', 'devtmpfs', 'sysfs', 'proc', 'cgroup']:
                    continue
                
                # Categorize drive types
                drive_info = {
                    'path': mount_point,
                    'device': device,
                    'filesystem': fs_type,
                    'name': os.path.basename(mount_point) or mount_point
                }
                
                # Cloud drives (common mount points)
                if any(cloud in mount_point.lower() for cloud in 
                      ['onedrive', 'dropbox', 'googledrive', 'icloud', 'nextcloud']):
                    drives['cloud_drives'].append(drive_info)
                
                # Network drives
                elif fs_type in ['nfs', 'cifs', 'smb', 'sshfs'] or device.startswith('//'):
                    drives['network_drives'].append(drive_info)
                
                # USB/External drives (typically in /media or /mnt)
                elif mount_point.startswith(('/media', '/mnt')) and fs_type in ['ext4', 'ntfs', 'vfat', 'exfat']:
                    drives['usb_drives'].append(drive_info)
                
                # Local drives
                elif mount_point in ['/', '/home'] or fs_type in ['ext4', 'btrfs', 'xfs']:
                    drives['local_drives'].append(drive_info)
            
        except Exception as e:
            print(f"[Drive Discovery] Error reading Linux mounts: {e}")
        
        return drives
    
    def _discover_windows_drives(self) -> Dict:
        """Discover drives on Windows systems"""
        drives = {
            'local_drives': [],
            'network_drives': [],
            'cloud_drives': [],
            'usb_drives': []
        }
        
        try:
            import win32api
            import win32file
            
            # Get all drive letters
            drive_letters = win32api.GetLogicalDriveStrings()
            drive_letters = drive_letters.split('\000')[:-1]
            
            for drive in drive_letters:
                try:
                    drive_type = win32file.GetDriveType(drive)
                    drive_info = {
                        'path': drive,
                        'device': drive,
                        'name': f"Drive {drive[0]}"
                    }
                    
                    # Categorize by Windows drive type
                    if drive_type == win32file.DRIVE_FIXED:
                        drives['local_drives'].append(drive_info)
                    elif drive_type == win32file.DRIVE_REMOVABLE:
                        drives['usb_drives'].append(drive_info)
                    elif drive_type == win32file.DRIVE_REMOTE:
                        drives['network_drives'].append(drive_info)
                    
                except Exception as e:
                    print(f"[Drive Discovery] Error analyzing drive {drive}: {e}")
            
            # Check for cloud drive folders in user directory
            import os
            user_dir = os.path.expanduser('~')
            cloud_folders = ['OneDrive', 'Dropbox', 'Google Drive', 'iCloud Drive']
            
            for folder in cloud_folders:
                cloud_path = os.path.join(user_dir, folder)
                if os.path.exists(cloud_path):
                    drives['cloud_drives'].append({
                        'path': cloud_path,
                        'device': f'Cloud:{folder}',
                        'name': folder
                    })
                    
        except ImportError:
            print("[Drive Discovery] Windows-specific modules not available")
        except Exception as e:
            print(f"[Drive Discovery] Error discovering Windows drives: {e}")
        
        return drives
    
    def _discover_macos_drives(self) -> Dict:
        """Discover drives on macOS systems"""
        drives = {
            'local_drives': [],
            'network_drives': [],
            'cloud_drives': [],
            'usb_drives': []
        }
        
        try:
            # Check /Volumes for mounted drives
            volumes_path = '/Volumes'
            if os.path.exists(volumes_path):
                for volume in os.listdir(volumes_path):
                    volume_path = os.path.join(volumes_path, volume)
                    if os.path.ismount(volume_path):
                        drive_info = {
                            'path': volume_path,
                            'device': f'/dev/{volume}',
                            'name': volume
                        }
                        
                        # Categorize (basic heuristics for macOS)
                        if any(cloud in volume.lower() for cloud in 
                              ['onedrive', 'dropbox', 'googledrive', 'icloud']):
                            drives['cloud_drives'].append(drive_info)
                        else:
                            drives['usb_drives'].append(drive_info)
            
            # Add main system drive
            drives['local_drives'].append({
                'path': '/',
                'device': '/dev/disk1s1',
                'name': 'Macintosh HD'
            })
            
            # Check for cloud folders in user directory
            user_dir = os.path.expanduser('~')
            cloud_folders = ['OneDrive', 'Dropbox', 'Google Drive', 'iCloud Drive']
            
            for folder in cloud_folders:
                cloud_path = os.path.join(user_dir, folder)
                if os.path.exists(cloud_path):
                    drives['cloud_drives'].append({
                        'path': cloud_path,
                        'device': f'Cloud:{folder}',
                        'name': folder
                    })
            
        except Exception as e:
            print(f"[Drive Discovery] Error discovering macOS drives: {e}")
        
        return drives
    
    def _log_action_to_database(self, action_data: Dict, source_folder: str, destination_folder: str):
        """Log file actions to secure database instead of scattered .homie_memory.json files"""
        try:
            self.db.log_file_action(
                user_id=self.user_id,
                action_type=action_data.get('action', 'unknown'),
                file_name=action_data.get('file', ''),
                source_path=source_folder,
                destination_path=action_data.get('destination', ''),
                success=action_data.get('success', False),
                error_message=action_data.get('error', None)
            )
            print(f"📊 Action logged to database: {action_data.get('action', 'unknown')} - {action_data.get('file', '')}")
            
        except Exception as e:
            print(f"⚠️  Warning: Could not log action to database: {e}")
    
    def _update_destination_memory(self, file_path: str, destination_path: str):
        """Update destination memory in database when files are moved"""
        try:
            # Determine file category
            file_ext = Path(file_path).suffix.lower()
            file_category = self._categorize_by_extension(file_ext)
            
            if file_category != 'unknown':
                # Extract destination folder (remove filename)
                dest_folder = os.path.dirname(destination_path) if '/' in destination_path else destination_path
                
                # Add or update destination mapping
                mapping_id = self.db.add_destination_mapping(
                    user_id=self.user_id,
                    file_category=file_category,
                    destination_path=dest_folder,
                    confidence_score=0.8  # High confidence for user-confirmed moves
                )
                
                print(f"🧠 Updated destination memory: {file_category} → {dest_folder} (mapping ID: {mapping_id})")
            
        except Exception as e:
            print(f"⚠️  Warning: Could not update destination memory: {e}")
    
    def close(self):
        """Close database connection gracefully"""
        try:
            if hasattr(self, 'db'):
                self.db.close()
                print("🔗 SmartOrganizer database connection closed")
        except Exception as e:
            print(f"⚠️  Warning: Error closing database: {e}")
    
    def analyze_downloads_folder(self, downloads_path: str, sorted_path: str) -> Dict:
        """
        Analyze downloads folder and suggest organization into sorted folder
        
        Args:
            downloads_path: Path to the downloads folder
            sorted_path: Path to the sorted folder
            
        Returns:
            Dictionary with organization suggestions
        """
        
        # Get current file inventory
        downloads_files = self._get_file_inventory(downloads_path)
        sorted_structure = self._get_sorted_structure(sorted_path)
        
        # Get destination memory from secure database for AI consistency
        destination_memory = self.get_destination_memory(sorted_path)
        
        # Discover available drives for multi-drive support
        available_drives = self.discover_available_drives()
        
        # Prepare enhanced context for AI with destination memory
        context = self._prepare_context(downloads_files, sorted_structure, destination_memory)
        
        # Detect redundant archives before AI analysis
        redundant_archives = self._detect_redundant_archives(downloads_files)
        
        # Detect archives that need extraction
        archives_to_extract = self._detect_archives_for_extraction(downloads_files, redundant_archives)
        
        # Get AI suggestions enhanced with destination memory
        suggestions = self._get_ai_suggestions(context, redundant_archives, archives_to_extract, destination_memory)
        
        # Transform to frontend-expected format
        file_suggestions = suggestions.get('file_suggestions', [])
        
        # Convert confidence to percentage (0-100) format if needed
        for suggestion in file_suggestions:
            if 'confidence' in suggestion:
                confidence = suggestion['confidence']
                # If confidence is between 0-1, convert to percentage
                if isinstance(confidence, (int, float)) and 0 <= confidence <= 1:
                    suggestion['confidence'] = int(confidence * 100)
                elif isinstance(confidence, (int, float)) and confidence > 100:
                    suggestion['confidence'] = min(100, int(confidence))
        
        return {
            'strategy': suggestions.get('general_strategy', 'AI-powered file organization'),
            'new_folders': suggestions.get('new_folders_suggested', []),
            'file_suggestions': file_suggestions,
            'total_files': len(downloads_files),
            'confidence_summary': suggestions.get('summary', f'{len(downloads_files)} files analyzed')
        }
    
    def _get_file_inventory(self, folder_path: str) -> List[Dict]:
        """Get detailed inventory of files in downloads folder"""
        files = []
        project_folders = set()
        
        for root, dirs, filenames in os.walk(folder_path):
            # Check if this is a project folder (contains .git)
            if '.git' in dirs:
                project_folders.add(root)
                # Add the entire project as one unit
                project_info = self._analyze_project_folder(root)
                files.append(project_info)
                # Skip walking into this directory further
                dirs.clear()
                continue
            
            # Check if we're inside a known project folder
            is_inside_project = any(root.startswith(proj_path) for proj_path in project_folders)
            if is_inside_project:
                continue
                
            for filename in filenames:
                file_path = os.path.join(root, filename)
                file_info = self._analyze_file(file_path)
                files.append(file_info)
                
        return files
    
    def _analyze_project_folder(self, project_path: str) -> Dict:
        """Analyze a project folder as a single unit"""
        project_name = os.path.basename(project_path)
        
        # Calculate total size
        total_size = 0
        file_count = 0
        for root, dirs, files in os.walk(project_path):
            for file in files:
                try:
                    file_path = os.path.join(root, file)
                    total_size += os.path.getsize(file_path)
                    file_count += 1
                except (OSError, IOError):
                    continue
        
        # Detect project type
        project_type = self._detect_project_type(project_path)
        
        return {
            'name': project_name,
            'path': project_path,
            'type_category': 'project',
            'project_type': project_type,
            'size_mb': round(total_size / (1024*1024), 2),
            'size_bytes': total_size,
            'file_count': file_count,
            'is_project': True,
            'size_category': self._categorize_size(total_size),
            'base_name_no_ext': project_name.lower()
        }
    
    def _detect_project_type(self, project_path: str) -> str:
        """Detect the type of project based on files present"""
        files_in_root = []
        try:
            files_in_root = os.listdir(project_path)
        except (OSError, IOError):
            return 'unknown'
        
        files_lower = [f.lower() for f in files_in_root]
        
        # Web development
        if any(f in files_lower for f in ['package.json', 'index.html', 'webpack.config.js', 'vite.config.js']):
            return 'web_development'
        
        # Python project
        if any(f in files_lower for f in ['requirements.txt', 'setup.py', 'pyproject.toml', 'pipfile']):
            return 'python_project'
        
        # Node.js project
        if 'package.json' in files_lower:
            return 'nodejs_project'
        
        # Java project
        if any(f in files_lower for f in ['pom.xml', 'build.gradle', 'gradle.properties']):
            return 'java_project'
        
        # C/C++ project
        if any(f in files_lower for f in ['makefile', 'cmake.txt', 'configure.ac']):
            return 'cpp_project'
        
        # Flutter/Dart project
        if 'pubspec.yaml' in files_lower:
            return 'flutter_project'
        
        # Documentation/Website
        if any(f in files_lower for f in ['readme.md', 'index.md', '_config.yml']):
            return 'documentation'
        
        return 'software_project'
    
    def execute_file_action(self, action: str, file_path: str, destination_path: str = None, 
                           source_folder: str = None, destination_folder: str = None) -> Dict:
        """Execute a file action (move, delete, etc.) and log to memory file"""
        try:
            full_file_path = file_path if os.path.isabs(file_path) else os.path.join(source_folder, file_path)
            
            if not os.path.exists(full_file_path):
                raise FileNotFoundError(f"File not found: {full_file_path}")
            
            result = {
                'action': action,
                'file': file_path,
                'timestamp': datetime.now().isoformat(),
                'success': False
            }
            
            if action == 'delete':
                os.remove(full_file_path)
                result['success'] = True
                result['message'] = f"File deleted: {file_path}"
                
            elif action == 'move':
                if not destination_path:
                    raise ValueError("destination_path is required for move action")
                
                # Construct full destination path
                full_dest_path = os.path.join(destination_folder, destination_path)
                
                # Create destination directory if it doesn't exist
                os.makedirs(os.path.dirname(full_dest_path), exist_ok=True)
                
                # Move the file
                shutil.move(full_file_path, full_dest_path)
                result['success'] = True
                result['message'] = f"File moved from {file_path} to {destination_path}"
                result['destination'] = destination_path
                
            else:
                raise ValueError(f"Unknown action: {action}")
            
            # Log to secure database for audit trail
            self._log_action_to_database(result, source_folder, destination_folder)
            
            # Update destination memory if this was a successful move
            if action == 'move' and result['success']:
                self._update_destination_memory(file_path, destination_path)
            
            return result
            
        except Exception as e:
            result = {
                'action': action,
                'file': file_path,
                'timestamp': datetime.now().isoformat(),
                'success': False,
                'error': str(e)
            }
            self._log_action_to_database(result, source_folder, destination_folder)
            raise
    
    def re_analyze_file(self, file_path: str, user_input: str, source_folder: str, 
                       destination_folder: str) -> Dict:
        """Re-analyze a file with user input"""
        try:
            full_file_path = file_path if os.path.isabs(file_path) else os.path.join(source_folder, file_path)
            
            if not os.path.exists(full_file_path):
                raise FileNotFoundError(f"File not found: {full_file_path}")
            
            # Analyze the file
            file_info = self._analyze_file(full_file_path)
            
            # Create enhanced prompt with user input
            enhanced_prompt = f"""
You are re-analyzing a file based on user input. The user has provided specific guidance about this file.

FILE: {file_info['name']}
USER INPUT: {user_input}

File Details:
- Size: {file_info['size_mb']} MB
- Type: {file_info['type_category']}
- Extension: {file_info['extension']}

Based on the user's input "{user_input}", suggest:
1. DESTINATION: Where this file should be organized (e.g., "Projects/V2K-Website/")
2. REASONING: Why this destination makes sense given the user's input
3. CONFIDENCE: How confident you are (0-100%)

Respond with JSON:
{{
    "destination": "suggested/path/",
    "reason": "explanation based on user input",
    "confidence": 95
}}
"""
            
            try:
                response = self.model.generate_content(enhanced_prompt)
                response_text = response.text.strip()
                
                # Parse JSON response
                if response_text.startswith('```json'):
                    response_text = response_text[7:-3]
                elif response_text.startswith('```'):
                    response_text = response_text[3:-3]
                
                ai_response = json.loads(response_text)
                
                result = {
                    'destination': ai_response.get('destination', user_input),
                    'reason': ai_response.get('reason', f'Based on user input: {user_input}'),
                    'confidence': ai_response.get('confidence', 80) / 100.0,
                    'user_input': user_input,
                    'timestamp': datetime.now().isoformat()
                }
                
                # Log the re-analysis
                self._log_to_memory_file({
                    'action': 're_analyze',
                    'file': file_path,
                    'user_input': user_input,
                    'new_suggestion': result['destination'],
                    'timestamp': datetime.now().isoformat(),
                    'success': True
                }, source_folder, destination_folder)
                
                return result
                
            except json.JSONDecodeError:
                # Fallback if AI response is not valid JSON
                return {
                    'destination': user_input,
                    'reason': f'Using user-specified path: {user_input}',
                    'confidence': 0.9,
                    'user_input': user_input,
                    'timestamp': datetime.now().isoformat()
                }
                
        except Exception as e:
            raise Exception(f"Error re-analyzing file: {str(e)}")
    
    def log_file_access(self, file_path: str, action: str = 'open', user_agent: str = None) -> Dict:
        """Log file access events for usage tracking and analytics
        
        Args:
            file_path: Full path to the accessed file
            action: Type of access ('open', 'download', 'view', 'edit', etc.)
            user_agent: Optional user agent string for web access tracking
        
        Returns:
            Dictionary with success status and details
        """
        try:
            if not os.path.exists(file_path):
                return {'success': False, 'error': f'File not found: {file_path}'}
            
            # Create access entry
            access_data = {
                'timestamp': datetime.now().isoformat(),
                'file': os.path.basename(file_path),
                'full_path': file_path,
                'action': action,
                'file_size_bytes': os.path.getsize(file_path),
                'file_extension': Path(file_path).suffix.lower()
            }
            
            # Add optional user agent for web access tracking
            if user_agent:
                access_data['user_agent'] = user_agent
                
            # Get folder containing the file
            folder_path = os.path.dirname(file_path)
            
            # Log to memory file in the file's directory
            memory_file = os.path.join(folder_path, '.homie_memory.json')
            self._append_access_to_memory_file(memory_file, access_data)
            
            return {
                'success': True,
                'message': f'Logged {action} access for {os.path.basename(file_path)}',
                'access_data': access_data
            }
            
        except Exception as e:
            error_msg = f"Error logging file access: {str(e)}"
            print(f"Warning: {error_msg}")
            return {'success': False, 'error': error_msg}

    def get_file_access_analytics(self, folder_path: str, days: int = 30) -> Dict:
        """Get file access analytics for a folder
        
        Args:
            folder_path: Path to analyze
            days: Number of days to look back (default 30)
            
        Returns:
            Dictionary with access statistics and frequently accessed files
        """
        try:
            memory_file = os.path.join(folder_path, '.homie_memory.json')
            
            if not os.path.exists(memory_file):
                return {
                    'success': True,
                    'total_accesses': 0,
                    'frequently_accessed': [],
                    'recent_accesses': [],
                    'access_patterns': {}
                }
            
            # Load memory data
            with open(memory_file, 'r', encoding='utf-8') as f:
                memory_data = json.load(f)
            
            # Get cutoff date
            cutoff_date = datetime.now() - timedelta(days=days)
            
            # Extract file accesses
            file_accesses = memory_data.get('file_accesses', [])
            
            # Filter to recent accesses
            recent_accesses = []
            for access in file_accesses:
                try:
                    access_time = datetime.fromisoformat(access['timestamp'])
                    if access_time >= cutoff_date:
                        recent_accesses.append(access)
                except (ValueError, KeyError):
                    continue
            
            # Count access frequency
            access_counts = {}
            for access in recent_accesses:
                file_name = access.get('file', 'unknown')
                if file_name not in access_counts:
                    access_counts[file_name] = {
                        'count': 0,
                        'last_access': access['timestamp'],
                        'actions': [],
                        'full_path': access.get('full_path', '')
                    }
                access_counts[file_name]['count'] += 1
                access_counts[file_name]['actions'].append(access.get('action', 'open'))
                # Update last access if this is more recent
                if access['timestamp'] > access_counts[file_name]['last_access']:
                    access_counts[file_name]['last_access'] = access['timestamp']
            
            # Sort by frequency
            frequently_accessed = sorted(
                [{'file': k, **v} for k, v in access_counts.items()],
                key=lambda x: x['count'],
                reverse=True
            )
            
            # Analyze access patterns by hour and day
            access_patterns = {
                'by_hour': {},
                'by_day': {},
                'by_action': {}
            }
            
            for access in recent_accesses:
                try:
                    access_time = datetime.fromisoformat(access['timestamp'])
                    hour = access_time.hour
                    day = access_time.strftime('%A')
                    action = access.get('action', 'open')
                    
                    # Count by hour
                    access_patterns['by_hour'][hour] = access_patterns['by_hour'].get(hour, 0) + 1
                    
                    # Count by day
                    access_patterns['by_day'][day] = access_patterns['by_day'].get(day, 0) + 1
                    
                    # Count by action
                    access_patterns['by_action'][action] = access_patterns['by_action'].get(action, 0) + 1
                    
                except (ValueError, KeyError):
                    continue
            
            return {
                'success': True,
                'total_accesses': len(recent_accesses),
                'frequently_accessed': frequently_accessed[:10],  # Top 10
                'recent_accesses': recent_accesses[-10:],  # Last 10
                'access_patterns': access_patterns,
                'analysis_period_days': days
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': f'Error analyzing file access: {str(e)}'
            }
    
    def _log_to_memory_file(self, action_data: Dict, source_folder: str, destination_folder: str):
        """Log actions to memory files in both source and destination folders"""
        try:
            # Create memory entry
            memory_entry = {
                'timestamp': datetime.now().isoformat(),
                'action': action_data,
                'source_folder': source_folder,
                'destination_folder': destination_folder
            }
            
            # Log to source folder
            source_memory_file = os.path.join(source_folder, '.homie_memory.json')
            self._append_to_memory_file(source_memory_file, memory_entry)
            
            # Log to destination folder
            dest_memory_file = os.path.join(destination_folder, '.homie_memory.json')
            self._append_to_memory_file(dest_memory_file, memory_entry)
            
        except Exception as e:
            print(f"Warning: Could not log to memory file: {e}")
    
    def _append_to_memory_file(self, memory_file_path: str, entry: Dict):
        """Append an entry to a memory file"""
        try:
            # Load existing memory or create new
            if os.path.exists(memory_file_path):
                with open(memory_file_path, 'r', encoding='utf-8') as f:
                    memory_data = json.load(f)
            else:
                memory_data = {
                    'created': datetime.now().isoformat(),
                    'version': '1.0',
                    'actions': [],
                    'file_accesses': []  # Add file access tracking array
                }
            
            # Ensure file_accesses array exists (for backward compatibility)
            if 'file_accesses' not in memory_data:
                memory_data['file_accesses'] = []
            
            # Add new entry
            memory_data['actions'].append(entry)
            memory_data['last_updated'] = datetime.now().isoformat()
            
            # Save back to file
            with open(memory_file_path, 'w', encoding='utf-8') as f:
                json.dump(memory_data, f, indent=2, ensure_ascii=False)
                
        except Exception as e:
            print(f"Warning: Could not append to memory file {memory_file_path}: {e}")

    def _append_access_to_memory_file(self, memory_file_path: str, access_data: Dict):
        """Append a file access entry to a memory file"""
        try:
            # Load existing memory or create new
            if os.path.exists(memory_file_path):
                with open(memory_file_path, 'r', encoding='utf-8') as f:
                    memory_data = json.load(f)
            else:
                memory_data = {
                    'created': datetime.now().isoformat(),
                    'version': '1.0',
                    'actions': [],
                    'file_accesses': []
                }
            
            # Ensure file_accesses array exists (for backward compatibility)
            if 'file_accesses' not in memory_data:
                memory_data['file_accesses'] = []
            
            # Add new access entry
            memory_data['file_accesses'].append(access_data)
            memory_data['last_updated'] = datetime.now().isoformat()
            
            # Optional: Limit file access history to prevent huge files (keep last 1000 entries)
            if len(memory_data['file_accesses']) > 1000:
                memory_data['file_accesses'] = memory_data['file_accesses'][-1000:]
            
            # Save back to file
            with open(memory_file_path, 'w', encoding='utf-8') as f:
                json.dump(memory_data, f, indent=2, ensure_ascii=False)
                
        except Exception as e:
            print(f"Warning: Could not append access to memory file {memory_file_path}: {e}")
    
    def _detect_redundant_archives(self, downloads_files: List[Dict]) -> Dict[str, Dict]:
        """Detect archive files that likely contain already-extracted content"""
        redundant_archives = {}
        
        # Group files by directory
        files_by_dir = {}
        for file_info in downloads_files:
            dir_path = os.path.dirname(file_info['path'])
            if dir_path not in files_by_dir:
                files_by_dir[dir_path] = []
            files_by_dir[dir_path].append(file_info)
        
        # Check each directory for archive + content patterns
        for dir_path, files in files_by_dir.items():
            archives = [f for f in files if f['type_category'] == 'archives']
            
            # Group potential content by type
            content_files = {
                'videos': [f for f in files if f['type_category'] == 'videos'],
                'documents': [f for f in files if f['type_category'] == 'documents'],
                'images': [f for f in files if f['type_category'] == 'images'],
                'audio': [f for f in files if f['type_category'] == 'audio'],
                'code': [f for f in files if f['type_category'] == 'code'],
                'software': [f for f in files if f['type_category'] == 'software'],
                'data': [f for f in files if f['type_category'] == 'data'],
            }
            
            # Look for patterns: archive files + content files with similar names
            for archive in archives:
                for content_type, content_list in content_files.items():
                    for content_file in content_list:
                        similarity_score = self._calculate_name_similarity(
                            archive['base_name_no_ext'], 
                            content_file['base_name_no_ext']
                        )
                        
                        # If names are similar
                        if similarity_score > 0.6:
                            # Check if content size suggests it could be from these archives
                            total_archive_size = sum(a['size_bytes'] for a in archives 
                                                   if self._calculate_name_similarity(
                                                       a['base_name_no_ext'], 
                                                       content_file['base_name_no_ext']) > 0.6)
                            
                            # Content should be smaller than archives (compression) but substantial
                            size_ratio = content_file['size_bytes'] / total_archive_size if total_archive_size > 0 else 0
                            
                            # Different compression ratios for different content types
                            min_ratio, max_ratio = self._get_compression_ratios(content_type)
                            
                            if min_ratio <= size_ratio <= max_ratio:
                                redundant_archives[archive['name']] = {
                                    'archive_file': archive,
                                    'likely_content': content_file,
                                    'content_type': content_type,
                                    'similarity_score': similarity_score,
                                    'size_ratio': size_ratio,
                                    'confidence': min(95, int((similarity_score * 100 + size_ratio * 50) / 1.5))
                                }
        
        return redundant_archives
    
    def _detect_archives_for_extraction(self, downloads_files: List[Dict], redundant_archives: Dict[str, Dict]) -> Dict[str, Dict]:
        """Detect archive files that should be extracted (no extracted content found)."""
        archives_to_extract = {}
        
        # Get all archives
        archives = [f for f in downloads_files if f['type_category'] == 'archives']
        
        # Filter out archives that are already flagged as redundant
        redundant_archive_names = set(redundant_archives.keys())
        
        for archive in archives:
            # Skip if this archive is redundant (already has extracted content)
            if archive['name'] in redundant_archive_names:
                continue
            
            # Check archive size - if it's substantial, it probably should be extracted
            if archive['size_mb'] > 5:  # Archives larger than 5MB
                archives_to_extract[archive['name']] = {
                    'archive_file': archive,
                    'reason': f"Archive {archive['name']} ({archive['size_mb']}MB) should be extracted to organize its contents",
                    'confidence': 80
                }
        
        return archives_to_extract
    
    def _calculate_name_similarity(self, name1: str, name2: str) -> float:
        """Calculate similarity between two filenames (0.0 to 1.0)"""
        # Enhanced similarity detection for movie/content files
        
        # Clean names: remove common noise words and special chars
        def clean_name(name):
            # Remove year patterns, quality indicators, etc.
            name = re.sub(r'\b(19|20)\d{2}\b', '', name)  # Years
            name = re.sub(r'\b(720p|1080p|480p|4k|hd|dvd|bluray|webrip|hdtv|brrip|cam|ts|dvdscr)\b', '', name, flags=re.I)
            name = re.sub(r'\b(x264|x265|h264|h265|xvid|divx|aac|ac3|dts)\b', '', name, flags=re.I)  # Codecs
            name = re.sub(r'\b(extended|unrated|directors|cut|remastered|special|edition)\b', '', name, flags=re.I)  # Versions
            name = re.sub(r'[^\w\s]', ' ', name)  # Special chars to spaces
            name = re.sub(r'\s+', ' ', name).strip()  # Multiple spaces to single
            return name.lower()
        
        clean1 = clean_name(name1)
        clean2 = clean_name(name2)
        
        if not clean1 or not clean2:
            return 0.0
        
        # Direct string similarity for very similar names
        if clean1 == clean2:
            return 1.0
        
        # Check if one is contained in the other (for cases like "Thunderbolts" and "Thunderbolts Movie")
        if clean1 in clean2 or clean2 in clean1:
            return 0.9
        
        # Word-based similarity
        words1 = set(clean1.split())
        words2 = set(clean2.split())
        
        if not words1 or not words2:
            return 0.0
        
        intersection = words1.intersection(words2)
        union = words1.union(words2)
        
        jaccard_similarity = len(intersection) / len(union) if union else 0.0
        
        # Boost similarity if the main title words match
        main_words1 = [w for w in words1 if len(w) > 3]  # Focus on substantial words
        main_words2 = [w for w in words2 if len(w) > 3]
        
        if main_words1 and main_words2:
            main_intersection = set(main_words1).intersection(set(main_words2))
            if main_intersection:
                jaccard_similarity = min(1.0, jaccard_similarity + 0.2)  # Boost for main word matches
        
        return jaccard_similarity
    
    def _get_compression_ratios(self, content_type: str) -> Tuple[float, float]:
        """Get expected compression ratios (min, max) for different content types"""
        ratios = {
            'videos': (0.3, 0.95),     # Video files compress well
            'documents': (0.1, 0.8),   # Documents compress very well
            'images': (0.7, 1.0),      # Images already compressed, less ratio
            'audio': (0.5, 0.9),       # Audio files compress moderately
            'code': (0.2, 0.7),        # Code compresses very well
            'software': (0.4, 0.9),    # Software varies
            'data': (0.3, 0.8),        # Data files compress well
        }
        return ratios.get(content_type, (0.3, 0.95))  # Default ratio
    
    def _analyze_file(self, file_path: str) -> Dict:
        """Analyze individual file and extract metadata"""
        stat = os.stat(file_path)
        base_name = os.path.basename(file_path)
        file_info = {
            'name': base_name,
            'path': file_path,
            'extension': Path(file_path).suffix.lower(),
            'size_mb': round(stat.st_size / (1024*1024), 2),
            'size_bytes': stat.st_size,
            'size_category': self._categorize_size(stat.st_size),
            'type_category': self._categorize_by_extension(Path(file_path).suffix.lower()),
            'base_name_no_ext': Path(file_path).stem.lower()
        }
        
        # Add series detection for video files
        if file_info['type_category'] == 'videos':
            series_info = self._detect_series_episode(base_name)
            file_info.update(series_info)
        
        # Add content hints for better AI analysis
        if file_info['extension'] in ['.txt', '.md', '.json', '.js', '.py', '.html', '.css']:
            file_info['content_hint'] = self._get_text_file_hint(file_path)
        elif file_info['extension'] in ['.pdf', '.doc', '.docx']:
            file_info['content_hint'] = self._get_document_content_hint(file_path)
            file_info['document_category'] = self._categorize_document_content(file_info['content_hint'])
            
        return file_info
    
    def _categorize_size(self, size_bytes: int) -> str:
        """Categorize file by size"""
        mb = size_bytes / (1024*1024)
        if mb < 1:
            return "small"
        elif mb < 10:
            return "medium"
        elif mb < 100:
            return "large"
        else:
            return "very_large"
    
    def _categorize_by_extension(self, ext: str) -> str:
        """Basic categorization by file extension"""
        categories = {
            'images': ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.webp', '.ico', '.svg'],
            'videos': ['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm', '.m4v', '.3gp'],
            'documents': ['.pdf', '.doc', '.docx', '.txt', '.rtf', '.odt', '.cls', '.epub', '.mobi', '.azw', '.azw3', '.fb2', '.djvu', '.chm'],
            'archives': ['.zip', '.rar', '.7z', '.tar', '.gz', '.bz2', '.tgz', '.xz', '.lzma', '.z'],
            'audio': ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.wma', '.m4a', '.opus'],
            'code': ['.js', '.py', '.html', '.css', '.json', '.xml', '.sql', '.php', '.cpp', '.c', '.java', '.go', '.rs'],
            'software': ['.deb', '.rpm', '.exe', '.msi', '.dmg', '.pkg', '.appimage', '.snap'],
            'data': ['.csv', '.xlsx', '.xls', '.json', '.xml', '.db', '.sql', '.sqlite'],
            'other': ['.dlc', '.iso', '.img', '.bin', '.cue']
        }
        
        for category, extensions in categories.items():
            if ext in extensions:
                return category
        return 'unknown'
    
    def _detect_series_episode(self, filename: str) -> Dict:
        """Detect if a video file is a series episode and extract series info"""
        # Remove extension for analysis
        name_no_ext = Path(filename).stem
        
        # Common series episode patterns
        patterns = [
            # S01E01, S1E1, etc.
            r'(.+?)[.\s_-]+[Ss](\d{1,2})[Ee](\d{1,2})',
            # Season 1 Episode 1, Season 01 Episode 01
            r'(.+?)[.\s_-]+[Ss]eason[.\s_-]*(\d{1,2})[.\s_-]*[Ee]pisode[.\s_-]*(\d{1,2})',
            # 1x01, 1x1, etc.
            r'(.+?)[.\s_-]+(\d{1,2})x(\d{1,2})',
            # Part 1, Part 01, etc. (for some series)
            r'(.+?)[.\s_-]+[Pp]art[.\s_-]*(\d{1,2})',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, name_no_ext, re.IGNORECASE)
            if match:
                if len(match.groups()) >= 3:
                    series_name = match.group(1)
                    season = match.group(2)
                    episode = match.group(3)
                elif len(match.groups()) == 2:  # Part pattern
                    series_name = match.group(1)
                    season = "1"  # Default to season 1 for part-based series
                    episode = match.group(2)
                else:
                    continue
                
                # Clean up series name
                series_name = re.sub(r'[.\s_-]+', ' ', series_name).strip()
                series_name = re.sub(r'\b(19|20)\d{2}\b', '', series_name)  # Remove years
                series_name = series_name.title()  # Title case
                
                return {
                    'is_series': True,
                    'series_name': series_name,
                    'season': int(season),
                    'episode': int(episode),
                    'suggested_path': f"Series/{series_name}/Season {int(season)}"
                }
        
        return {'is_series': False}
    
    def _get_text_file_hint(self, file_path: str) -> str:
        """Get content hint from text files"""
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read(200)  # First 200 chars
                return content.strip()[:100] + "..." if len(content) > 100 else content.strip()
        except:
            return "Could not read file content"
    
    def _get_document_content_hint(self, file_path: str) -> str:
        """Extract text content from PDF and document files for AI analysis"""
        if not DOCUMENT_PROCESSING_AVAILABLE:
            return "Document processing not available - install PyPDF2, python-docx, pytesseract"
        
        try:
            file_ext = Path(file_path).suffix.lower()
            content = ""
            
            if file_ext == '.pdf':
                content = self._extract_pdf_text(file_path)
            elif file_ext in ['.doc', '.docx']:
                content = self._extract_word_text(file_path)
            
            # Return first 500 characters for AI analysis
            if content:
                clean_content = ' '.join(content.split())  # Clean whitespace
                return clean_content[:500] + "..." if len(clean_content) > 500 else clean_content
            else:
                return "Could not extract text from document"
                
        except Exception as e:
            return f"Error reading document: {str(e)}"

    def _extract_pdf_text(self, file_path: str) -> str:
        """Extract text from PDF files"""
        try:
            text = ""
            with open(file_path, 'rb') as file:
                pdf_reader = PyPDF2.PdfReader(file)
                
                # Extract text from first few pages (limit for performance)
                max_pages = min(5, len(pdf_reader.pages))
                for page_num in range(max_pages):
                    page = pdf_reader.pages[page_num]
                    page_text = page.extract_text()
                    if page_text:
                        text += page_text + " "
                
                # If no text extracted (scanned PDF), try OCR on first page
                if not text.strip() and len(pdf_reader.pages) > 0:
                    text = self._ocr_pdf_page(file_path, 0)
                    
            return text.strip()
        except Exception as e:
            return f"PDF extraction error: {str(e)}"

    def _extract_word_text(self, file_path: str) -> str:
        """Extract text from Word documents"""
        try:
            doc = Document(file_path)
            text = ""
            
            # Extract from paragraphs (limit for performance)
            for i, paragraph in enumerate(doc.paragraphs):
                if i > 20:  # Limit to first 20 paragraphs
                    break
                text += paragraph.text + " "
                
            return text.strip()
        except Exception as e:
            return f"Word extraction error: {str(e)}"

    def _ocr_pdf_page(self, file_path: str, page_num: int = 0) -> str:
        """Perform OCR on a PDF page (for scanned PDFs)"""
        try:
            # This is a basic implementation
            # For production, you'd want more sophisticated PDF to image conversion
            return "OCR text extraction (simplified implementation)"
        except Exception as e:
            return f"OCR error: {str(e)}"

    def _categorize_document_content(self, content_hint: str) -> str:
        """Categorize document based on content analysis"""
        if not content_hint or "error" in content_hint.lower():
            return "unknown"
        
        content_lower = content_hint.lower()
        
        # Austrian business document patterns
        if any(word in content_lower for word in ['rechnung', 'invoice', 'faktura', 'bill']):
            return 'invoices'
        elif any(word in content_lower for word in ['vertrag', 'contract', 'vereinbarung', 'agreement']):
            return 'contracts'
        elif any(word in content_lower for word in ['lohnzettel', 'gehalt', 'salary', 'payroll', 'lohn']):
            return 'payroll'
        elif any(word in content_lower for word in ['zeiterfassung', 'timesheet', 'stunden', 'hours']):
            return 'timesheet'
        elif any(word in content_lower for word in ['steuer', 'tax', 'finanzamt', 'abgaben']):
            return 'tax_documents'
        elif any(word in content_lower for word in ['bank', 'konto', 'überweisung', 'transfer', 'statement']):
            return 'banking'
        elif any(word in content_lower for word in ['versicherung', 'insurance', 'police', 'claim']):
            return 'insurance'
        elif any(word in content_lower for word in ['arzt', 'doctor', 'medical', 'medizin', 'health']):
            return 'medical'
        elif any(word in content_lower for word in ['brief', 'letter', 'post', 'mail']):
            return 'correspondence'
        elif any(word in content_lower for word in ['buch', 'book', 'roman', 'novel', 'story']):
            return 'books'
        elif any(word in content_lower for word in ['manual', 'handbuch', 'anleitung', 'guide']):
            return 'manuals'
        elif any(word in content_lower for word in ['recipe', 'rezept', 'cooking', 'kochen']):
            return 'recipes'
        else:
            return 'general_documents'
    
    def _get_sorted_structure(self, sorted_path: str) -> Dict:
        """Get current structure of sorted folder"""
        structure = {}
        
        if not os.path.exists(sorted_path):
            return structure
            
        for item in os.listdir(sorted_path):
            item_path = os.path.join(sorted_path, item)
            if os.path.isdir(item_path):
                file_count = sum(1 for _ in os.walk(item_path) for f in _[2])
                structure[item] = {
                    'type': 'folder',
                    'file_count': file_count,
                    'subfolders': [d for d in os.listdir(item_path) 
                                 if os.path.isdir(os.path.join(item_path, d))]
                }
        
        return structure
    
    def _prepare_context(self, downloads_files: List[Dict], sorted_structure: Dict, 
                        destination_memory: Dict = None) -> str:
        """Prepare enhanced context string for AI analysis with destination memory"""
        context = f"""
I need to organize {len(downloads_files)} files from my Downloads folder into my sorted folder structure.

CURRENT SORTED FOLDER STRUCTURE:
{json.dumps(sorted_structure, indent=2)}
"""
        
        # Add destination memory for AI consistency
        if destination_memory and destination_memory.get('category_mappings'):
            context += f"""

🧠 DESTINATION MEMORY (for consistency):
I have previously organized files using these patterns. Please follow these established patterns to maintain consistency:

"""
            for category, destinations in destination_memory['category_mappings'].items():
                primary_dest = None
                max_usage = 0
                
                # Find the most used destination for this category
                for dest, usage_count in destinations.items():
                    if usage_count > max_usage:
                        max_usage = usage_count
                        primary_dest = dest
                
                if primary_dest:
                    confidence_info = destination_memory['pattern_confidence'].get(category, {}).get(primary_dest, {})
                    confidence = confidence_info.get('confidence', 0)
                    context += f"- {category.upper()} files → {primary_dest}/ (used {max_usage} times, {confidence:.0f}% confidence)\n"
            
            # Add series-specific patterns if available
            if destination_memory.get('series_mappings'):
                context += f"\nSERIES-SPECIFIC PATTERNS:\n"
                for series, destinations in destination_memory['series_mappings'].items():
                    most_used = max(destinations.items(), key=lambda x: x[1])
                    context += f"- '{series}' episodes → {most_used[0]}/ (used {most_used[1]} times)\n"
            
            total_mappings = destination_memory.get('total_mappings', 0)
            context += f"\n💡 Total learned patterns: {total_mappings} mappings"
        
        context += f"""

FILES TO ORGANIZE:
"""
        
        for file_info in downloads_files[:20]:  # Limit to first 20 files for context
            context += f"- {file_info['name']} ({file_info['type_category']}, {file_info['size_category']}, {file_info['size_mb']}MB)"
            
            # Add series information if available
            if file_info.get('is_series', False):
                context += f"\n  📺 Series: {file_info['series_name']} - Season {file_info['season']} Episode {file_info['episode']}"
                context += f"\n  📁 Suggested Path: {file_info['suggested_path']}"
            
            # Add project information if available
            if file_info.get('is_project', False):
                context += f"\n  💻 Project: {file_info['project_type']} ({file_info['file_count']} files)"
                context += f"\n  📁 Should go to: Projects/"
            
            # Add document content analysis if available
            if 'content_hint' in file_info and file_info['content_hint']:
                context += f"\n  📄 Content: {file_info['content_hint'][:100]}..."
            
            if 'document_category' in file_info and file_info['document_category'] != 'unknown':
                context += f"\n  🏷️  Document Type: {file_info['document_category']}"
                
            context += "\n"
            
        if len(downloads_files) > 20:
            context += f"... and {len(downloads_files) - 20} more files\n"
            
        return context
    
    def _get_ai_suggestions(self, context: str, redundant_archives: Dict = None, archives_to_extract: Dict = None, destination_memory: Dict = None) -> Dict:
        """Get AI suggestions for file organization"""
        
        # Add redundant archive information to context
        redundant_info = ""
        if redundant_archives:
            redundant_info = f"""

DETECTED REDUNDANT ARCHIVES:
{json.dumps(redundant_archives, indent=2, default=str)}

For these archives, consider suggesting deletion if the content is already extracted.
"""

        # Add archives to extract information to context
        extract_info = ""
        if archives_to_extract:
            extract_info = f"""

ARCHIVES THAT SHOULD BE EXTRACTED:
{json.dumps(archives_to_extract, indent=2, default=str)}

These archives likely contain content that isn't extracted. Consider extraction before organization.
"""

        prompt = f"""
{context}{redundant_info}{extract_info}

Please analyze these files and suggest how to organize them into the existing sorted folder structure. 

IMPORTANT CATEGORIZATION RULES:
1. **Movies vs Series**: 
   - Single movie files (.mp4, .mkv, .avi, etc.) should go to "Movies" folder
   - Series episodes should go to "Series/[Series Name]/Season X/" structure
   
2. **Series Organization**: 
   - Detect series episodes by patterns like: S01E01, Season 1, 1x01, etc.
   - Extract series name and season number from filename
   - Create folder structure: Series/[Series Name]/Season [X]/
   - Examples: "Breaking.Bad.S01E01.mp4" → "Series/Breaking Bad/Season 1/"
   
3. **Redundant Archives**: If you see both an archive (RAR, ZIP, 7Z) AND the extracted content with similar names, suggest deleting the archive with action "delete_redundant".

4. **Software/Games**: ISO files, installers, and game files should go to "Software" or "Games" folders.

5. **Projects**: Software projects (especially with .git folders) should go to "Projects" folder. These are treated as single units, not individual files.

6. **Document Content**: Use content analysis for PDFs and Word docs to categorize intelligently.

7. **Unknown Files**: For files that don't fit clear categories, suggest action "needs_user_input" so user can specify what to do.

For each file, suggest:

1. DESTINATION: Which existing folder OR suggest a new folder name with full path
2. REASONING: Why this file belongs there (be specific about movie vs series logic)
3. ACTION: One of these options:
   - 'move_to_existing': Move to existing folder
   - 'create_new_folder': Create new folder and move there
   - 'delete_redundant': Delete this file (for redundant archives when content is extracted)
   - 'extract_archive': Extract this archive and organize its contents
   - 'delete_folder': Delete empty folder after moving contents
   - 'create_folder': Create a new organization folder
   - 'needs_user_input': File needs user clarification (for unknown/ambiguous files)

SPECIFIC EXAMPLES:
- "Thunderbolts.mp4" → Movies/ (single movie file)
- "Thunderbolts.rar" + "Thunderbolts.mp4" → Delete the RAR (redundant archive)
- "Breaking.Bad.S01E01.mp4" → Series/Breaking Bad/Season 1/ (series episode)
- "Game.of.Thrones.1x05.mp4" → Series/Game of Thrones/Season 1/ (series episode)
- "Ubuntu.iso" → Software/ (ISO file)
- "my-website-project/" (with .git) → Projects/ (software project)
- "V2K-homepage-files.zip" → needs_user_input (unclear project files)

Return your response as JSON with this structure:
{{
    "strategy": "Overall organization strategy",
    "new_folders": ["List of new folders to create"],
    "file_suggestions": [
        {{
            "file": "filename",
            "current_path": "current/path",
            "action": "move_to_existing|create_new_folder|delete_redundant|extract_archive|create_folder|delete_folder",
            "destination": "destination/path",
            "reasoning": "why this file goes here (be specific about movie vs TV show logic)",
            "confidence": 85,
            "document_type": "contract|receipt|invoice|personal|etc" // for documents only
        }}
    ],
    "total_files": "number of files processed"
}}
"""

        try:
            # Generate content using Gemini
            response = self.model.generate_content(prompt)
            
            # Parse the JSON response
            json_text = response.text.strip()
            if json_text.startswith('```json'):
                json_text = json_text[7:]
            if json_text.endswith('```'):
                json_text = json_text[:-3]
            
            result = json.loads(json_text.strip())
            return result
            
        except json.JSONDecodeError as e:
            print(f"JSON decode error: {e}")
            print(f"Raw response: {response.text[:500]}...")
            return {
                "error": "Failed to parse AI response as JSON",
                "raw_response": response.text[:500]
            }
        except Exception as e:
            error_str = str(e).lower()
            
            # Check for quota/rate limit errors (429)
            if any(quota_term in error_str for quota_term in ['quota', 'rate limit', '429', 'exceeded']):
                return {
                    "error_type": "quota_exceeded",
                    "error": "🚫 Gemini API Quota Exceeded",
                    "error_details": "You've reached your free tier limit for Gemini API requests. This typically means you've used up your daily or per-minute quota.",
                    "suggestions": [
                        "Wait a few minutes and try again (if you hit the per-minute limit)",
                        "Wait until tomorrow to reset daily quota",
                        "Enable billing in Google Cloud Console for higher limits",
                        "Use fewer files per analysis to reduce API usage",
                        "Switch to Gemini Flash model for higher free tier limits"
                    ],
                    "fallback_available": True,
                    "quota_info": {
                        "free_tier_limits": {
                            "gemini_1_5_pro": "2 requests/minute, 50 requests/day",
                            "gemini_1_5_flash": "15 requests/minute, 1500 requests/day"
                        },
                        "how_to_check": "No real-time quota checking available from Google's API"
                    }
                }
            
            # Check for other Google API errors
            elif any(api_term in error_str for api_term in ['internal server error', '500', 'internal error']):
                return {
                    "error_type": "api_error",
                    "error": "🔧 Gemini API Temporary Error",
                    "error_details": "Google's Gemini API is experiencing temporary issues. This is usually resolved quickly.",
                    "suggestions": [
                        "Wait a few minutes and try again",
                        "The issue is on Google's side, not your application",
                        "Try using a smaller batch of files"
                    ],
                    "fallback_available": True
                }
            
            # Check for authentication errors
            elif any(auth_term in error_str for auth_term in ['unauthorized', '401', 'api key', 'authentication']):
                return {
                    "error_type": "auth_error",
                    "error": "🔑 API Key Authentication Error",
                    "error_details": "Your Gemini API key is invalid, expired, or not properly configured.",
                    "suggestions": [
                        "Check that your API key is correct",
                        "Verify the API key has Gemini API access enabled",
                        "Make sure you've enabled the Generative AI API in Google Cloud Console",
                        "Check if your API key has expired"
                    ],
                    "fallback_available": False
                }
            
            # Generic error fallback
            else:
                print(f"AI analysis error: {e}")
                return {
                    "error_type": "generic_error",
                    "error": f"🤖 AI Analysis Failed: {str(e)}",
                    "error_details": "An unexpected error occurred during AI analysis.",
                    "suggestions": [
                        "Try again in a few moments",
                        "Check your internet connection",
                        "Contact support if the problem persists"
                    ],
                    "fallback_available": True
                }
    
    def _fallback_suggestions(self, context: str) -> Dict:
        """Fallback rule-based suggestions if AI fails"""
        return {
            "general_strategy": "Rule-based organization by file type",
            "new_folders_suggested": ["Documents", "Images", "Software", "Archives"],
            "file_suggestions": [],
            "summary": "AI analysis failed, using rule-based fallback",
            "error": "Could not connect to AI service"
        }

def demo_organization_analysis(downloads_path: str, sorted_path: str, api_key: str):
    """Demo function to show what the organizer would suggest"""
    
    print("🤖 Analyzing files with AI-powered organization logic...")
    print("=" * 60)
    
    organizer = SmartOrganizer(api_key)
    analysis = organizer.analyze_downloads_folder(downloads_path, sorted_path)
    
    print(f"📁 Found {analysis['total_files']} files to organize")
    print(f"📂 Strategy: {analysis['strategy']}")
    print()
    
    suggestions = {
        'general_strategy': analysis['strategy'],
        'new_folders_suggested': analysis['new_folders'],
        'file_suggestions': analysis['file_suggestions']
    }
    
    print("🧠 AI SUGGESTIONS:")
    print("-" * 40)
    print(f"Strategy: {suggestions.get('general_strategy', 'No strategy provided')}")
    print()
    
    if 'new_folders_suggested' in suggestions:
        print(f"🆕 New folders to create: {suggestions['new_folders_suggested']}")
        print()
    
    print("📋 FILE ORGANIZATION PLAN:")
    print("-" * 40)
    
    for suggestion in suggestions.get('file_suggestions', [])[:10]:  # Show first 10
        action_emoji = {"move_to_existing": "➡️", "create_new_folder": "🆕", "skip_for_now": "⏭️"}
        emoji = action_emoji.get(suggestion.get('action', 'skip_for_now'), "❓")
        
        print(f"{emoji} {suggestion.get('filename', 'Unknown file')}")
        print(f"   → Destination: {suggestion.get('destination', 'Unknown')}")
        print(f"   → Reason: {suggestion.get('reasoning', 'No reason provided')}")
        print(f"   → Confidence: {suggestion.get('confidence', 0.5)*100:.0f}%")
        print()
    
    if len(suggestions.get('file_suggestions', [])) > 10:
        remaining = len(suggestions['file_suggestions']) - 10
        print(f"... and {remaining} more file suggestions")
    
    print("\n" + "=" * 60)
    print("⚠️  NOTE: This is a PREVIEW only - no files were moved!")
    
    return analysis

if __name__ == "__main__":
    # This would be called from the API with actual paths and API key
    print("Smart Organizer module loaded. Use via API endpoint.")
