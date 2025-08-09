#!/usr/bin/env python3
"""
Module Database Service - Separate database files for each module
Provides true module isolation with separate database files

Architecture:
- homie_users.db: User management and authentication
- homie_file_organizer.db: File organization and destination memory
- homie_financial_manager.db: Financial data and transactions
- homie_media_manager.db: Media library and watch history
- homie_document_manager.db: Document management and OCR
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

class ModuleDatabaseError(Exception):
    """Raised when module database operations fail"""
    pass

class ModuleDatabaseService:
    """
    Module-Specific Database Service for Homie Platform
    
    Each module gets its own database file for true isolation:
    - homie_users.db: User management and authentication
    - homie_file_organizer.db: File organization and destination memory
    - homie_financial_manager.db: Financial data and transactions
    - homie_media_manager.db: Media library and watch history
    - homie_document_manager.db: Document management and OCR
    """
    
    def __init__(self, data_dir: str = "backend/data"):
        """
        Initialize module database service
        
        Args:
            data_dir: Directory containing module databases
        """
        self.data_dir = os.path.abspath(data_dir)
        self.modules_dir = os.path.join(self.data_dir, "modules")
        
        # Create directories if they don't exist
        os.makedirs(self.data_dir, exist_ok=True)
        os.makedirs(self.modules_dir, exist_ok=True)
        
        # Initialize all module databases
        self._initialize_all_databases()
        
        audit_logger.info(f"ModuleDatabaseService initialized - Data dir: {self.data_dir}")
    
    def _get_database_path(self, module_name: str) -> str:
        """Get database path for a specific module"""
        if module_name == "users":
            return os.path.join(self.data_dir, "homie_users.db")
        else:
            return os.path.join(self.modules_dir, f"homie_{module_name}.db")
    
    def _validate_module_name(self, module_name: str) -> str:
        """Validate module name"""
        valid_modules = ["users", "file_organizer", "financial_manager", "media_manager", "document_manager"]
        if module_name not in valid_modules:
            raise ModuleDatabaseError(f"Invalid module name: {module_name}")
        return module_name
    
    @contextmanager
    def _get_connection(self, module_name: str):
        """
        Get database connection for a specific module
        
        Args:
            module_name: Name of the module (users, file_organizer, etc.)
        """
        validated_module = self._validate_module_name(module_name)
        db_path = self._get_database_path(validated_module)
        
        conn = None
        try:
            # Connect with security settings
            conn = sqlite3.connect(
                db_path,
                timeout=30.0,
                isolation_level=None,
                check_same_thread=False
            )
            
            # Enable foreign key constraints for data integrity
            conn.execute("PRAGMA foreign_keys = ON")
            
            # Set secure pragma settings
            conn.execute("PRAGMA journal_mode = DELETE")
            conn.execute("PRAGMA synchronous = NORMAL")
            conn.execute("PRAGMA temp_store = MEMORY")
            
            # Row factory for easier data access
            conn.row_factory = sqlite3.Row
            
            yield conn
            
        except Exception as e:
            security_logger.error(f"Database connection error for {module_name}: {e}")
            if conn:
                conn.rollback()
            raise
        finally:
            if conn:
                conn.close()
    
    def _initialize_all_databases(self):
        """Initialize all module databases with their specific schemas"""
        self._initialize_users_database()
        self._initialize_file_organizer_database()
        self._initialize_financial_manager_database()
        self._initialize_media_manager_database()
        self._initialize_document_manager_database()
    
    def _initialize_users_database(self):
        """Initialize users database with authentication and user management"""
        with self._get_connection("users") as conn:
            cursor = conn.cursor()
            
            # Create users table
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
            
            # Create user preferences table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS user_preferences (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    preference_key TEXT NOT NULL,
                    preference_value TEXT,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
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
            
            # Create indexes
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_security_audit_timestamp ON security_audit(timestamp)")
            
            conn.commit()
            audit_logger.info("Users database initialized successfully")
    
    def _initialize_file_organizer_database(self):
        """Initialize File Organizer database with destination memory and file operations"""
        with self._get_connection("file_organizer") as conn:
            cursor = conn.cursor()
            
            # Create destination mappings table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS destination_mappings (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    file_category TEXT NOT NULL,
                    destination_path TEXT NOT NULL,
                    drive_info TEXT,
                    confidence_score REAL DEFAULT 0.5 CHECK(confidence_score >= 0 AND confidence_score <= 1),
                    usage_count INTEGER DEFAULT 1 CHECK(usage_count >= 0),
                    last_used TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # Create series mappings table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS series_mappings (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    series_name TEXT NOT NULL,
                    destination_path TEXT NOT NULL,
                    season_structure TEXT,
                    usage_count INTEGER DEFAULT 1 CHECK(usage_count >= 0),
                    last_used TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # Create user drives table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS user_drives (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    drive_path TEXT NOT NULL,
                    drive_type TEXT NOT NULL CHECK(drive_type IN ('local', 'network', 'cloud', 'usb')),
                    drive_label TEXT,
                    usb_serial_number TEXT,
                    partition_uuid TEXT,
                    identifier_type TEXT NOT NULL CHECK(identifier_type IN ('usb_serial', 'partition_uuid', 'label_size')),
                    primary_identifier TEXT NOT NULL,
                    is_connected BOOLEAN DEFAULT 0,
                    last_used TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(user_id, primary_identifier)
                )
            """)
            
            # Create file actions table for audit trail
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS file_actions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    action_type TEXT NOT NULL,
                    file_name TEXT NOT NULL,
                    source_path TEXT,
                    destination_path TEXT,
                    success BOOLEAN,
                    error_message TEXT,
                    ip_address TEXT,
                    user_agent TEXT,
                    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # Create module data table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS module_data (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    data_key TEXT NOT NULL,
                    data_value TEXT,
                    data_type TEXT DEFAULT 'json',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(user_id, data_key)
                )
            """)
            
            # Create indexes
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_destination_mappings_user ON destination_mappings(user_id)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_series_mappings_user ON series_mappings(user_id)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_user_drives_user ON user_drives(user_id)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_file_actions_user ON file_actions(user_id)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_module_data_user ON module_data(user_id)")
            
            conn.commit()
            audit_logger.info("File Organizer database initialized successfully")
    
    def _initialize_financial_manager_database(self):
        """Initialize Financial Manager database with accounts, transactions, and financial data"""
        with self._get_connection("financial_manager") as conn:
            cursor = conn.cursor()
            
            # Create user accounts table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS user_accounts (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    account_name TEXT NOT NULL,
                    account_type TEXT NOT NULL CHECK(account_type IN ('checking', 'savings', 'investment', 'credit', 'cash')),
                    balance REAL DEFAULT 0.0,
                    currency TEXT DEFAULT 'EUR',
                    is_active BOOLEAN DEFAULT TRUE,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # Create transactions table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS transactions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    account_id INTEGER,
                    transaction_type TEXT NOT NULL CHECK(transaction_type IN ('income', 'expense', 'transfer')),
                    amount REAL NOT NULL,
                    description TEXT,
                    category TEXT,
                    date DATE NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (account_id) REFERENCES user_accounts(id) ON DELETE SET NULL
                )
            """)
            
            # Create construction budget table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS construction_budget (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    category TEXT NOT NULL,
                    budgeted_amount REAL NOT NULL,
                    spent_amount REAL DEFAULT 0.0,
                    notes TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # Create securities portfolio table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS securities (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    symbol TEXT NOT NULL,
                    name TEXT,
                    quantity REAL NOT NULL,
                    purchase_price REAL,
                    current_price REAL,
                    purchase_date DATE,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # Create module data table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS module_data (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    data_key TEXT NOT NULL,
                    data_value TEXT,
                    data_type TEXT DEFAULT 'json',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(user_id, data_key)
                )
            """)
            
            # Create indexes
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_user_accounts_user ON user_accounts(user_id)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_transactions_user ON transactions(user_id)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_construction_budget_user ON construction_budget(user_id)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_securities_user ON securities(user_id)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_module_data_user ON module_data(user_id)")
            
            conn.commit()
            audit_logger.info("Financial Manager database initialized successfully")
    
    def _initialize_media_manager_database(self):
        """Initialize Media Manager database with media library and watch history"""
        with self._get_connection("media_manager") as conn:
            cursor = conn.cursor()
            
            # Create media library table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS media_library (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    title TEXT NOT NULL,
                    media_type TEXT NOT NULL CHECK(media_type IN ('movie', 'series', 'documentary', 'show')),
                    file_path TEXT NOT NULL,
                    file_size INTEGER,
                    duration INTEGER,
                    year INTEGER,
                    rating REAL,
                    genre TEXT,
                    description TEXT,
                    poster_path TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # Create watch history table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS watch_history (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    media_id INTEGER NOT NULL,
                    watch_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    watch_duration INTEGER,
                    completed BOOLEAN DEFAULT FALSE,
                    FOREIGN KEY (media_id) REFERENCES media_library(id) ON DELETE CASCADE
                )
            """)
            
            # Create series episodes table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS series_episodes (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    series_title TEXT NOT NULL,
                    season_number INTEGER NOT NULL,
                    episode_number INTEGER NOT NULL,
                    episode_title TEXT,
                    file_path TEXT NOT NULL,
                    watch_status TEXT DEFAULT 'unwatched' CHECK(watch_status IN ('unwatched', 'watching', 'completed')),
                    watch_date TIMESTAMP,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # Create module data table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS module_data (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    data_key TEXT NOT NULL,
                    data_value TEXT,
                    data_type TEXT DEFAULT 'json',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(user_id, data_key)
                )
            """)
            
            # Create indexes
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_media_library_user ON media_library(user_id)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_watch_history_user ON watch_history(user_id)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_series_episodes_user ON series_episodes(user_id)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_module_data_user ON module_data(user_id)")
            
            conn.commit()
            audit_logger.info("Media Manager database initialized successfully")
    
    def _initialize_document_manager_database(self):
        """Initialize Document Manager database with document management and OCR"""
        with self._get_connection("document_manager") as conn:
            cursor = conn.cursor()
            
            # Create documents table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS documents (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    title TEXT NOT NULL,
                    file_path TEXT NOT NULL,
                    document_type TEXT NOT NULL CHECK(document_type IN ('invoice', 'contract', 'receipt', 'report', 'other')),
                    category TEXT,
                    amount REAL,
                    date DATE,
                    ocr_text TEXT,
                    tags TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # Create document categories table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS document_categories (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    category_name TEXT NOT NULL,
                    parent_category TEXT,
                    color TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # Create module data table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS module_data (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    data_key TEXT NOT NULL,
                    data_value TEXT,
                    data_type TEXT DEFAULT 'json',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(user_id, data_key)
                )
            """)
            
            # Create indexes
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_documents_user ON documents(user_id)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_document_categories_user ON document_categories(user_id)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_module_data_user ON module_data(user_id)")
            
            conn.commit()
            audit_logger.info("Document Manager database initialized successfully")
    
    # User Management Methods (users database)
    def create_user(self, email: str, username: Optional[str] = None, 
                   password: Optional[str] = None, backend_type: str = "local",
                   backend_url: Optional[str] = None) -> str:
        """Create new user in users database"""
        # Input validation
        if not email or not isinstance(email, str):
            raise ModuleDatabaseError("Valid email required")
        
        # Email format validation
        email_pattern = re.compile(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        if not email_pattern.match(email):
            raise ModuleDatabaseError("Invalid email format")
        
        # Generate secure user ID
        user_id = str(uuid.uuid4())
        
        # Generate secure salt
        salt = secrets.token_hex(32)
        
        # Hash password if provided
        password_hash = None
        if password:
            if len(password) < 8:
                raise ModuleDatabaseError("Password must be at least 8 characters")
            password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        try:
            with self._get_connection("users") as conn:
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
                raise ModuleDatabaseError("Email already exists")
            elif "username" in str(e):
                raise ModuleDatabaseError("Username already exists")
            else:
                raise ModuleDatabaseError("User creation failed")
        except Exception as e:
            security_logger.error(f"User creation failed: {e}")
            raise ModuleDatabaseError("User creation failed")
    
    def _log_security_event(self, user_id: Optional[str], event_type: str, 
                           description: str, risk_level: str = "LOW",
                           ip_address: Optional[str] = None, user_agent: Optional[str] = None,
                           module_name: Optional[str] = None):
        """Log security events to users database"""
        try:
            with self._get_connection("users") as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    INSERT INTO security_audit 
                    (user_id, module_name, event_type, event_description, risk_level, ip_address, user_agent)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                """, (user_id, module_name, event_type, description, risk_level, ip_address, user_agent))
                conn.commit()
                
                module_info = f" (Module: {module_name})" if module_name else ""
                security_logger.info(f"SECURITY_EVENT: {event_type} - {description} - User: {user_id}{module_info} - Risk: {risk_level}")
                
        except Exception as e:
            security_logger.error(f"Failed to log security event: {e}")
    
    # File Organizer Methods
    def get_user_destination_mappings(self, user_id: str) -> List[Dict[str, Any]]:
        """Get destination mappings for File Organizer module"""
        try:
            with self._get_connection("file_organizer") as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT id, file_category, destination_path, drive_info, 
                           confidence_score, usage_count, last_used, created_at
                    FROM destination_mappings 
                    WHERE user_id = ?
                    ORDER BY usage_count DESC, last_used DESC
                """, (user_id,))
                
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
            security_logger.error(f"Failed to get destination mappings for user {user_id}: {e}")
            return []
    
    def add_destination_mapping(self, user_id: str, file_category: str, 
                              destination_path: str, confidence_score: float = 0.5) -> int:
        """Add destination mapping for File Organizer module"""
        try:
            with self._get_connection("file_organizer") as conn:
                cursor = conn.cursor()
                
                # Check if mapping already exists
                cursor.execute("""
                    SELECT id, usage_count FROM destination_mappings 
                    WHERE user_id = ? AND file_category = ? AND destination_path = ?
                """, (user_id, file_category, destination_path))
                
                existing = cursor.fetchone()
                
                if existing:
                    # Update existing mapping
                    cursor.execute("""
                        UPDATE destination_mappings 
                        SET usage_count = usage_count + 1, 
                            last_used = CURRENT_TIMESTAMP,
                            confidence_score = ?
                        WHERE id = ?
                    """, (confidence_score, existing['id']))
                    mapping_id = existing['id']
                else:
                    # Create new mapping
                    cursor.execute("""
                        INSERT INTO destination_mappings 
                        (user_id, file_category, destination_path, confidence_score)
                        VALUES (?, ?, ?, ?)
                    """, (user_id, file_category, destination_path, confidence_score))
                    mapping_id = cursor.lastrowid
                
                conn.commit()
                
                self._log_security_event(
                    user_id, 
                    "DESTINATION_MAPPING_UPDATED", 
                    f"Updated mapping: {file_category} -> {destination_path}",
                    module_name="file_organizer"
                )
                
                return mapping_id
                
        except Exception as e:
            security_logger.error(f"Failed to add destination mapping: {e}")
            raise ModuleDatabaseError("Failed to add destination mapping")
    
    def log_file_action(self, user_id: str, action_type: str, file_name: str,
                       source_path: Optional[str] = None, destination_path: Optional[str] = None,
                       success: bool = True, error_message: Optional[str] = None,
                       ip_address: Optional[str] = None, user_agent: Optional[str] = None):
        """Log file action for File Organizer module"""
        try:
            with self._get_connection("file_organizer") as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    INSERT INTO file_actions 
                    (user_id, action_type, file_name, source_path, destination_path, 
                     success, error_message, ip_address, user_agent)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (user_id, action_type, file_name, source_path, 
                      destination_path, success, error_message, ip_address, user_agent))
                conn.commit()
                
                # Log security event for failed actions
                if not success:
                    self._log_security_event(
                        user_id,
                        "FILE_ACTION_FAILED",
                        f"Failed {action_type}: {file_name} - {error_message}",
                        "MEDIUM",
                        module_name="file_organizer"
                    )
                
        except Exception as e:
            security_logger.error(f"Failed to log file action: {e}")
    
    def get_file_actions(self, user_id: str, days: int = 30, source_path: Optional[str] = None) -> List[Dict[str, Any]]:
        """Get file actions from the database"""
        try:
            with self._get_connection("file_organizer") as conn:
                cursor = conn.cursor()
                
                # Build query based on parameters
                query = """
                    SELECT action_type, file_name, source_path, destination_path, 
                           success, error_message, timestamp
                    FROM file_actions 
                    WHERE user_id = ?
                """
                params = [user_id]
                
                if source_path:
                    query += " AND source_path = ?"
                    params.append(source_path)
                
                query += " ORDER BY timestamp DESC"
                
                cursor.execute(query, params)
                rows = cursor.fetchall()
                
                return [
                    {
                        'action': row[0],
                        'file_path': row[1],
                        'source_path': row[2],
                        'destination_path': row[3],
                        'success': bool(row[4]),
                        'error': row[5] or '',
                        'timestamp': row[6]
                    }
                    for row in rows
                ]
                
        except Exception as e:
            security_logger.error(f"Error getting file actions: {e}")
            return []
    
    def add_user_drive(self, user_id: str, drive_path: str, drive_type: str, 
                       drive_label: str = '', usb_serial_number: str = '', 
                       partition_uuid: str = '', identifier_type: str = '', 
                       primary_identifier: str = '', is_connected: bool = True) -> int:
        """Add a user drive to the database with dual identification support"""
        try:
            with self._get_connection("file_organizer") as conn:
                cursor = conn.cursor()
                
                now = datetime.now().isoformat()
                
                cursor.execute("""
                    INSERT INTO user_drives 
                    (user_id, drive_path, drive_type, drive_label, usb_serial_number,
                     partition_uuid, identifier_type, primary_identifier, 
                     is_connected, last_used, created_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    user_id, drive_path, drive_type, drive_label, usb_serial_number,
                    partition_uuid, identifier_type, primary_identifier, 
                    is_connected, now, now
                ))
                
                drive_id = cursor.lastrowid
                conn.commit()
                audit_logger.info(f"User drive added: {drive_label or primary_identifier} - User: {user_id}")
                return drive_id
                
        except Exception as e:
            audit_logger.error(f"Error adding user drive: {e}")
            raise ModuleDatabaseError(f"Failed to add user drive: {e}")
    
    def get_user_drives(self, user_id: str) -> List[Dict[str, Any]]:
        """Get user drives from the database"""
        try:
            with self._get_connection("file_organizer") as conn:
                cursor = conn.cursor()
                
                cursor.execute("""
                    SELECT id, drive_path, drive_type, drive_label, usb_serial_number,
                           partition_uuid, identifier_type, primary_identifier,
                           is_connected, last_used, created_at
                    FROM user_drives 
                    WHERE user_id = ?
                    ORDER BY last_used DESC
                """, (user_id,))
                
                rows = cursor.fetchall()
                
                return [
                    {
                        'id': row[0],
                        'path': row[1],
                        'type': row[2],
                        'label': row[3],
                        'usb_serial_number': row[4],
                        'partition_uuid': row[5],
                        'identifier_type': row[6],
                        'primary_identifier': row[7],
                        'is_connected': bool(row[8]),
                        'last_used': row[9],
                        'created_at': row[10]
                    }
                    for row in rows
                ]
                
        except Exception as e:
            audit_logger.error(f"Error getting user drives: {e}")
            return []

    def find_drive_by_identifier(self, user_id: str, usb_serial: str = '', partition_uuid: str = '') -> Optional[Dict[str, Any]]:
        """Find a drive by USB serial number or partition UUID"""
        try:
            with self._get_connection("file_organizer") as conn:
                cursor = conn.cursor()
                
                # Try USB serial first
                if usb_serial:
                    cursor.execute("""
                        SELECT id, drive_path, drive_type, drive_label, usb_serial_number,
                               partition_uuid, identifier_type, primary_identifier,
                               is_connected, last_used, created_at
                        FROM user_drives 
                        WHERE user_id = ? AND usb_serial_number = ?
                    """, (user_id, usb_serial))
                    
                    row = cursor.fetchone()
                    if row:
                        return self._row_to_drive_dict(row)
                
                # Try partition UUID
                if partition_uuid:
                    cursor.execute("""
                        SELECT id, drive_path, drive_type, drive_label, usb_serial_number,
                               partition_uuid, identifier_type, primary_identifier,
                               is_connected, last_used, created_at
                        FROM user_drives 
                        WHERE user_id = ? AND partition_uuid = ?
                    """, (user_id, partition_uuid))
                    
                    row = cursor.fetchone()
                    if row:
                        return self._row_to_drive_dict(row)
                
                return None
                
        except Exception as e:
            audit_logger.error(f"Error finding drive by identifier: {e}")
            return None

    def update_drive_connection_status(self, user_id: str, primary_identifier: str, is_connected: bool, current_path: str = '') -> bool:
        """Update drive connection status and path"""
        try:
            with self._get_connection("file_organizer") as conn:
                cursor = conn.cursor()
                
                if current_path:
                    cursor.execute("""
                        UPDATE user_drives 
                        SET is_connected = ?, drive_path = ?, last_used = ?
                        WHERE user_id = ? AND primary_identifier = ?
                    """, (is_connected, current_path, datetime.now().isoformat(), user_id, primary_identifier))
                else:
                    cursor.execute("""
                        UPDATE user_drives 
                        SET is_connected = ?, last_used = ?
                        WHERE user_id = ? AND primary_identifier = ?
                    """, (is_connected, datetime.now().isoformat(), user_id, primary_identifier))
                
                conn.commit()
                return cursor.rowcount > 0
                
        except Exception as e:
            audit_logger.error(f"Error updating drive connection status: {e}")
            return False

    def _row_to_drive_dict(self, row) -> Dict[str, Any]:
        """Convert database row to drive dictionary"""
        return {
            'id': row[0],
            'path': row[1],
            'type': row[2],
            'label': row[3],
            'usb_serial_number': row[4],
            'partition_uuid': row[5],
            'identifier_type': row[6],
            'primary_identifier': row[7],
            'is_connected': bool(row[8]),
            'last_used': row[9],
            'created_at': row[10]
        }
    
    def store_module_data(self, module_name: str, user_id: str, data_key: str, 
                         data_value: Any, data_type: str = 'json') -> bool:
        """Store module-specific data"""
        validated_module = self._validate_module_name(module_name)
        
        # Serialize data value
        if data_type == 'json':
            serialized_value = json.dumps(data_value, ensure_ascii=False)
        else:
            serialized_value = str(data_value)
        
        try:
            with self._get_connection(validated_module) as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    INSERT OR REPLACE INTO module_data 
                    (user_id, data_key, data_value, data_type, updated_at)
                    VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
                """, (user_id, data_key, serialized_value, data_type))
                conn.commit()
                
                return True
                
        except Exception as e:
            security_logger.error(f"Failed to store module data: {e}")
            return False
    
    def get_module_data(self, module_name: str, user_id: str, data_key: str, 
                       default_value: Any = None) -> Any:
        """Get module-specific data"""
        validated_module = self._validate_module_name(module_name)
        
        try:
            with self._get_connection(validated_module) as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT data_value, data_type FROM module_data 
                    WHERE user_id = ? AND data_key = ?
                """, (user_id, data_key))
                
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
    
    def close(self):
        """Close database service gracefully"""
        audit_logger.info("ModuleDatabaseService closed") 