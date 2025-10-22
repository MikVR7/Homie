#!/usr/bin/env python3
"""
File Organizer Data Models

Dataclasses representing the database schema for the File Organizer module.
"""

from dataclasses import dataclass
from datetime import datetime
from typing import Optional, List


@dataclass
class DriveClientMount:
    """
    Represents a mount point for a drive on a specific client
    
    Attributes:
        id: Unique identifier (UUID)
        drive_id: Reference to the drive
        client_id: Client/laptop identifier
        mount_point: Local mount path on this client
        last_seen_at: Last time this mount was detected
        is_available: Whether this mount is currently accessible
    """
    id: str
    drive_id: str
    client_id: str
    mount_point: str
    last_seen_at: datetime
    is_available: bool
    
    @classmethod
    def from_db_row(cls, row) -> 'DriveClientMount':
        """Create DriveClientMount instance from database row"""
        return cls(
            id=row['id'],
            drive_id=row['drive_id'],
            client_id=row['client_id'],
            mount_point=row['mount_point'],
            last_seen_at=datetime.fromisoformat(row['last_seen_at']),
            is_available=bool(row['is_available'])
        )


@dataclass
class Drive:
    """
    Represents a physical or cloud drive/mount point
    
    Attributes:
        id: Unique identifier (UUID)
        user_id: User who owns this drive mapping
        unique_identifier: Hardware/cloud identifier (e.g., UUID, serial number)
        mount_point: Current mount path (deprecated - use client_mounts)
        volume_label: Human-readable drive label
        drive_type: Type of drive ('internal', 'usb', 'cloud')
        cloud_provider: Cloud service name ('onedrive', 'dropbox', 'google_drive', None)
        is_available: Whether the drive is currently accessible (deprecated - use client_mounts)
        last_seen_at: Last time the drive was detected
        created_at: When this drive was first registered
        client_mounts: List of mount points per client (populated when joined)
    """
    id: str
    user_id: str
    unique_identifier: str
    mount_point: str
    volume_label: Optional[str]
    drive_type: str
    cloud_provider: Optional[str]
    is_available: bool
    last_seen_at: datetime
    created_at: datetime
    client_mounts: Optional[List[DriveClientMount]] = None
    
    @classmethod
    def from_db_row(cls, row) -> 'Drive':
        """Create Drive instance from database row"""
        return cls(
            id=row['id'],
            user_id=row['user_id'],
            unique_identifier=row['unique_identifier'],
            mount_point=row['mount_point'],
            volume_label=row['volume_label'],
            drive_type=row['drive_type'],
            cloud_provider=row['cloud_provider'],
            is_available=bool(row['is_available']),
            last_seen_at=datetime.fromisoformat(row['last_seen_at']),
            created_at=datetime.fromisoformat(row['created_at']),
            client_mounts=None  # Populated separately when needed
        )


@dataclass
class Destination:
    """
    Represents a learned destination folder for file organization
    
    Attributes:
        id: Unique identifier (UUID)
        user_id: User who uses this destination
        path: Full path to the destination folder
        category: File category this destination is used for (e.g., 'invoices', 'receipts')
        drive_id: Reference to the drive this path is on (for portability)
        created_at: When this destination was first learned
        last_used_at: Last time files were organized to this destination
        usage_count: Number of times this destination has been used
        is_active: Whether this destination is still valid/preferred
    """
    id: str
    user_id: str
    path: str
    category: str
    drive_id: Optional[str]
    created_at: datetime
    last_used_at: Optional[datetime]
    usage_count: int
    is_active: bool
    
    @classmethod
    def from_db_row(cls, row) -> 'Destination':
        """Create Destination instance from database row"""
        return cls(
            id=row['id'],
            user_id=row['user_id'],
            path=row['path'],
            category=row['category'],
            drive_id=row['drive_id'],
            created_at=datetime.fromisoformat(row['created_at']),
            last_used_at=datetime.fromisoformat(row['last_used_at']) if row['last_used_at'] else None,
            usage_count=int(row['usage_count']),
            is_active=bool(row['is_active'])
        )


@dataclass
class DestinationUsage:
    """
    Tracks individual usage events for destinations
    
    Attributes:
        id: Unique identifier (UUID)
        destination_id: Reference to the destination used
        used_at: Timestamp of this usage
        file_count: Number of files organized in this operation
        operation_type: Type of operation ('move', 'copy')
    """
    id: str
    destination_id: str
    used_at: datetime
    file_count: int
    operation_type: Optional[str]
    
    @classmethod
    def from_db_row(cls, row) -> 'DestinationUsage':
        """Create DestinationUsage instance from database row"""
        return cls(
            id=row['id'],
            destination_id=row['destination_id'],
            used_at=datetime.fromisoformat(row['used_at']),
            file_count=int(row['file_count']),
            operation_type=row['operation_type']
        )
