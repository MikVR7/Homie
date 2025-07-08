"""
Homie Backend Services
Modular business logic for all Homie modules
"""

# File Organizer Service
from .file_organizer import SmartOrganizer, discover_folders

__all__ = ['SmartOrganizer', 'discover_folders'] 