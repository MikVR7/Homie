#!/usr/bin/env python3
"""
DriveManager

Handles drive tracking across multiple frontend clients.

ARCHITECTURE:
- Backend does NOT detect drives (it's on a server)
- Multiple frontend clients detect drives locally and report to backend
- Backend tracks drives across all clients using unique identifiers
- Same drive recognized across different clients (e.g., USB moved between laptops)

Responsibilities:
- Register drives reported by frontend clients
- Track drive availability per client
- Match drives by unique identifier across clients
- Handle USB drive mobility between laptops
- Handle shared cloud storage across multiple clients
"""

import logging
import sqlite3
import uuid
from datetime import datetime
from pathlib import Path
from typing import List, Optional, Dict, Any

from .models import Drive, DriveClientMount

logger = logging.getLogger("DriveManager")


class DriveManager:
    """Manages drive tracking across multiple frontend clients."""

    def __init__(self, db_path: Path):
        """
        Initialize the DriveManager.
        
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

    def get_drives(self, user_id: str) -> List[Drive]:
        """
        Retrieve all known drives for a user across ALL client devices.
        
        Args:
            user_id: User identifier
            
        Returns:
            List of Drive objects ordered by last_seen_at DESC
        """
        try:
            with self._get_db_connection() as conn:
                cursor = conn.execute("""
                    SELECT 
                        id, user_id, unique_identifier, mount_point, volume_label,
                        drive_type, cloud_provider, is_available, last_seen_at, created_at
                    FROM drives
                    WHERE user_id = ?
                    ORDER BY last_seen_at DESC
                """, (user_id,))
                
                drives = []
                for row in cursor.fetchall():
                    drive = Drive.from_db_row(row)
                    
                    # Load client mounts for this drive
                    mount_cursor = conn.execute("""
                        SELECT id, drive_id, client_id, mount_point, last_seen_at, is_available
                        FROM drive_client_mounts
                        WHERE drive_id = ?
                        ORDER BY last_seen_at DESC
                    """, (drive.id,))
                    
                    drive.client_mounts = []
                    for mount_row in mount_cursor.fetchall():
                        mount = DriveClientMount.from_db_row(mount_row)
                        drive.client_mounts.append(mount)
                    
                    drives.append(drive)
                
                logger.debug(f"Retrieved {len(drives)} drives for user {user_id}")
                return drives
                
        except Exception as e:
            logger.error(f"Error retrieving drives for user {user_id}: {e}")
            return []

    def register_drive(
        self, 
        user_id: str, 
        drive_info: Dict[str, Any], 
        client_id: str
    ) -> Optional[Drive]:
        """
        Register or update a drive reported by a frontend client.
        
        This is the PRIMARY method for drive registration from frontends.
        
        Args:
            user_id: User identifier
            drive_info: Dictionary containing:
                - unique_identifier: Hardware/cloud identifier (REQUIRED)
                - mount_point: Local mount path on this client (REQUIRED)
                - volume_label: Human-readable label (optional)
                - drive_type: 'internal', 'usb', 'cloud' (REQUIRED)
                - cloud_provider: 'onedrive', 'dropbox', etc. (optional)
            client_id: Client/laptop identifier reporting this drive
            
        Returns:
            Drive object if successful, None on error
            
        Drive Matching Logic:
        - Checks if drive exists by unique_identifier
        - If exists: Updates mount for this client
        - If new: Creates new drive record
        """
        try:
            # Validate required fields
            unique_identifier = drive_info.get('unique_identifier')
            mount_point = drive_info.get('mount_point')
            drive_type = drive_info.get('drive_type')
            
            if not unique_identifier or not mount_point or not drive_type:
                logger.error(f"Missing required fields in drive_info: {drive_info}")
                return None
            
            volume_label = drive_info.get('volume_label')
            cloud_provider = drive_info.get('cloud_provider')
            now = datetime.now().isoformat()
            
            with self._get_db_connection() as conn:
                # Check if drive already exists by unique_identifier
                existing_drive = self.match_drive_by_identifier(user_id, unique_identifier)
                
                if existing_drive:
                    # Drive exists - update it
                    drive_id = existing_drive.id
                    
                    # Update drive record
                    conn.execute("""
                        UPDATE drives
                        SET mount_point = ?,
                            volume_label = ?,
                            is_available = 1,
                            last_seen_at = ?
                        WHERE id = ?
                    """, (mount_point, volume_label, now, drive_id))
                    
                    logger.info(f"Updated existing drive {drive_id} ({unique_identifier}) from client {client_id}")
                    
                else:
                    # New drive - create it
                    drive_id = str(uuid.uuid4())
                    
                    conn.execute("""
                        INSERT INTO drives 
                        (id, user_id, unique_identifier, mount_point, volume_label, 
                         drive_type, cloud_provider, is_available, last_seen_at, created_at)
                        VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
                    """, (drive_id, user_id, unique_identifier, mount_point, volume_label,
                          drive_type, cloud_provider, now, now))
                    
                    logger.info(f"Created new drive {drive_id} ({unique_identifier}) from client {client_id}")
                
                # Update or create client mount
                mount_id = str(uuid.uuid4())
                conn.execute("""
                    INSERT INTO drive_client_mounts 
                    (id, drive_id, client_id, mount_point, last_seen_at, is_available)
                    VALUES (?, ?, ?, ?, ?, 1)
                    ON CONFLICT(drive_id, client_id) DO UPDATE SET
                        mount_point = excluded.mount_point,
                        last_seen_at = excluded.last_seen_at,
                        is_available = 1
                """, (mount_id, drive_id, client_id, mount_point, now))
                
                logger.info(f"Updated mount for drive {drive_id} on client {client_id}: {mount_point}")
                
                conn.commit()
                
                # Retrieve and return the drive
                cursor = conn.execute("""
                    SELECT id, user_id, unique_identifier, mount_point, volume_label,
                           drive_type, cloud_provider, is_available, last_seen_at, created_at
                    FROM drives
                    WHERE id = ?
                """, (drive_id,))
                
                row = cursor.fetchone()
                if row:
                    drive = Drive.from_db_row(row)
                    
                    # Load client mounts
                    mount_cursor = conn.execute("""
                        SELECT id, drive_id, client_id, mount_point, last_seen_at, is_available
                        FROM drive_client_mounts
                        WHERE drive_id = ?
                    """, (drive_id,))
                    
                    drive.client_mounts = []
                    for mount_row in mount_cursor.fetchall():
                        mount = DriveClientMount.from_db_row(mount_row)
                        drive.client_mounts.append(mount)
                    
                    return drive
                
                return None
                
        except Exception as e:
            logger.error(f"Error registering drive: {e}")
            return None

    def update_drive_availability(
        self, 
        user_id: str, 
        unique_identifier: str, 
        is_available: bool, 
        client_id: str
    ) -> bool:
        """
        Update the availability status for a drive on a specific client.
        
        Args:
            user_id: User identifier
            unique_identifier: Hardware/cloud identifier
            is_available: Whether the drive is currently accessible
            client_id: Client/laptop identifier reporting the change
            
        Returns:
            True if successful, False otherwise
            
        Note: Drive may be unavailable on one client but available on another
        """
        try:
            now = datetime.now().isoformat()
            
            # Find the drive
            drive = self.match_drive_by_identifier(user_id, unique_identifier)
            if not drive:
                logger.warning(f"Drive not found: {unique_identifier}")
                return False
            
            with self._get_db_connection() as conn:
                # Update client mount availability
                cursor = conn.execute("""
                    UPDATE drive_client_mounts
                    SET is_available = ?,
                        last_seen_at = ?
                    WHERE drive_id = ? AND client_id = ?
                """, (1 if is_available else 0, now, drive.id, client_id))
                
                if cursor.rowcount == 0:
                    logger.warning(f"No mount found for drive {drive.id} on client {client_id}")
                    return False
                
                # Update drive's overall availability and last_seen_at
                # Drive is available if ANY client has it available
                cursor = conn.execute("""
                    SELECT COUNT(*) as available_count
                    FROM drive_client_mounts
                    WHERE drive_id = ? AND is_available = 1
                """, (drive.id,))
                
                available_count = cursor.fetchone()['available_count']
                drive_available = available_count > 0
                
                conn.execute("""
                    UPDATE drives
                    SET is_available = ?,
                        last_seen_at = ?
                    WHERE id = ?
                """, (1 if drive_available else 0, now, drive.id))
                
                conn.commit()
                
                status = "available" if is_available else "unavailable"
                logger.info(f"Drive {drive.id} ({unique_identifier}) marked {status} on client {client_id}")
                
                return True
                
        except Exception as e:
            logger.error(f"Error updating drive availability: {e}")
            return False

    def match_drive_by_identifier(
        self, 
        user_id: str, 
        unique_identifier: str
    ) -> Optional[Drive]:
        """
        Find a drive by its unique identifier.
        
        This is the PRIMARY method for recognizing drives across clients.
        
        Args:
            user_id: User identifier
            unique_identifier: Hardware/cloud identifier
            
        Returns:
            Drive object if found, None otherwise
        """
        try:
            with self._get_db_connection() as conn:
                cursor = conn.execute("""
                    SELECT id, user_id, unique_identifier, mount_point, volume_label,
                           drive_type, cloud_provider, is_available, last_seen_at, created_at
                    FROM drives
                    WHERE user_id = ? AND unique_identifier = ?
                """, (user_id, unique_identifier))
                
                row = cursor.fetchone()
                if row:
                    drive = Drive.from_db_row(row)
                    
                    # Load client mounts
                    mount_cursor = conn.execute("""
                        SELECT id, drive_id, client_id, mount_point, last_seen_at, is_available
                        FROM drive_client_mounts
                        WHERE drive_id = ?
                    """, (drive.id,))
                    
                    drive.client_mounts = []
                    for mount_row in mount_cursor.fetchall():
                        mount = DriveClientMount.from_db_row(mount_row)
                        drive.client_mounts.append(mount)
                    
                    logger.debug(f"Matched drive {drive.id} by identifier {unique_identifier}")
                    return drive
                
                logger.debug(f"No drive found with identifier {unique_identifier}")
                return None
                
        except Exception as e:
            logger.error(f"Error matching drive by identifier: {e}")
            return None

    def get_drive_for_path(
        self, 
        user_id: str, 
        path: str, 
        client_id: str
    ) -> Optional[Drive]:
        """
        Determine which drive contains the given path on a specific client.
        
        Args:
            user_id: User identifier
            path: File system path
            client_id: Client/laptop identifier
            
        Returns:
            Drive object if found, None otherwise
            
        Note: Same drive may have different mount points on different clients
        """
        try:
            path_str = str(Path(path).resolve())
            
            with self._get_db_connection() as conn:
                # Find drive with longest matching mount point for this client
                cursor = conn.execute("""
                    SELECT 
                        d.id, d.user_id, d.unique_identifier, d.mount_point, d.volume_label,
                        d.drive_type, d.cloud_provider, d.is_available, d.last_seen_at, d.created_at,
                        m.mount_point as client_mount_point
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
                    drive = Drive.from_db_row(row)
                    client_mount = row['client_mount_point']
                    
                    logger.debug(f"Path {path_str} matched to drive {drive.id} (mount: {client_mount})")
                    return drive
                
                logger.debug(f"No drive found for path {path_str} on client {client_id}")
                return None
                
        except Exception as e:
            logger.error(f"Error getting drive for path: {e}")
            return None

    def get_shared_cloud_drives(
        self, 
        user_id: str, 
        cloud_provider: str
    ) -> List[Drive]:
        """
        Get all drives for a specific cloud provider.
        
        Multiple clients may report the same cloud storage.
        Uses unique_identifier to deduplicate.
        
        Args:
            user_id: User identifier
            cloud_provider: Cloud provider name ('onedrive', 'dropbox', 'google_drive')
            
        Returns:
            List of cloud Drive objects
        """
        try:
            with self._get_db_connection() as conn:
                cursor = conn.execute("""
                    SELECT 
                        id, user_id, unique_identifier, mount_point, volume_label,
                        drive_type, cloud_provider, is_available, last_seen_at, created_at
                    FROM drives
                    WHERE user_id = ? 
                      AND drive_type = 'cloud'
                      AND LOWER(cloud_provider) = LOWER(?)
                    ORDER BY last_seen_at DESC
                """, (user_id, cloud_provider))
                
                drives = []
                for row in cursor.fetchall():
                    drive = Drive.from_db_row(row)
                    
                    # Load client mounts
                    mount_cursor = conn.execute("""
                        SELECT id, drive_id, client_id, mount_point, last_seen_at, is_available
                        FROM drive_client_mounts
                        WHERE drive_id = ?
                        ORDER BY last_seen_at DESC
                    """, (drive.id,))
                    
                    drive.client_mounts = []
                    for mount_row in mount_cursor.fetchall():
                        mount = DriveClientMount.from_db_row(mount_row)
                        drive.client_mounts.append(mount)
                    
                    drives.append(drive)
                
                logger.debug(f"Retrieved {len(drives)} {cloud_provider} drives for user {user_id}")
                return drives
                
        except Exception as e:
            logger.error(f"Error retrieving cloud drives: {e}")
            return []

    def get_client_drives(self, user_id: str, client_id: str) -> List[Drive]:
        """
        Get all drives currently available on a specific client.
        
        Args:
            user_id: User identifier
            client_id: Client/laptop identifier
            
        Returns:
            List of Drive objects available on this client
        """
        try:
            with self._get_db_connection() as conn:
                cursor = conn.execute("""
                    SELECT DISTINCT
                        d.id, d.user_id, d.unique_identifier, d.mount_point, d.volume_label,
                        d.drive_type, d.cloud_provider, d.is_available, d.last_seen_at, d.created_at
                    FROM drives d
                    JOIN drive_client_mounts m ON d.id = m.drive_id
                    WHERE d.user_id = ?
                      AND m.client_id = ?
                      AND m.is_available = 1
                    ORDER BY d.last_seen_at DESC
                """, (user_id, client_id))
                
                drives = []
                for row in cursor.fetchall():
                    drive = Drive.from_db_row(row)
                    
                    # Load client mounts (just for this client)
                    mount_cursor = conn.execute("""
                        SELECT id, drive_id, client_id, mount_point, last_seen_at, is_available
                        FROM drive_client_mounts
                        WHERE drive_id = ? AND client_id = ?
                    """, (drive.id, client_id))
                    
                    drive.client_mounts = []
                    for mount_row in mount_cursor.fetchall():
                        mount = DriveClientMount.from_db_row(mount_row)
                        drive.client_mounts.append(mount)
                    
                    drives.append(drive)
                
                logger.debug(f"Retrieved {len(drives)} drives for client {client_id}")
                return drives
                
        except Exception as e:
            logger.error(f"Error retrieving client drives: {e}")
            return []
