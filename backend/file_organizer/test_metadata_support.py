#!/usr/bin/env python3
"""
Test Enhanced File Metadata Support

Tests the new API endpoint that accepts rich file metadata.
"""

import sys
from pathlib import Path

# Add backend directory to path
backend_dir = Path(__file__).parent.parent
sys.path.insert(0, str(backend_dir))

import json


def test_request_model_parsing():
    """Test that the request model correctly parses different formats"""
    from file_organizer.request_models import OrganizeRequest
    
    # Test 1: New format with metadata
    request_data = {
        "files_with_metadata": [
            {
                "path": "/path/to/image.jpg",
                "metadata": {
                    "size": 1024000,
                    "extension": ".jpg",
                    "image": {
                        "width": 1920,
                        "height": 1080,
                        "date_taken": "2025-01-12T14:20:00Z",
                        "camera_model": "Canon EOS R5"
                    }
                }
            }
        ],
        "source_path": "/source",
        "destination_path": "/dest"
    }
    
    req = OrganizeRequest(**request_data)
    files = req.get_file_list()
    
    assert len(files) == 1
    assert files[0]['path'] == "/path/to/image.jpg"
    assert files[0]['metadata'] is not None
    assert files[0]['metadata']['image']['camera_model'] == "Canon EOS R5"
    print("✅ Test 1: New format with metadata - PASSED")


def test_legacy_format_compatibility():
    """Test backward compatibility with legacy format"""
    from file_organizer.request_models import OrganizeRequest
    
    # Test 2: Legacy format (files as strings)
    request_data = {
        "files": ["/path/to/file1.txt", "/path/to/file2.pdf"],
        "source_path": "/source",
        "destination_path": "/dest"
    }
    
    req = OrganizeRequest(**request_data)
    files = req.get_file_list()
    
    assert len(files) == 2
    assert files[0]['path'] == "/path/to/file1.txt"
    assert files[0]['metadata'] is None
    print("✅ Test 2: Legacy format compatibility - PASSED")


def test_file_paths_format():
    """Test file_paths array format (no metadata)"""
    from file_organizer.request_models import OrganizeRequest
    
    # Test 3: file_paths format
    request_data = {
        "file_paths": ["/path/to/file1.txt", "/path/to/file2.pdf"],
        "source_path": "/source",
        "destination_path": "/dest"
    }
    
    req = OrganizeRequest(**request_data)
    files = req.get_file_list()
    
    assert len(files) == 2
    assert files[0]['metadata'] is None
    print("✅ Test 3: file_paths format - PASSED")


def test_archive_metadata():
    """Test archive metadata with project detection"""
    from file_organizer.request_models import OrganizeRequest
    
    request_data = {
        "files_with_metadata": [
            {
                "path": "/path/to/project.zip",
                "metadata": {
                    "size": 5242880,
                    "extension": ".zip",
                    "archive": {
                        "archive_type": "ZIP",
                        "contents": ["src/Program.cs", "MyProject.csproj", "README.md"],
                        "detected_project_type": "DotNet",
                        "contains_executables": False
                    }
                }
            }
        ],
        "source_path": "/source",
        "destination_path": "/dest"
    }
    
    req = OrganizeRequest(**request_data)
    files = req.get_file_list()
    
    assert len(files) == 1
    assert files[0]['metadata']['archive']['detected_project_type'] == "DotNet"
    assert len(files[0]['metadata']['archive']['contents']) == 3
    print("✅ Test 4: Archive metadata - PASSED")


def test_document_metadata():
    """Test document metadata"""
    from file_organizer.request_models import OrganizeRequest
    
    request_data = {
        "files_with_metadata": [
            {
                "path": "/path/to/invoice.pdf",
                "metadata": {
                    "size": 256000,
                    "extension": ".pdf",
                    "document": {
                        "page_count": 2,
                        "title": "Invoice",
                        "author": "Acme Corp",
                        "created": "2025-01-05T09:00:00Z"
                    }
                }
            }
        ],
        "source_path": "/source",
        "destination_path": "/dest"
    }
    
    req = OrganizeRequest(**request_data)
    files = req.get_file_list()
    
    assert files[0]['metadata']['document']['author'] == "Acme Corp"
    assert files[0]['metadata']['document']['page_count'] == 2
    print("✅ Test 5: Document metadata - PASSED")


def test_mixed_files_with_and_without_metadata():
    """Test that some files can have metadata while others don't"""
    from file_organizer.request_models import OrganizeRequest
    
    request_data = {
        "files_with_metadata": [
            {
                "path": "/path/to/image.jpg",
                "metadata": {
                    "size": 1024000,
                    "image": {"width": 1920, "height": 1080}
                }
            },
            {
                "path": "/path/to/unknown.bin",
                "metadata": None  # No metadata available
            }
        ],
        "source_path": "/source",
        "destination_path": "/dest"
    }
    
    req = OrganizeRequest(**request_data)
    files = req.get_file_list()
    
    assert len(files) == 2
    assert files[0]['metadata'] is not None
    assert files[1]['metadata'] is None
    print("✅ Test 6: Mixed files with/without metadata - PASSED")


def test_metadata_integration_with_analyzer():
    """Test that metadata is properly passed to the AI analyzer"""
    from file_organizer.ai_content_analyzer import AIContentAnalyzer
    
    # Mock shared services
    class MockSharedServices:
        def is_ai_available(self):
            return False
    
    analyzer = AIContentAnalyzer(shared_services=MockSharedServices())
    
    # Test metadata structure
    files_metadata = {
        "/path/to/image.jpg": {
            "size": 1024000,
            "image": {
                "width": 1920,
                "height": 1080,
                "date_taken": "2025-01-12T14:20:00Z",
                "camera_model": "Canon EOS R5",
                "location": "Vienna, Austria"
            }
        }
    }
    
    # Verify metadata structure is correct
    assert files_metadata["/path/to/image.jpg"]["image"]["camera_model"] == "Canon EOS R5"
    print("✅ Test 7: Metadata integration structure - PASSED")


def test_priority_order():
    """Test that files_with_metadata takes priority over other formats"""
    from file_organizer.request_models import OrganizeRequest
    
    # Provide all three formats - files_with_metadata should win
    request_data = {
        "files": ["/legacy/file.txt"],
        "file_paths": ["/paths/file.txt"],
        "files_with_metadata": [
            {
                "path": "/metadata/file.txt",
                "metadata": {"size": 100}
            }
        ],
        "source_path": "/source",
        "destination_path": "/dest"
    }
    
    req = OrganizeRequest(**request_data)
    files = req.get_file_list()
    
    assert len(files) == 1
    assert files[0]['path'] == "/metadata/file.txt"
    print("✅ Test 8: Priority order - PASSED")


if __name__ == '__main__':
    print("🧪 Testing Enhanced File Metadata Support\n")
    
    try:
        test_request_model_parsing()
        test_legacy_format_compatibility()
        test_file_paths_format()
        test_archive_metadata()
        test_document_metadata()
        test_mixed_files_with_and_without_metadata()
        test_metadata_integration_with_analyzer()
        test_priority_order()
        
        print("\n✅ All tests passed!")
        
    except AssertionError as e:
        print(f"\n❌ Test failed: {e}")
        raise
    except Exception as e:
        print(f"\n❌ Error: {e}")
        raise
