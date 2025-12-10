#!/usr/bin/env python3
"""
Request Models for File Organizer API

Pydantic models for validating incoming API requests with enhanced metadata support.
"""

from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field


class ImageMetadata(BaseModel):
    """Metadata specific to image files"""
    width: Optional[int] = None
    height: Optional[int] = None
    format: Optional[str] = None
    date_taken: Optional[str] = None
    camera_model: Optional[str] = None
    location: Optional[str] = None


class VideoMetadata(BaseModel):
    """Metadata specific to video files"""
    duration: Optional[float] = None
    width: Optional[int] = None
    height: Optional[int] = None
    codec: Optional[str] = None
    bitrate: Optional[int] = None
    fps: Optional[float] = None


class AudioMetadata(BaseModel):
    """Metadata specific to audio files"""
    duration: Optional[float] = None
    artist: Optional[str] = None
    album: Optional[str] = None
    title: Optional[str] = None
    genre: Optional[str] = None
    year: Optional[int] = None
    bitrate: Optional[int] = None


class DocumentMetadata(BaseModel):
    """Metadata specific to document files (PDF, Office)"""
    page_count: Optional[int] = None
    title: Optional[str] = None
    author: Optional[str] = None
    created: Optional[str] = None
    modified: Optional[str] = None


class ArchiveMetadata(BaseModel):
    """Metadata specific to archive files (ZIP, RAR, 7Z, ISO)"""
    archive_type: Optional[str] = None
    contents: Optional[List[str]] = None
    detected_project_type: Optional[str] = None
    contains_executables: Optional[bool] = None
    compressed_size: Optional[int] = None
    uncompressed_size: Optional[int] = None


class SourceCodeMetadata(BaseModel):
    """Metadata specific to source code files"""
    language: Optional[str] = None
    lines_of_code: Optional[int] = None
    has_tests: Optional[bool] = None


class FileMetadata(BaseModel):
    """
    Complete metadata for a file.
    Only ONE of the type-specific metadata objects should be populated.
    """
    size: Optional[int] = None
    last_modified: Optional[str] = None
    created: Optional[str] = None
    extension: Optional[str] = None
    
    # Type-specific metadata (mutually exclusive)
    image: Optional[ImageMetadata] = None
    video: Optional[VideoMetadata] = None
    audio: Optional[AudioMetadata] = None
    document: Optional[DocumentMetadata] = None
    archive: Optional[ArchiveMetadata] = None
    source_code: Optional[SourceCodeMetadata] = None


class FileWithMetadata(BaseModel):
    """A file path with its associated metadata"""
    path: str
    metadata: Optional[FileMetadata] = None


class OrganizeRequest(BaseModel):
    """
    Request model for /api/file-organizer/organize endpoint.
    """
    # File formats
    file_paths: Optional[List[str]] = Field(None, description="Array of file paths (without metadata)")
    files_with_metadata: Optional[List[FileWithMetadata]] = Field(None, description="Array of files with metadata")
    
    # Common fields
    source_path: str = Field(..., description="Source folder path")
    destination_path: str = Field(..., description="Destination root folder path")
    organization_style: Optional[str] = Field("by_type", description="Organization style preference")
    user_id: Optional[str] = Field("dev_user", description="User identifier")
    client_id: Optional[str] = Field("default_client", description="Client/device identifier")
    
    def get_file_list(self) -> List[Dict[str, Any]]:
        """
        Extract file list in a unified format.
        Returns list of dicts with 'path' and optional 'metadata' keys.
        """
        # Priority 1: Files with metadata
        if self.files_with_metadata:
            return [
                {
                    'path': f.path,
                    'metadata': f.metadata.dict() if f.metadata else None
                }
                for f in self.files_with_metadata
            ]
        
        # Priority 2: file_paths array (no metadata)
        if self.file_paths:
            return [{'path': fp, 'metadata': None} for fp in self.file_paths]
        
        return []
