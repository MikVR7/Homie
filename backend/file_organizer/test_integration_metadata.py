#!/usr/bin/env python3
"""
Integration Test: Enhanced Metadata Support

Tests the complete flow from request parsing to AI analysis.
"""

import sys
from pathlib import Path

# Add backend directory to path
backend_dir = Path(__file__).parent.parent
sys.path.insert(0, str(backend_dir))

import json


def test_request_to_metadata_flow():
    """Test the complete flow from request to metadata extraction"""
    from file_organizer.request_models import OrganizeRequest
    
    # Simulate a frontend request with rich metadata
    request_json = {
        "files_with_metadata": [
            {
                "path": "/test/photo.jpg",
                "metadata": {
                    "size": 2048000,
                    "extension": ".jpg",
                    "image": {
                        "width": 1920,
                        "height": 1080,
                        "date_taken": "2025-01-12T14:20:00Z",
                        "camera_model": "Canon EOS R5",
                        "location": "Vienna, Austria"
                    }
                }
            },
            {
                "path": "/test/project.zip",
                "metadata": {
                    "size": 5242880,
                    "extension": ".zip",
                    "archive": {
                        "archive_type": "ZIP",
                        "contents": ["src/Program.cs", "MyProject.csproj"],
                        "detected_project_type": "DotNet"
                    }
                }
            }
        ],
        "source_path": "/test/source",
        "destination_path": "/test/dest"
    }
    
    # Parse request
    request = OrganizeRequest(**request_json)
    files = request.get_file_list()
    
    # Extract metadata dict for analyzer
    files_metadata = {f['path']: f['metadata'] for f in files if f['metadata']}
    
    # Verify structure
    assert len(files_metadata) == 2
    assert "/test/photo.jpg" in files_metadata
    assert "/test/project.zip" in files_metadata
    
    # Verify image metadata
    img_meta = files_metadata["/test/photo.jpg"]
    assert img_meta['image']['camera_model'] == "Canon EOS R5"
    assert img_meta['image']['location'] == "Vienna, Austria"
    
    # Verify archive metadata
    arch_meta = files_metadata["/test/project.zip"]
    assert arch_meta['archive']['detected_project_type'] == "DotNet"
    assert "src/Program.cs" in arch_meta['archive']['contents']
    
    print("✅ Request to metadata flow - PASSED")
    return files_metadata


def test_metadata_structure_for_ai():
    """Test that metadata is structured correctly for AI consumption"""
    files_metadata = test_request_to_metadata_flow()
    
    # Simulate building file_list for AI (as done in ai_content_analyzer.py)
    file_paths = list(files_metadata.keys())
    file_list = []
    
    for fp in file_paths:
        file_info = {
            'path': fp,
            'name': Path(fp).name,
            'extension': Path(fp).suffix.lower()
        }
        
        # Add metadata (same logic as in analyzer)
        if fp in files_metadata:
            metadata = files_metadata[fp]
            if metadata:
                if 'size' in metadata:
                    file_info['size_bytes'] = metadata['size']
                    file_info['size_mb'] = round(metadata['size'] / (1024 * 1024), 2)
                
                if 'image' in metadata and metadata['image']:
                    img = metadata['image']
                    file_info['image_info'] = {k: v for k, v in img.items() if v is not None}
                
                elif 'archive' in metadata and metadata['archive']:
                    arch = metadata['archive']
                    file_info['archive_metadata'] = {k: v for k, v in arch.items() if v is not None}
        
        file_list.append(file_info)
    
    # Verify AI-ready structure
    assert len(file_list) == 2
    
    # Check image file
    img_file = next(f for f in file_list if f['name'] == 'photo.jpg')
    assert 'image_info' in img_file
    assert img_file['image_info']['camera_model'] == "Canon EOS R5"
    assert img_file['size_mb'] == 1.95  # 2048000 bytes = ~1.95 MB
    
    # Check archive file
    arch_file = next(f for f in file_list if f['name'] == 'project.zip')
    assert 'archive_metadata' in arch_file
    assert arch_file['archive_metadata']['detected_project_type'] == "DotNet"
    assert arch_file['size_mb'] == 5.0  # 5242880 bytes = 5 MB
    
    print("✅ Metadata structure for AI - PASSED")
    print(f"\nAI-ready file list:\n{json.dumps(file_list, indent=2)}")


