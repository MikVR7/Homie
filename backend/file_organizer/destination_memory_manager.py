#!/usr/bin/env python3
"""
DestinationMemoryManager

Handles all destination-related operations for the File Organizer.

Responsibilities:
- Manage destination CRUD operations
- Track destination usage and analytics
- Auto-capture destinations from file operations
- Extract categories from paths
- Integrate with drives for path portability
"""

import logging
import sqlite3
import uuid
from datetime import datetime
from pathlib import Path
from typing import List, Optional, Dict, Any

from .models import Destination, DestinationUsage

logger = logging.getLogger("DestinationMemoryManager")


class DestinationMemoryManager:
    """Manages destination learning and retrieval for file organization."""

    def __init__(self, db_path: Path):
        """
        Initialize the DestinationMemoryManager.
        
        Args:
            db_path: Path to the SQLite database file
        """
        self.db_path = db_path

    def _get_db_connection(self) -> sqlite3.Connection:
        """
        Create and return a database connection.
        
        Returns:
            SQLite connection with row factory configured
        """
        conn = sqlite3.connect(str(self.db_path), check_same_thread=False)
        conn.row_factory = sqlite3.Row
        return conn

    def get_destinations(self, user_id: str) -> List[Destination]:
        """
        Retrieve all active destinations for a user.
        
        Args:
            user_id: User identifier
            
        Returns:
            List of Destination objects ordered by usage
        """
        try:
            with self._get_db_connection() as conn:
                cursor = conn.execute("""
                    SELECT 
                        d.id, d.user_id, d.path, d.category, d.drive_id,
                        d.created_at, d.last_used_at, d.usage_count, d.is_active
                    FROM destinations d
                    WHERE d.user_id = ? AND d.is_active = 1
                    ORDER BY d.usage_count DESC, d.last_used_at DESC
                """, (user_id,))
                
                destinations = []
                for row in cursor.fetchall():
                    destinations.append(Destination.from_db_row(row))
                
                logger.debug(f"Retrieved {len(destinations)} destinations for user {user_id}")
                return destinations
                
        except Exception as e:
            logger.error(f"Error retrieving destinations for user {user_id}: {e}")
            return []

    def add_destination(
        self, 
        user_id: str, 
        path: str, 
        category: str, 
        drive_id: Optional[str] = None
    ) -> Optional[Destination]:
        """
        Manually add a new destination.
        
        Args:
            user_id: User identifier
            path: Destination folder path
            category: File category for this destination
            drive_id: Optional drive identifier
            
        Returns:
            Created or existing Destination object, None on error
        """
        try:
            # Validate path format
            if not path or not isinstance(path, str):
                logger.error(f"Invalid path format: {path}")
                return None
            
            # Normalize path
            normalized_path = str(Path(path).resolve())
            
            with self._get_db_connection() as conn:
                # Check for existing destination
                cursor = conn.execute("""
                    SELECT id, user_id, path, category, drive_id,
                           created_at, last_used_at, usage_count, is_active
                    FROM destinations
                    WHERE user_id = ? AND path = ?
                """, (user_id, normalized_path))
                
                existing = cursor.fetchone()
                if existing:
                    logger.info(f"Destination already exists: {normalized_path}")
                    return Destination.from_db_row(existing)
                
                # Create new destination
                destination_id = str(uuid.uuid4())
                now = datetime.now().isoformat()
                
                conn.execute("""
                    INSERT INTO destinations 
                    (id, user_id, path, category, drive_id, created_at, last_used_at, usage_count, is_active)
                    VALUES (?, ?, ?, ?, ?, ?, ?, 0, 1)
                """, (destination_id, user_id, normalized_path, category, drive_id, now, None))
                
                conn.commit()
                
                # Retrieve and return the created destination
                cursor = conn.execute("""
                    SELECT id, user_id, path, category, drive_id,
                           created_at, last_used_at, usage_count, is_active
                    FROM destinations
                    WHERE id = ?
                """, (destination_id,))
                
                row = cursor.fetchone()
                destination = Destination.from_db_row(row)
                
                logger.info(f"Added destination: {normalized_path} (category: {category})")
                return destination
                
        except Exception as e:
            logger.error(f"Error adding destination {path}: {e}")
            return None

    def remove_destination(self, user_id: str, destination_id: str) -> bool:
        """
        Mark a destination as inactive (soft delete).
        
        Args:
            user_id: User identifier
            destination_id: Destination UUID
            
        Returns:
            True if successful, False otherwise
        """
        try:
            with self._get_db_connection() as conn:
                cursor = conn.execute("""
                    UPDATE destinations
                    SET is_active = 0
                    WHERE id = ? AND user_id = ?
                """, (destination_id, user_id))
                
                conn.commit()
                
                if cursor.rowcount > 0:
                    logger.info(f"Removed destination: {destination_id}")
                    return True
                else:
                    logger.warning(f"Destination not found: {destination_id}")
                    return False
                    
        except Exception as e:
            logger.error(f"Error removing destination {destination_id}: {e}")
            return False

    def get_destinations_by_category(self, user_id: str, category: str) -> List[Destination]:
        """
        Get all active destinations for a specific category.
        
        Args:
            user_id: User identifier
            category: File category (case-insensitive)
            
        Returns:
            List of Destination objects ordered by usage
        """
        try:
            with self._get_db_connection() as conn:
                cursor = conn.execute("""
                    SELECT 
                        id, user_id, path, category, drive_id,
                        created_at, last_used_at, usage_count, is_active
                    FROM destinations
                    WHERE user_id = ? AND LOWER(category) = LOWER(?) AND is_active = 1
                    ORDER BY usage_count DESC, last_used_at DESC
                """, (user_id, category))
                
                destinations = []
                for row in cursor.fetchall():
                    destinations.append(Destination.from_db_row(row))
                
                logger.debug(f"Retrieved {len(destinations)} destinations for category '{category}'")
                return destinations
                
        except Exception as e:
            logger.error(f"Error retrieving destinations for category {category}: {e}")
            return []

    def auto_capture_destinations(
        self, 
        user_id: str, 
        operations: List[Dict[str, Any]]
    ) -> List[Destination]:
        """
        Extract and capture destination paths from file operations.
        
        Args:
            user_id: User identifier
            operations: List of file operation dictionaries with 'dest' or 'destination' keys
            
        Returns:
            List of newly captured Destination objects
        """
        try:
            newly_captured = []
            unique_paths = set()
            
            # Extract unique destination paths
            for op in operations:
                dest_path = op.get('dest') or op.get('destination')
                if dest_path:
                    # Get the parent directory (the destination folder)
                    try:
                        folder_path = str(Path(dest_path).parent.resolve())
                        unique_paths.add(folder_path)
                    except Exception as e:
                        logger.warning(f"Could not extract folder from path {dest_path}: {e}")
            
            # Process each unique destination path
            for path in unique_paths:
                try:
                    # Check if destination already exists
                    with self._get_db_connection() as conn:
                        cursor = conn.execute("""
                            SELECT id FROM destinations
                            WHERE user_id = ? AND path = ?
                        """, (user_id, path))
                        
                        if cursor.fetchone():
                            logger.debug(f"Destination already exists: {path}")
                            continue
                    
                    # Extract category from path
                    category = self.extract_category_from_path(path)
                    
                    # Determine drive_id (placeholder for now - would integrate with DrivesManager)
                    drive_id = self.get_drive_for_path(path)
                    
                    # Add the destination
                    destination = self.add_destination(user_id, path, category, drive_id)
                    if destination:
                        newly_captured.append(destination)
                        
                except Exception as e:
                    logger.error(f"Error capturing destination {path}: {e}")
            
            if newly_captured:
                logger.info(f"Auto-captured {len(newly_captured)} new destinations")
            
            return newly_captured
            
        except Exception as e:
            logger.error(f"Error in auto_capture_destinations: {e}")
            return []

    def extract_category_from_path(self, path: str) -> str:
        """
        Extract category from path using the last folder name.
        
        Args:
            path: File system path
            
        Returns:
            Category name or "Uncategorized"
            
        Examples:
            "/home/user/Videos/Movies" -> "Movies"
            "/home/user/Documents/Work/Projects" -> "Projects"
            "/home/user/Documents/" -> "Documents"
        """
        try:
            if not path:
                return "Uncategorized"
            
            # Normalize and remove trailing slashes
            normalized = Path(path).resolve()
            
            # Get the last folder name
            folder_name = normalized.name
            
            if folder_name and folder_name != '/':
                # Clean up the name (capitalize first letter)
                category = folder_name.replace('_', ' ').replace('-', ' ')
                return category.title()
            
            return "Uncategorized"
            
        except Exception as e:
            logger.warning(f"Could not extract category from path {path}: {e}")
            return "Uncategorized"

    def get_drive_for_path(self, path: str) -> Optional[str]:
        """
        Determine the drive_id for a given path.
        
        This is a placeholder that would integrate with DrivesManager.
        For now, returns None (internal drive).
        
        Args:
            path: File system path
            
        Returns:
            Drive UUID or None
        """
        # TODO: Integrate with DrivesManager to detect:
        # - USB drives (paths starting with /media, /mnt)
        # - Cloud drives (OneDrive, Dropbox, Google Drive paths)
        # - Network drives (SMB, NFS mounts)
        
        try:
            path_obj = Path(path)
            path_str = str(path_obj.resolve())
            
            # Simple heuristics for common mount points
            if '/media/' in path_str or '/mnt/' in path_str:
                logger.debug(f"Path appears to be on external drive: {path_str}")
                # Would query drives table here
                return None
            
            # Check for common cloud drive paths
            cloud_indicators = ['Dropbox', 'OneDrive', 'Google Drive', 'iCloud']
            for indicator in cloud_indicators:
                if indicator in path_str:
                    logger.debug(f"Path appears to be on cloud drive: {path_str}")
                    # Would query drives table here
                    return None
            
            return None  # Internal/default drive
            
        except Exception as e:
            logger.warning(f"Error determining drive for path {path}: {e}")
            return None

    def update_usage(
        self, 
        destination_id: str, 
        file_count: int = 1, 
        operation_type: str = "move"
    ) -> bool:
        """
        Update destination usage statistics.
        
        Args:
            destination_id: Destination UUID
            file_count: Number of files in this operation
            operation_type: Type of operation ('move', 'copy')
            
        Returns:
            True if successful, False otherwise
        """
        try:
            now = datetime.now().isoformat()
            
            with self._get_db_connection() as conn:
                # Update destinations table
                conn.execute("""
                    UPDATE destinations
                    SET usage_count = usage_count + 1,
                        last_used_at = ?
                    WHERE id = ?
                """, (now, destination_id))
                
                # Insert usage record
                usage_id = str(uuid.uuid4())
                conn.execute("""
                    INSERT INTO destination_usage 
                    (id, destination_id, used_at, file_count, operation_type)
                    VALUES (?, ?, ?, ?, ?)
                """, (usage_id, destination_id, now, file_count, operation_type))
                
                conn.commit()
                
                logger.debug(f"Updated usage for destination {destination_id}: {file_count} files")
                return True
                
        except Exception as e:
            logger.error(f"Error updating usage for destination {destination_id}: {e}")
            return False

    def get_usage_analytics(self, user_id: str) -> Dict[str, Any]:
        """
        Get usage analytics for a user's destinations.
        
        Args:
            user_id: User identifier
            
        Returns:
            Dictionary with analytics data
        """
        try:
            with self._get_db_connection() as conn:
                # Overall stats
                cursor = conn.execute("""
                    SELECT 
                        COUNT(DISTINCT d.id) as total_destinations,
                        COUNT(DISTINCT d.category) as total_categories,
                        SUM(d.usage_count) as total_uses,
                        MAX(d.last_used_at) as last_activity
                    FROM destinations d
                    WHERE d.user_id = ? AND d.is_active = 1
                """, (user_id,))
                
                overall = dict(cursor.fetchone())
                
                # By category
                cursor = conn.execute("""
                    SELECT 
                        d.category,
                        COUNT(d.id) as destination_count,
                        SUM(d.usage_count) as total_uses
                    FROM destinations d
                    WHERE d.user_id = ? AND d.is_active = 1
                    GROUP BY d.category
                    ORDER BY total_uses DESC
                """, (user_id,))
                
                by_category = [dict(row) for row in cursor.fetchall()]
                
                # Most used destinations
                cursor = conn.execute("""
                    SELECT 
                        d.path,
                        d.category,
                        d.usage_count,
                        d.last_used_at
                    FROM destinations d
                    WHERE d.user_id = ? AND d.is_active = 1
                    ORDER BY d.usage_count DESC, d.last_used_at DESC
                    LIMIT 10
                """, (user_id,))
                
                most_used = [dict(row) for row in cursor.fetchall()]
                
                return {
                    'overall': overall,
                    'by_category': by_category,
                    'most_used': most_used
                }
                
        except Exception as e:
            logger.error(f"Error getting usage analytics: {e}")
            return {
                'overall': {},
                'by_category': [],
                'most_used': []
            }
