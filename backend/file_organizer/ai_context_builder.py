#!/usr/bin/env python3
"""
AIContextBuilder

Prepares destination and drive context for AI requests.

Responsibilities:
- Build comprehensive context from DestinationMemoryManager and DriveManager
- Format context for AI prompts in natural language
- Include drive space, availability, and usage statistics
- Provide instructions for AI to prefer known destinations
"""

import logging
import os
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any, Optional

from .destination_memory_manager import DestinationMemoryManager
from .drive_manager import DriveManager

logger = logging.getLogger("AIContextBuilder")


class AIContextBuilder:
    """Builds context for AI requests including destinations and drives."""

    def __init__(
        self, 
        destination_manager: DestinationMemoryManager,
        drive_manager: DriveManager
    ):
        """
        Initialize the AIContextBuilder.
        
        Args:
            destination_manager: DestinationMemoryManager instance
            drive_manager: DriveManager instance
        """
        self.destination_manager = destination_manager
        self.drive_manager = drive_manager

    def build_context(self, user_id: str, client_id: str) -> Dict[str, Any]:
        """
        Build complete context for AI including destinations and drives.
        
        Args:
            user_id: User identifier
            client_id: Client/laptop identifier
            
        Returns:
            Dictionary with known_destinations and drives
        """
        try:
            # Get destinations accessible from this client
            destinations = self.destination_manager.get_destinations_for_client(user_id, client_id)
            
            # Get drives for this client
            drives = self.drive_manager.get_client_drives(user_id, client_id)
            
            # Build drive info map
            drive_info_map = {}
            for drive in drives:
                drive_info_map[drive.id] = {
                    'id': drive.id,
                    'type': drive.drive_type,
                    'mount_point': self._get_client_mount_point(drive, client_id),
                    'volume_label': drive.volume_label,
                    'available_space_gb': self._get_available_space(drive, client_id),
                    'is_available': self._is_drive_available_for_client(drive, client_id),
                    'cloud_provider': drive.cloud_provider
                }
            
            # Group destinations by category
            destinations_by_category = {}
            for dest in destinations:
                category = dest.category
                if category not in destinations_by_category:
                    destinations_by_category[category] = []
                
                # Get drive info for this destination
                drive_info = None
                if dest.drive_id and dest.drive_id in drive_info_map:
                    drive_info = drive_info_map[dest.drive_id]
                
                dest_info = {
                    'path': dest.path,
                    'drive_type': drive_info['type'] if drive_info else 'unknown',
                    'drive_label': drive_info['volume_label'] if drive_info else None,
                    'available_space_gb': drive_info['available_space_gb'] if drive_info else None,
                    'is_available': drive_info['is_available'] if drive_info else True,
                    'usage_count': dest.usage_count,
                    'last_used': dest.last_used_at.isoformat() if dest.last_used_at else None,
                    'cloud_provider': drive_info['cloud_provider'] if drive_info else None
                }
                
                destinations_by_category[category].append(dest_info)
            
            # Format known destinations
            known_destinations = []
            for category, paths in destinations_by_category.items():
                # Sort by usage count descending
                paths.sort(key=lambda x: x['usage_count'], reverse=True)
                
                known_destinations.append({
                    'category': category,
                    'paths': paths
                })
            
            # Sort categories by total usage
            known_destinations.sort(
                key=lambda x: sum(p['usage_count'] for p in x['paths']), 
                reverse=True
            )
            
            # Format drives list
            drives_list = list(drive_info_map.values())
            
            return {
                'known_destinations': known_destinations,
                'drives': drives_list
            }
            
        except Exception as e:
            logger.error(f"Error building context: {e}")
            return {
                'known_destinations': [],
                'drives': []
            }

    def format_for_ai_prompt(self, context: Dict[str, Any]) -> str:
        """
        Convert context dict to natural language for AI prompt.
        Optimized for minimal token usage while maintaining readability.
        
        Args:
            context: Context dictionary from build_context()
            
        Returns:
            Formatted string for AI prompt
        """
        try:
            lines = []
            
            # Header - shortened separator
            lines.append("--- DESTINATIONS ---")
            
            known_destinations = context.get('known_destinations', [])
            
            if not known_destinations:
                lines.append("None")
            else:
                # Build drive index map first
                drive_index_map = {}
                drive_counter = 1
                
                # Collect all unique drives used by destinations
                for category_info in known_destinations:
                    for path_info in category_info['paths']:
                        # Find matching drive
                        for drive in context.get('drives', []):
                            if path_info['path'].startswith(drive['mount_point']):
                                if drive['id'] not in drive_index_map:
                                    drive_index_map[drive['id']] = drive_counter
                                    drive_counter += 1
                                break
                
                # List all destinations without category grouping
                for category_info in known_destinations:
                    for path_info in category_info['paths']:
                        path = path_info['path']
                        usage_count = path_info['usage_count']
                        is_available = path_info['is_available']
                        
                        # Find drive index for this path
                        drive_idx = "?"
                        for drive in context.get('drives', []):
                            if path.startswith(drive['mount_point']):
                                drive_idx = drive_index_map.get(drive['id'], "?")
                                break
                        
                        # Compact format: path (drive:id, used:N)
                        status = " [UNAVAILABLE]" if not is_available else ""
                        lines.append(f"{path} (drive:{drive_idx}, used:{usage_count}x){status}")
            
            # Drives section - only include drives referenced by destinations
            lines.append("\n--- DRIVES ---")
            
            # Build map of drive_id to destinations that use it
            drive_usage = {}
            for category_info in known_destinations:
                for path_info in category_info['paths']:
                    # We'll use the index as drive reference
                    pass
            
            # Get unique drives from destinations
            drives = context.get('drives', [])
            used_drives = []
            
            # Only include drives that are actually used by destinations
            for category_info in known_destinations:
                for path_info in category_info['paths']:
                    # Find matching drive by checking if path starts with mount point
                    for drive in drives:
                        if path_info['path'].startswith(drive['mount_point']):
                            if drive not in used_drives:
                                used_drives.append(drive)
                            break
            
            if not used_drives:
                lines.append("None")
            else:
                for idx, drive in enumerate(used_drives, 1):
                    available_space = drive['available_space_gb']
                    volume_label = drive['volume_label']
                    cloud_provider = drive['cloud_provider']
                    
                    # Compact format: id. Name (space GB)
                    if cloud_provider:
                        name = cloud_provider.title()
                    elif volume_label:
                        name = volume_label
                    else:
                        name = drive['type'].title()
                    
                    if available_space is not None:
                        lines.append(f"{idx}. {name} ({available_space:.0f}GB)")
                    else:
                        lines.append(f"{idx}. {name}")
            
            # Instructions - shortened
            lines.append("\n--- INSTRUCTIONS ---")
            lines.append("Prefer known destinations when appropriate.")
            lines.append("Choose based on: availability > space > usage frequency.")
            lines.append("If no match, suggest new destination.")
            
            return "\n".join(lines)
            
        except Exception as e:
            logger.error(f"Error formatting context for AI: {e}")
            return "Error: Could not format context for AI."

    def _get_client_mount_point(self, drive, client_id: str) -> Optional[str]:
        """Get mount point for drive on specific client"""
        if not drive.client_mounts:
            return drive.mount_point
        
        for mount in drive.client_mounts:
            if mount.client_id == client_id:
                return mount.mount_point
        
        return drive.mount_point

    def _is_drive_available_for_client(self, drive, client_id: str) -> bool:
        """Check if drive is available on specific client"""
        if not drive.client_mounts:
            return drive.is_available
        
        for mount in drive.client_mounts:
            if mount.client_id == client_id:
                return mount.is_available
        
        return False

    def _get_available_space(self, drive, client_id: str) -> Optional[float]:
        """
        Get available space on drive in GB.
        
        Args:
            drive: Drive object
            client_id: Client identifier
            
        Returns:
            Available space in GB or None if cannot determine
        """
        try:
            mount_point = self._get_client_mount_point(drive, client_id)
            if not mount_point:
                return None
            
            # Check if mount point exists
            if not os.path.exists(mount_point):
                return None
            
            # Get disk usage
            stat = os.statvfs(mount_point)
            
            # Calculate available space in GB
            available_bytes = stat.f_bavail * stat.f_frsize
            available_gb = available_bytes / (1024 ** 3)
            
            return round(available_gb, 1)
            
        except Exception as e:
            logger.debug(f"Could not get available space for {mount_point}: {e}")
            return None

    def build_context_summary(self, user_id: str, client_id: str) -> str:
        """
        Build a brief summary of context for logging/debugging.
        
        Args:
            user_id: User identifier
            client_id: Client identifier
            
        Returns:
            Brief summary string
        """
        try:
            context = self.build_context(user_id, client_id)
            
            dest_count = sum(len(cat['paths']) for cat in context['known_destinations'])
            category_count = len(context['known_destinations'])
            drive_count = len(context['drives'])
            
            return (
                f"Context: {dest_count} destination(s) in {category_count} categor{'ies' if category_count != 1 else 'y'}, "
                f"{drive_count} drive(s) available"
            )
            
        except Exception as e:
            logger.error(f"Error building context summary: {e}")
            return "Context: Error building summary"