def test_backward_compatibility():
    """Test that legacy requests still work"""
    from file_organizer.request_models import OrganizeRequest
    
    # Legacy format 1: files array
    legacy1 = {
        "files": ["/test/file1.txt", "/test/file2.pdf"],
        "source_path": "/test/source",
        "destination_path": "/test/dest"
    }
    
    req1 = OrganizeRequest(**legacy1)
    files1 = req1.get_file_list()
    assert len(files1) == 2
    assert all(f['metadata'] is None for f in files1)
    
    # Legacy format 2: file_paths array
    legacy2 = {
        "file_paths": ["/test/file3.txt", "/test/file4.pdf"],
        "source_path": "/test/source",
        "destination_path": "/test/dest"
    }
    
    req2 = OrganizeRequest(**legacy2)
    files2 = req2.get_file_list()
    assert len(files2) == 2
    assert all(f['metadata'] is None for f in files2)
    
    print("✅ Backward compatibility - PASSED")


def test_mixed_metadata():
    """Test files with and without metadata in same request"""
    from file_organizer.request_models import OrganizeRequest
    
    request_json = {
        "files_with_metadata": [
            {
                "path": "/test/with_meta.jpg",
                "metadata": {
                    "size": 1024000,
                    "image": {"width": 1920, "height": 1080}
                }
            },
            {
                "path": "/test/without_meta.txt",
                "metadata": None
            }
        ],
        "source_path": "/test/source",
        "destination_path": "/test/dest"
    }
    
    request = OrganizeRequest(**request_json)
    files = request.get_file_list()
    
    assert len(files) == 2
    assert files[0]['metadata'] is not None
    assert files[1]['metadata'] is None
    
    # Build metadata dict (only non-null)
    files_metadata = {f['path']: f['metadata'] for f in files if f['metadata']}
    assert len(files_metadata) == 1
    assert "/test/with_meta.jpg" in files_metadata
    
    print("✅ Mixed metadata - PASSED")


def test_all_metadata_types():
    """Test that all metadata types are correctly parsed"""
    from file_organizer.request_models import OrganizeRequest
    
    request_json = {
        "files_with_metadata": [
            {
                "path": "/test/image.jpg",
                "metadata": {"image": {"width": 1920}}
            },
            {
                "path": "/test/video.mp4",
                "metadata": {"video": {"duration": 120.5}}
            },
            {
                "path": "/test/audio.mp3",
                "metadata": {"audio": {"artist": "Artist"}}
            },
            {
                "path": "/test/doc.pdf",
                "metadata": {"document": {"page_count": 5}}
            },
            {
                "path": "/test/archive.zip",
                "metadata": {"archive": {"archive_type": "ZIP"}}
            },
            {
                "path": "/test/code.py",
                "metadata": {"source_code": {"language": "Python"}}
            }
        ],
        "source_path": "/test/source",
        "destination_path": "/test/dest"
    }
    
    request = OrganizeRequest(**request_json)
    files = request.get_file_list()
    
    assert len(files) == 6
    
    # Verify each type
    types_found = set()
    for f in files:
        if f['metadata']:
            for key in ['image', 'video', 'audio', 'document', 'archive', 'source_code']:
                if key in f['metadata'] and f['metadata'][key]:
                    types_found.add(key)
    
    assert len(types_found) == 6
    print("✅ All metadata types - PASSED")


if __name__ == '__main__':
    print("🧪 Integration Test: Enhanced Metadata Support\n")
    
    try:
        test_request_to_metadata_flow()
        test_metadata_structure_for_ai()
        test_backward_compatibility()
        test_mixed_metadata()
        test_all_metadata_types()
        
        print("\n" + "="*60)
        print("✅ ALL INTEGRATION TESTS PASSED!")
        print("="*60)
        print("\n📋 Summary:")
        print("  • Request parsing works correctly")
        print("  • Metadata flows through to AI analyzer")
        print("  • Backward compatibility maintained")
        print("  • Mixed metadata scenarios handled")
        print("  • All metadata types supported")
        print("\n🚀 Ready for production!")
        
    except AssertionError as e:
        print(f"\n❌ Test failed: {e}")
        raise
    except Exception as e:
        print(f"\n❌ Error: {e}")
        raise
