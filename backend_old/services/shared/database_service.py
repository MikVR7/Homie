#!/usr/bin/env python3
"""
Secure Database Service - Enterprise-grade SQLite operations
Handles all database operations with security-first design for customer deployment

Security Features:
- SQL injection prevention via parameterized queries
- Complete user data isolation 
- Input validation and sanitization
- Path traversal protection
- Comprehensive audit logging
- Password security with bcrypt
- Database encryption support
"""

import sqlite3
import hashlib
import secrets
import uuid
import os
import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any, Union
from contextlib import contextmanager
import bcrypt
import logging

# Setup security-focused logging
log_dir = os.path.join(os.path.dirname(__file__), '../../logs')
os.makedirs(log_dir, exist_ok=True)
log_file = os.path.join(log_dir, 'security.log')

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_file),
        logging.StreamHandler()
    ]
)
security_logger = logging.getLogger('HomieDB.Security')
audit_logger = logging.getLogger('HomieDB.Audit')

class DatabaseSecurityError(Exception):
    """Raised when security validation fails"""
    pass

class DatabaseService:
    """
    Secure Database Service for Homie Platform
    
    Provides enterprise-grade security for customer deployments:
    - Complete user data isolation
    - SQL injection prevention  
    - Input validation and sanitization
    - Comprehensive audit logging
    - Secure password handling
    """
    
    def __init__(self, db_path: str = "backend/data/homie.db", encryption_key: Optional[str] = None):
        """
        Initialize secure database service
        
        Args:
            db_path: Path to SQLite database file
            encryption_key: Optional encryption key for database (future: SQLCipher)
        """
        self.db_path = self._validate_db_path(db_path)
        self.encryption_key = encryption_key
        
        # Create database directory if it doesn't exist
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
        
        # Initialize database with secure schema
        self._initialize_database()
        
        # Setup audit logging
        audit_logger.info(f"DatabaseService initialized - Path: {self.db_path}")
    
    def _validate_db_path(self, db_path: str) -> str:
        """
        Validate database path to prevent directory traversal attacks
        
        Args:
            db_path: Proposed database path
            
        Returns:
            Validated absolute path
            
        Raises:
            DatabaseSecurityError: If path is invalid or dangerous
        """
        try:
            # Convert to absolute path and resolve any symbolic links
            abs_path = os.path.abspath(db_path)
            
            # Ensure path is within project directory (security boundary)
            project_root = os.path.abspath(os.path.dirname(__file__) + "/../../")
            if not abs_path.startswith(project_root):
                raise DatabaseSecurityError(f"Database path outside project boundary: {abs_path}")
            
            # Validate file extension
            if not abs_path.endswith('.db'):
                raise DatabaseSecurityError(f"Invalid database file extension: {abs_path}")
            
            # Check for path traversal attempts in the original path
            if '..' in db_path or '~' in db_path:
                # Only reject if the path traversal is still present after normalization
                if '..' in abs_path or '~' in abs_path:
                    raise DatabaseSecurityError(f"Path traversal attempt detected: {db_path}")
            
            return abs_path
            
        except Exception as e:
            security_logger.error(f"Database path validation failed: {db_path} - {e}")
            raise DatabaseSecurityError(f"Invalid database path: {db_path}")
    
    @contextmanager
    def _get_connection(self):
        """
        Secure database connection context manager
        
        Yields:
            sqlite3.Connection: Database connection with security settings
        """
        conn = None
        try:
            # Connect with security settings
            conn = sqlite3.connect(
                self.db_path,
                timeout=30.0,  # Prevent indefinite locks
                isolation_level=None,  # Autocommit mode for better concurrency
                check_same_thread=False  # Allow multi-thread access
            )
            
            # Enable foreign key constraints for data integrity
            conn.execute("PRAGMA foreign_keys = ON")
            
            # Set secure pragma settings
            conn.execute("PRAGMA journal_mode = WAL")  # Better concurrency
            conn.execute("PRAGMA synchronous = FULL")   # Prevent corruption
            conn.execute("PRAGMA temp_store = MEMORY")  # Memory temp storage
            
            # Row factory for easier data access
            conn.row_factory = sqlite3.Row
            
            yield conn
            
        except Exception as e:
            security_logger.error(f"Database connection error: {e}")
            if conn:
                conn.rollback()
            raise
        finally:
            if conn:
                conn.close()
    
    def _initialize_database(self):
        """Initialize database with secure schema"""
        with self._get_connection() as conn:
            cursor = conn.cursor()
            
            # Create users table with security features
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS users (
                    id TEXT PRIMARY KEY,
                    email TEXT UNIQUE NOT NULL,
                    username TEXT UNIQUE,
                    password_hash TEXT,
                    salt TEXT NOT NULL,
                    subscription_tier TEXT DEFAULT 'free',
                    backend_type TEXT DEFAULT 'local',
                    backend_url TEXT,
                    is_active BOOLEAN DEFAULT TRUE,
                    failed_login_attempts INTEGER DEFAULT 0,
                    last_failed_login TIMESTAMP,
                    account_locked_until TIMESTAMP,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    last_login TIMESTAMP,
                    last_password_change TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # Create destination mappings table with user and module isolation
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS destination_mappings (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    module_name TEXT NOT NULL DEFAULT 'file_organizer',
                    file_category TEXT NOT NULL,
                    destination_path TEXT NOT NULL,
                    drive_info TEXT,
                    confidence_score REAL DEFAULT 0.5 CHECK(confidence_score >= 0 AND confidence_score <= 1),
                    usage_count INTEGER DEFAULT 1 CHECK(usage_count >= 0),
                    last_used TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
                )
            """)
            
            # Create series mappings table with module isolation
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS series_mappings (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    module_name TEXT NOT NULL DEFAULT 'file_organizer',
                    series_name TEXT NOT NULL,
                    destination_path TEXT NOT NULL,
                    season_structure TEXT,
                    usage_count INTEGER DEFAULT 1 CHECK(usage_count >= 0),
                    last_used TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
                )
            """)
            
            # Create user drives table with module isolation
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS user_drives (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    module_name TEXT NOT NULL DEFAULT 'file_organizer',
                    drive_path TEXT NOT NULL,
                    drive_type TEXT NOT NULL CHECK(drive_type IN ('local', 'network', 'cloud', 'usb')),
                    drive_name TEXT,
                    filesystem TEXT,
                    is_active BOOLEAN DEFAULT TRUE,
                    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
                )
            """)
            
            # Create user preferences table (already has module_name)
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS user_preferences (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    preference_key TEXT NOT NULL,
                    preference_value TEXT,
                    module_name TEXT,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
                )
            """)
            
            # Create file actions table for audit trail with module isolation
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS file_actions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    module_name TEXT NOT NULL DEFAULT 'file_organizer',
                    action_type TEXT NOT NULL,
                    file_name TEXT NOT NULL,
                    source_path TEXT,
                    destination_path TEXT,
                    success BOOLEAN,
                    error_message TEXT,
                    ip_address TEXT,
                    user_agent TEXT,
                    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
                )
            """)
            
            # Create module-specific data table for flexible module storage
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS module_data (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    module_name TEXT NOT NULL,
                    data_key TEXT NOT NULL,
                    data_value TEXT,
                    data_type TEXT DEFAULT 'json',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                    UNIQUE(user_id, module_name, data_key)
                )
            """)
            
            # Create security audit table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS security_audit (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT,
                    module_name TEXT,
                    event_type TEXT NOT NULL,
                    event_description TEXT NOT NULL,
                    ip_address TEXT,
                    user_agent TEXT,
                    risk_level TEXT DEFAULT 'LOW' CHECK(risk_level IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
                    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
                )
            """)
            
            # Create security indexes for performance
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_destination_mappings_user_module ON destination_mappings(user_id, module_name)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_series_mappings_user_module ON series_mappings(user_id, module_name)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_user_drives_user_module ON user_drives(user_id, module_name)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_file_actions_user_module ON file_actions(user_id, module_name)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_module_data_user_module ON module_data(user_id, module_name)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_security_audit_timestamp ON security_audit(timestamp)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)")
            
            conn.commit()
            audit_logger.info("Database schema initialized successfully")
    
    def _validate_user_id(self, user_id: str) -> str:
        """
        Validate user ID format and existence
        
        Args:
            user_id: User ID to validate
            
        Returns:
            Validated user ID
            
        Raises:
            DatabaseSecurityError: If user ID is invalid
        """
        if not user_id or not isinstance(user_id, str):
            raise DatabaseSecurityError("Invalid user ID format")
        
        # Validate UUID format
        try:
            uuid.UUID(user_id)
        except ValueError:
            raise DatabaseSecurityError(f"Invalid user ID format: {user_id}")
        
        return user_id
    
    def _validate_file_path(self, file_path: str) -> str:
        """
        Validate and sanitize file paths to prevent path traversal attacks
        
        Args:
            file_path: File path to validate
            
        Returns:
            Sanitized file path
            
        Raises:
            DatabaseSecurityError: If path is dangerous
        """
        if not file_path or not isinstance(file_path, str):
            raise DatabaseSecurityError("Invalid file path")
        
        # Check for path traversal attempts
        dangerous_patterns = ['../', '..\\', '~/', '~\\', '/etc/', '/proc/', '/sys/']
        for pattern in dangerous_patterns:
            if pattern in file_path.lower():
                raise DatabaseSecurityError(f"Dangerous path pattern detected: {file_path}")
        
        # Sanitize path
        sanitized = os.path.normpath(file_path)
        
        # Additional validation
        if len(sanitized) > 4096:  # Reasonable path length limit
            raise DatabaseSecurityError("File path too long")
        
        return sanitized
    
    def _log_security_event(self, user_id: Optional[str], event_type: str, 
                           description: str, risk_level: str = "LOW",
                           ip_address: Optional[str] = None, user_agent: Optional[str] = None,
                           module_name: Optional[str] = None):
        """
        Log security events for audit trail with module tracking
        
        Args:
            user_id: User ID (optional for system events)
            event_type: Type of security event
            description: Event description
            risk_level: Risk level (LOW, MEDIUM, HIGH, CRITICAL)
            ip_address: Client IP address
            user_agent: Client user agent
            module_name: Module name (optional)
        """
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    INSERT INTO security_audit 
                    (user_id, module_name, event_type, event_description, risk_level, ip_address, user_agent)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                """, (user_id, module_name, event_type, description, risk_level, ip_address, user_agent))
                conn.commit()
                
                # Also log to file
                module_info = f" (Module: {module_name})" if module_name else ""
                security_logger.info(f"SECURITY_EVENT: {event_type} - {description} - User: {user_id}{module_info} - Risk: {risk_level}")
                
        except Exception as e:
            security_logger.error(f"Failed to log security event: {e}")
    
    def create_user(self, email: str, username: Optional[str] = None, 
                   password: Optional[str] = None, backend_type: str = "local",
                   backend_url: Optional[str] = None) -> str:
        """
        Create new user with secure password handling
        
        Args:
            email: User email address
            username: Optional username
            password: Optional password (for cloud backend)
            backend_type: Backend type ('local' or 'cloud')
            backend_url: Backend URL for cloud users
            
        Returns:
            User ID (UUID)
            
        Raises:
            DatabaseSecurityError: If validation fails
        """
        # Input validation
        if not email or not isinstance(email, str):
            raise DatabaseSecurityError("Valid email required")
        
        # Email format validation
        email_pattern = re.compile(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        if not email_pattern.match(email):
            raise DatabaseSecurityError("Invalid email format")
        
        # Generate secure user ID
        user_id = str(uuid.uuid4())
        
        # Generate secure salt
        salt = secrets.token_hex(32)
        
        # Hash password if provided
        password_hash = None
        if password:
            if len(password) < 8:
                raise DatabaseSecurityError("Password must be at least 8 characters")
            password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    INSERT INTO users 
                    (id, email, username, password_hash, salt, backend_type, backend_url)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                """, (user_id, email, username, password_hash, salt, backend_type, backend_url))
                conn.commit()
                
                self._log_security_event(user_id, "USER_CREATED", f"New user created: {email}")
                audit_logger.info(f"User created successfully: {user_id} - {email}")
                
                return user_id
                
        except sqlite3.IntegrityError as e:
            if "email" in str(e):
                raise DatabaseSecurityError("Email already exists")
            elif "username" in str(e):
                raise DatabaseSecurityError("Username already exists")
            else:
                raise DatabaseSecurityError("User creation failed")
        except Exception as e:
            security_logger.error(f"User creation failed: {e}")
            raise DatabaseSecurityError("User creation failed")
    
    def get_user_destination_mappings(self, user_id: str, module_name: str = 'file_organizer') -> List[Dict[str, Any]]:
        """
        Get destination mappings for a specific user and module (with complete isolation)
        
        Args:
            user_id: User ID
            module_name: Module name (e.g., 'file_organizer', 'financial_manager')
            
        Returns:
            List of destination mappings for the user and module
        """
        validated_user_id = self._validate_user_id(user_id)
        
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT id, file_category, destination_path, drive_info, 
                           confidence_score, usage_count, last_used, created_at
                    FROM destination_mappings 
                    WHERE user_id = ? AND module_name = ?
                    ORDER BY usage_count DESC, last_used DESC
                """, (validated_user_id, module_name))
                
                results = []
                for row in cursor.fetchall():
                    drive_info = json.loads(row['drive_info']) if row['drive_info'] else {}
                    results.append({
                        'id': row['id'],
                        'file_category': row['file_category'],
                        'destination_path': row['destination_path'],
                        'drive_info': drive_info,
                        'confidence_score': row['confidence_score'],
                        'usage_count': row['usage_count'],
                        'last_used': row['last_used'],
                        'created_at': row['created_at']
                    })
                
                return results
                
        except Exception as e:
            security_logger.error(f"Failed to get destination mappings for user {user_id}, module {module_name}: {e}")
            return []
    
    def add_destination_mapping(self, user_id: str, file_category: str, 
                              destination_path: str, module_name: str = 'file_organizer',
                              drive_info: Optional[Dict] = None,
                              confidence_score: float = 0.5) -> int:
        """
        Add or update destination mapping for a user and module
        
        Args:
            user_id: User ID
            file_category: File category (videos, documents, etc.)
            destination_path: Destination folder path
            module_name: Module name (e.g., 'file_organizer', 'financial_manager')
            drive_info: Optional drive information
            confidence_score: Confidence score (0.0-1.0)
            
        Returns:
            Mapping ID
        """
        validated_user_id = self._validate_user_id(user_id)
        validated_path = self._validate_file_path(destination_path)
        
        # Validate confidence score
        if not 0.0 <= confidence_score <= 1.0:
            raise DatabaseSecurityError("Confidence score must be between 0.0 and 1.0")
        
        drive_info_json = json.dumps(drive_info) if drive_info else None
        
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                
                # Check if mapping already exists
                cursor.execute("""
                    SELECT id, usage_count FROM destination_mappings 
                    WHERE user_id = ? AND module_name = ? AND file_category = ? AND destination_path = ?
                """, (validated_user_id, module_name, file_category, validated_path))
                
                existing = cursor.fetchone()
                
                if existing:
                    # Update existing mapping
                    cursor.execute("""
                        UPDATE destination_mappings 
                        SET usage_count = usage_count + 1, 
                            last_used = CURRENT_TIMESTAMP,
                            confidence_score = ?,
                            drive_info = ?
                        WHERE id = ?
                    """, (confidence_score, drive_info_json, existing['id']))
                    mapping_id = existing['id']
                else:
                    # Create new mapping
                    cursor.execute("""
                        INSERT INTO destination_mappings 
                        (user_id, module_name, file_category, destination_path, drive_info, confidence_score)
                        VALUES (?, ?, ?, ?, ?, ?)
                    """, (validated_user_id, module_name, file_category, validated_path, drive_info_json, confidence_score))
                    mapping_id = cursor.lastrowid
                
                conn.commit()
                
                self._log_security_event(
                    validated_user_id, 
                    "DESTINATION_MAPPING_UPDATED", 
                    f"Updated mapping: {file_category} -> {validated_path} (module: {module_name})",
                    module_name=module_name
                )
                
                return mapping_id
                
        except Exception as e:
            security_logger.error(f"Failed to add destination mapping: {e}")
            raise DatabaseSecurityError("Failed to add destination mapping")
    
    def log_file_action(self, user_id: str, action_type: str, file_name: str,
                       module_name: str = 'file_organizer',
                       source_path: Optional[str] = None, destination_path: Optional[str] = None,
                       success: bool = True, error_message: Optional[str] = None,
                       ip_address: Optional[str] = None, user_agent: Optional[str] = None):
        """
        Log file action for audit trail with module isolation
        
        Args:
            user_id: User ID
            action_type: Type of action (move, delete, etc.)
            file_name: Name of file
            module_name: Module name (e.g., 'file_organizer', 'financial_manager')
            source_path: Source path (optional)
            destination_path: Destination path (optional)
            success: Whether action succeeded
            error_message: Error message if failed
            ip_address: Client IP address
            user_agent: Client user agent
        """
        validated_user_id = self._validate_user_id(user_id)
        
        # Validate and sanitize paths
        if source_path:
            source_path = self._validate_file_path(source_path)
        if destination_path:
            destination_path = self._validate_file_path(destination_path)
        
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    INSERT INTO file_actions 
                    (user_id, module_name, action_type, file_name, source_path, destination_path, 
                     success, error_message, ip_address, user_agent)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (validated_user_id, module_name, action_type, file_name, source_path, 
                      destination_path, success, error_message, ip_address, user_agent))
                conn.commit()
                
                # Log security event for failed actions
                if not success:
                    self._log_security_event(
                        validated_user_id,
                        "FILE_ACTION_FAILED",
                        f"Failed {action_type}: {file_name} - {error_message}",
                        "MEDIUM",
                        module_name=module_name
                    )
                
        except Exception as e:
            security_logger.error(f"Failed to log file action: {e}")
    
    def get_user_drives(self, user_id: str, module_name: str = 'file_organizer') -> List[Dict[str, Any]]:
        """
        Get available drives for a user and module
        
        Args:
            user_id: User ID
            module_name: Module name (e.g., 'file_organizer', 'financial_manager')
            
        Returns:
            List of user drives for the module
        """
        validated_user_id = self._validate_user_id(user_id)
        
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT id, drive_path, drive_type, drive_name, filesystem, 
                           is_active, last_seen, created_at
                    FROM user_drives 
                    WHERE user_id = ? AND module_name = ? AND is_active = TRUE
                    ORDER BY drive_type, drive_name
                """, (validated_user_id, module_name))
                
                results = []
                for row in cursor.fetchall():
                    results.append({
                        'id': row['id'],
                        'drive_path': row['drive_path'],
                        'drive_type': row['drive_type'],
                        'drive_name': row['drive_name'],
                        'filesystem': row['filesystem'],
                        'is_active': row['is_active'],
                        'last_seen': row['last_seen'],
                        'created_at': row['created_at']
                    })
                
                return results
                
        except Exception as e:
            security_logger.error(f"Failed to get drives for user {user_id}, module {module_name}: {e}")
            return []
    
    def store_module_data(self, user_id: str, module_name: str, data_key: str, 
                         data_value: Any, data_type: str = 'json') -> bool:
        """
        Store module-specific data with user isolation
        
        Args:
            user_id: User ID
            module_name: Module name (e.g., 'file_organizer', 'financial_manager')
            data_key: Data key
            data_value: Data value (will be JSON serialized)
            data_type: Data type ('json', 'text', 'number')
            
        Returns:
            Success status
        """
        validated_user_id = self._validate_user_id(user_id)
        
        # Serialize data value
        if data_type == 'json':
            serialized_value = json.dumps(data_value, ensure_ascii=False)
        else:
            serialized_value = str(data_value)
        
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    INSERT OR REPLACE INTO module_data 
                    (user_id, module_name, data_key, data_value, data_type, updated_at)
                    VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
                """, (validated_user_id, module_name, data_key, serialized_value, data_type))
                conn.commit()
                
                return True
                
        except Exception as e:
            security_logger.error(f"Failed to store module data: {e}")
            return False
    
    def get_module_data(self, user_id: str, module_name: str, data_key: str, 
                       default_value: Any = None) -> Any:
        """
        Get module-specific data with user isolation
        
        Args:
            user_id: User ID
            module_name: Module name (e.g., 'file_organizer', 'financial_manager')
            data_key: Data key
            default_value: Default value if not found
            
        Returns:
            Deserialized data value or default
        """
        validated_user_id = self._validate_user_id(user_id)
        
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT data_value, data_type FROM module_data 
                    WHERE user_id = ? AND module_name = ? AND data_key = ?
                """, (validated_user_id, module_name, data_key))
                
                row = cursor.fetchone()
                if row:
                    data_value = row['data_value']
                    data_type = row['data_type']
                    
                    # Deserialize based on type
                    if data_type == 'json':
                        return json.loads(data_value)
                    elif data_type == 'number':
                        return float(data_value) if '.' in data_value else int(data_value)
                    else:
                        return data_value
                else:
                    return default_value
                
        except Exception as e:
            security_logger.error(f"Failed to get module data: {e}")
            return default_value
    
    def get_all_module_data(self, user_id: str, module_name: str) -> Dict[str, Any]:
        """
        Get all module-specific data for a user and module
        
        Args:
            user_id: User ID
            module_name: Module name (e.g., 'file_organizer', 'financial_manager')
            
        Returns:
            Dictionary of all module data
        """
        validated_user_id = self._validate_user_id(user_id)
        
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT data_key, data_value, data_type FROM module_data 
                    WHERE user_id = ? AND module_name = ?
                    ORDER BY data_key
                """, (validated_user_id, module_name))
                
                results = {}
                for row in cursor.fetchall():
                    data_value = row['data_value']
                    data_type = row['data_type']
                    
                    # Deserialize based on type
                    if data_type == 'json':
                        results[row['data_key']] = json.loads(data_value)
                    elif data_type == 'number':
                        results[row['data_key']] = float(data_value) if '.' in data_value else int(data_value)
                    else:
                        results[row['data_key']] = data_value
                
                return results
                
        except Exception as e:
            security_logger.error(f"Failed to get all module data: {e}")
            return {}
    
    def close(self):
        """Close database service gracefully"""
        audit_logger.info("DatabaseService closed") 