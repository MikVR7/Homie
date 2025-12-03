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
                        d.id, d.user_id, d.path, d.category, d.color, d.drive_id,
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
    
    def _get_existing_colors(self, user_id: str, conn: sqlite3.Connection) -> List[str]:
        """
        Get all colors currently assigned to active destinations for a user.
        
        Args:
            user_id: User identifier
            conn: Database connection
            
        Returns:
            List of hex color codes
        """
        try:
            cursor = conn.execute("""
                SELECT color FROM destinations
                WHERE user_id = ? AND is_active = 1 AND color IS NOT NULL
            """, (user_id,))
            
            colors = [row['color'] for row in cursor.fetchall()]
            return colors
        except Exception as e:
            logger.error(f"Error retrieving existing colors: {e}")
            return []

    def add_destination(
        self, 
        user_id: str, 
        path: str, 
        category: str, 
        client_id: str,
        drive_id: Optional[str] = None,
        color: Optional[str] = None
    ) -> Optional[Destination]:
        """
        Manually add a new destination.
        
        Args:
            user_id: User identifier
            path: Destination folder path
            category: File category for this destination
            client_id: Client/laptop identifier reporting this destination
            drive_id: Optional drive identifier (auto-detected if None)
            color: Optional hex color code (auto-assigned if None)
            
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
            
            # Validate and normalize color if provided
            if color:
                from .color_palette import normalize_hex_color
                color = normalize_hex_color(color)
                if not color:
                    logger.warning(f"Invalid color format provided, will auto-assign")
            
            with self._get_db_connection() as conn:
                # Check for existing destination
                cursor = conn.execute("""
                    SELECT id, user_id, path, category, color, drive_id,
                           created_at, last_used_at, usage_count, is_active
                    FROM destinations
                    WHERE user_id = ? AND path = ?
                """, (user_id, normalized_path))
                
                existing = cursor.fetchone()
                if existing:
                    # If destination exists but is inactive, reactivate it
                    if not existing['is_active']:
                        logger.info(f"Reactivating inactive destination: {normalized_path}")
                        
                        # If color is provided, update it; otherwise keep existing
                        if color:
                            conn.execute("""
                                UPDATE destinations
                                SET is_active = 1, last_used_at = ?, color = ?
                                WHERE id = ?
                            """, (datetime.now().isoformat(), color, existing['id']))
                        else:
                            conn.execute("""
                                UPDATE destinations
                                SET is_active = 1, last_used_at = ?
                                WHERE id = ?
                            """, (datetime.now().isoformat(), existing['id']))
                        
                        conn.commit()
                        
                        # Fetch the updated destination
                        cursor = conn.execute("""
                            SELECT id, user_id, path, category, color, drive_id,
                                   created_at, last_used_at, usage_count, is_active
                            FROM destinations
                            WHERE id = ?
                        """, (existing['id'],))
                        existing = cursor.fetchone()
                    else:
                        logger.info(f"Destination already exists: {normalized_path}")
                    
                    return Destination.from_db_row(existing)
                
                # Auto-detect drive_id if not provided
                if drive_id is None:
                    drive_id = self.get_drive_for_path(user_id, client_id, normalized_path)
                
                # Auto-assign color if not provided
                if not color:
                    existing_colors = self._get_existing_colors(user_id, conn)
                    from .color_palette import assign_color_from_palette
                    color = assign_color_from_palette(existing_colors)
                    logger.debug(f"Auto-assigned color {color} to destination")
                
                # Create new destination
                destination_id = str(uuid.uuid4())
                now = datetime.now().isoformat()
                
                conn.execute("""
                    INSERT INTO destinations 
                    (id, user_id, path, category, color, drive_id, created_at, last_used_at, usage_count, is_active)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, 1)
                """, (destination_id, user_id, normalized_path, category, color, drive_id, now, None))
                
                conn.commit()
                
                # Retrieve and return the created destination
                cursor = conn.execute("""
                    SELECT id, user_id, path, category, color, drive_id,
                           created_at, last_used_at, usage_count, is_active
                    FROM destinations
                    WHERE id = ?
                """, (destination_id,))
                
                row = cursor.fetchone()
                destination = Destination.from_db_row(row)
                
                logger.info(f"Added destination: {normalized_path} (category: {category}, color: {color})")
                return destination
                
        except Exception as e:
            logger.error(f"Error adding destination {path}: {e}")
            return None

    def remove_destination(self, user_id: str, destination_id: str) -> bool:
        """
        Mark a destination as inactive (soft delete).
        Also cascades to deactivate any child destinations under the same path.
        
        Args:
            user_id: User identifier
            destination_id: Destination UUID
            
        Returns:
            True if successful, False otherwise
        """
        try:
            with self._get_db_connection() as conn:
                # First, get the path of the destination being deleted
                cursor = conn.execute("""
                    SELECT path FROM destinations
                    WHERE id = ? AND user_id = ?
                """, (destination_id, user_id))
                
                row = cursor.fetchone()
                if not row:
                    logger.warning(f"Destination not found: {destination_id}")
                    return False
                
                destination_path = row['path']
                
                # Normalize path to ensure consistent matching
                normalized_path = str(Path(destination_path).resolve())
                
                # Deactivate the destination itself
                cursor = conn.execute("""
                    UPDATE destinations
                    SET is_active = 0
                    WHERE id = ? AND user_id = ?
                """, (destination_id, user_id))
                
                # Cascade: deactivate all child destinations (paths that start with this path)
                # Use LIKE with trailing slash to match children only
                cascade_cursor = conn.execute("""
                    UPDATE destinations
                    SET is_active = 0
                    WHERE user_id = ? 
                      AND is_active = 1
                      AND (path LIKE ? OR path LIKE ?)
                """, (user_id, f"{normalized_path}/%", f"{destination_path}/%"))
                
                cascaded_count = cascade_cursor.rowcount
                
                conn.commit()
                
                if cascaded_count > 0:
                    logger.info(f"Removed destination {destination_id} and cascaded to {cascaded_count} child destination(s)")
                else:
                    logger.info(f"Removed destination: {destination_id}")
                
                return True
                    
        except Exception as e:
            logger.error(f"Error removing destination {destination_id}: {e}")
            return False

    def update_destination(
        self,
        user_id: str,
        destination_id: str,
        path: Optional[str] = None,
        category: Optional[str] = None,
        color: Optional[str] = None
    ) -> Optional[Destination]:
        """
        Update an existing destination's properties.
        
        Args:
            user_id: User identifier
            destination_id: Destination UUID
            path: New path (optional)
            category: New category (optional)
            color: New color (optional)
            
        Returns:
            Updated Destination object, None on error
        """
        try:
            # Validate color if provided
            if color:
                from .color_palette import normalize_hex_color
                color = normalize_hex_color(color)
                if not color:
                    logger.warning(f"Invalid color format provided for update")
                    return None
            
            with self._get_db_connection() as conn:
                # Check if destination exists
                cursor = conn.execute("""
                    SELECT id FROM destinations
                    WHERE id = ? AND user_id = ?
                """, (destination_id, user_id))
                
                if not cursor.fetchone():
                    logger.warning(f"Destination not found: {destination_id}")
                    return None
                
                # Build update query dynamically based on provided fields
                update_fields = []
                update_values = []
                
                if path is not None:
                    normalized_path = str(Path(path).resolve())
                    update_fields.append("path = ?")
                    update_values.append(normalized_path)
                
                if category is not None:
                    update_fields.append("category = ?")
                    update_values.append(category)
                
                if color is not None:
                    update_fields.append("color = ?")
                    update_values.append(color)
                
                if not update_fields:
                    logger.warning("No fields to update")
                    return None
                
                # Add destination_id to values for WHERE clause
                update_values.extend([user_id, destination_id])
                
                # Execute update
                update_query = f"""
                    UPDATE destinations
                    SET {', '.join(update_fields)}
                    WHERE user_id = ? AND id = ?
                """
                
                conn.execute(update_query, update_values)
                conn.commit()
                
                # Retrieve and return updated destination
                cursor = conn.execute("""
                    SELECT id, user_id, path, category, color, drive_id,
                           created_at, last_used_at, usage_count, is_active
                    FROM destinations
                    WHERE id = ?
                """, (destination_id,))
                
                row = cursor.fetchone()
                if row:
                    destination = Destination.from_db_row(row)
                    logger.info(f"Updated destination {destination_id}")
                    return destination
                
                return None
                
        except Exception as e:
            logger.error(f"Error updating destination {destination_id}: {e}")
            return None

    def get_destinations_for_client(self, user_id: str, client_id: str) -> List[Destination]:
        """
        Get destinations that are accessible from a specific client.
        
        Filters destinations based on drive availability for that client.
        Cloud storage destinations are accessible from all clients.
        
        Args:
            user_id: User identifier
            client_id: Client/laptop identifier
            
        Returns:
            List of Destination objects accessible from this client
        """
        try:
            with self._get_db_connection() as conn:
                cursor = conn.execute("""
                    SELECT DISTINCT
                        d.id, d.user_id, d.path, d.category, d.color, d.drive_id,
                        d.created_at, d.last_used_at, d.usage_count, d.is_active
                    FROM destinations d
                    LEFT JOIN drives dr ON d.drive_id = dr.id
                    LEFT JOIN drive_client_mounts m ON dr.id = m.drive_id AND m.client_id = ?
                    WHERE d.user_id = ? 
                      AND d.is_active = 1
                      AND (
                          d.drive_id IS NULL  -- No drive (local paths)
                          OR dr.drive_type = 'cloud'  -- Cloud drives accessible from all clients
                          OR m.is_available = 1  -- Drive has mount on this client
                      )
                    ORDER BY d.usage_count DESC, d.last_used_at DESC
                """, (client_id, user_id))
                
                destinations = []
                for row in cursor.fetchall():
                    destinations.append(Destination.from_db_row(row))
                
                logger.debug(f"Retrieved {len(destinations)} destinations for client {client_id}")
                return destinations
                
        except Exception as e:
            logger.error(f"Error retrieving destinations for client {client_id}: {e}")
            return []

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
                        id, user_id, path, category, color, drive_id,
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
        operations: List[Dict[str, Any]],
        client_id: str
    ) -> List[Destination]:
        """
        Extract and capture destination paths from file operations.
        
        Args:
            user_id: User identifier
            operations: List of file operation dictionaries with 'dest' or 'destination' keys
            client_id: Client/laptop identifier reporting these operations
            
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
                    
                    # Determine drive_id using client-specific mount points
                    drive_id = self.get_drive_for_path(user_id, client_id, path)
                    
                    # Add the destination
                    destination = self.add_destination(user_id, path, category, client_id, drive_id)
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

    def get_drive_for_path(self, user_id: str, client_id: str, path: str) -> Optional[str]:
        """
        Determine the drive_id for a given path on a specific client.
        
        Checks client-specific mount points to find which drive contains the path.
        
        Args:
            user_id: User identifier
            client_id: Client/laptop identifier
            path: File system path
            
        Returns:
            Drive UUID or None if no matching drive found
        """
        try:
            path_str = str(Path(path).resolve())
            
            with self._get_db_connection() as conn:
                # Find drive with longest matching mount point for this client
                cursor = conn.execute("""
                    SELECT d.id, m.mount_point
                    FROM drives d
                    JOIN drive_client_mounts m ON d.id = m.drive_id
                    WHERE d.user_id = ?
                      AND m.client_id = ?
                      AND m.is_available = 1
                      AND ? LIKE m.mount_point || '%'
                    ORDER BY LENGTH(m.mount_point) DESC
                    LIMIT 1
                """, (user_id, client_id, path_str))
                
                row = cursor.fetchone()
                if row:
                    drive_id = row['id']
                    mount_point = row['mount_point']
                    logger.debug(f"Path {path_str} matched to drive {drive_id} (mount: {mount_point})")
                    return drive_id
                
                logger.debug(f"No drive found for path {path_str} on client {client_id}")
                return None
            
        except Exception as e:
            logger.error(f"Error determining drive for path {path}: {e}")
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
