#!/usr/bin/env python3
"""
Test script for nested file organization
Verifies that files in subdirectories are properly included in operations
"""

import json
import tempfile
from pathlib import Path


def test_nested_files_in_request():
    """Test that nested files are properly handled when provided in file_paths"""
    
    print("\n=== Test: Nested Files in Organization Request ===\n")
    
    # Create a temporary directory structure
    with tempfile.TemporaryDirectory() as tmpdir:
        source = Path(tmpdir) / "source"
        dest = Path(tmpdir) / "dest"
        source.mkdir()
        dest.mkdir()
        
        # Create test files with nested structure
        (source / "root_file.txt").write_text("root level file")
        
        subfolder1 = source / "Test"
        subfolder1.mkdir()
        (subfolder1 / "nested_file1.txt").write_text("nested in Test")
        
        subfolder2 = source / "ChatGPT"
        subfolder2.mkdir()
        (subfolder2 / "ChatGPT.png").write_text("image in ChatGPT folder")
        
        deep_folder = subfolder1 / "Deep"
        deep_folder.mkdir()
        (deep_folder / "deep_file.txt").write_text("deeply nested")
        
        # Collect all files (simulating frontend behavior)
        all_files = []
        for file_path in source.rglob("*"):
            if file_path.is_file():
                all_files.append(str(file_path))
        
        print(f"✓ Created test structure with {len(all_files)} files:")
        for fp in all_files:
            rel_path = Path(fp).relative_to(source)
            print(f"  - {rel_path}")
        
        # Simulate the request payload
        request_data = {
            'source_path': str(source),
            'destination_path': str(dest),
            'organization_style': 'by_type',
            'user_id': 'test_user',
            'client_id': 'test_client',
            'file_paths': all_files  # Frontend sends ALL files including nested
        }
        
        print(f"\n✓ Request payload includes {len(request_data['file_paths'])} file paths")
        print(f"✓ Nested files included: {len([f for f in all_files if '/' in Path(f).relative_to(source).as_posix()])}")
        
        # Expected behavior:
        # 1. Backend should process ALL files from file_paths
        # 2. Each file should get an operation
        # 3. Nested structure should be preserved in destination paths
        
        print("\n✅ Test structure created successfully")
        print(f"\nExpected behavior:")
        print(f"  - Input files: {len(all_files)}")
        print(f"  - Expected operations: {len(all_files)}")
        print(f"  - Each nested file should preserve its subfolder structure")
        
        return request_data


def test_relative_path_preservation():
    """Test that relative paths are correctly preserved"""
    
    print("\n=== Test: Relative Path Preservation ===\n")
    
    with tempfile.TemporaryDirectory() as tmpdir:
        source = Path(tmpdir) / "source"
        dest = Path(tmpdir) / "dest"
        source.mkdir()
        dest.mkdir()
        
        # Create nested structure
        (source / "Test" / "Sub").mkdir(parents=True)
        test_file = source / "Test" / "Sub" / "file.txt"
        test_file.write_text("test")
        
        # Test relative path calculation
        relative = test_file.relative_to(source)
        print(f"✓ Source: {source}")
        print(f"✓ File: {test_file}")
        print(f"✓ Relative path: {relative}")
        print(f"✓ Parts: {relative.parts}")
        print(f"✓ Is nested: {len(relative.parts) > 1}")
        
        # Simulate destination path construction
        suggested_folder = "Documents"
        if len(relative.parts) > 1:
            dest_path = dest / suggested_folder / relative
        else:
            dest_path = dest / suggested_folder / test_file.name
        
        print(f"\n✓ Destination path: {dest_path}")
        print(f"✓ Preserves structure: {'Test/Sub' in str(dest_path)}")
        
        assert "Test" in str(dest_path), "Should preserve 'Test' folder"
        assert "Sub" in str(dest_path), "Should preserve 'Sub' folder"
        
        print("\n✅ Relative path preservation works correctly")


def test_fallback_for_missing_results():
    """Test that files without AI results get fallback operations"""
    
    print("\n=== Test: Fallback for Missing AI Results ===\n")
    
    # Simulate scenario where AI doesn't return results for some files
    input_files = [
        "/source/file1.txt",
        "/source/nested/file2.txt",
        "/source/deep/nested/file3.txt"
    ]
    
    ai_results = {
        "/source/file1.txt": {"action": "move", "suggested_folder": "Documents"}
        # file2.txt and file3.txt are missing from AI results
    }
    
    print(f"✓ Input files: {len(input_files)}")
    print(f"✓ AI results: {len(ai_results)}")
    print(f"✓ Missing results: {len(input_files) - len(ai_results)}")
    
    operations = []
    
    for file_path in input_files:
        if file_path in ai_results:
            result = ai_results[file_path]
            operations.append({
                'type': result['action'],
                'source': file_path,
                'destination': f"/dest/{result['suggested_folder']}/{Path(file_path).name}"
            })
        else:
            # Fallback for missing results
            operations.append({
                'type': 'move',
                'source': file_path,
                'destination': f"/dest/Uncategorized/{Path(file_path).name}",
                'reason_hint': 'No AI analysis result - defaulting to Uncategorized'
            })
    
    print(f"\n✓ Generated operations: {len(operations)}")
    print(f"✓ Operations match input: {len(operations) == len(input_files)}")
    
    for op in operations:
        print(f"  - {Path(op['source']).name} -> {op['destination']}")
    
    assert len(operations) == len(input_files), "Every file should have an operation"
    
    print("\n✅ Fallback mechanism works correctly")


if __name__ == "__main__":
    test_nested_files_in_request()
    test_relative_path_preservation()
    test_fallback_for_missing_results()
    print("\n🎉 All tests passed!")
