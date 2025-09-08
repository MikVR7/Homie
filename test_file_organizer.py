#!/usr/bin/env python3
"""
Simple File Organizer Test Script
Tests the file organizer functionality directly without Flutter UI issues
"""

import os
import sys
import tempfile
import shutil
from pathlib import Path

def create_test_files():
    """Create a test directory with sample files"""
    test_dir = Path(tempfile.mkdtemp(prefix="homie_test_"))
    print(f"📁 Created test directory: {test_dir}")
    
    # Create sample files of different types
    test_files = [
        "document.pdf",
        "image.jpg", 
        "video.mp4",
        "music.mp3",
        "code.py",
        "spreadsheet.xlsx",
        "text.txt"
    ]
    
    for filename in test_files:
        file_path = test_dir / filename
        file_path.write_text(f"Test content for {filename}")
        print(f"   ✅ Created: {filename}")
    
    return str(test_dir)

def test_file_organizer_direct():
    """Test the file organizer functionality directly"""
    print("🧪 Testing File Organizer - Direct Python Test")
    print("=" * 50)
    
    # Create test directory
    test_folder = create_test_files()
    
    print(f"\n📂 Test folder contents:")
    for file in os.listdir(test_folder):
        print(f"   - {file}")
    
    # TODO: Add direct import and test of file organizer logic
    print(f"\n✅ Test setup complete!")
    print(f"🗂️  Test folder: {test_folder}")
    print(f"📝 You can manually inspect the files and test organization logic")
    
    return test_folder

if __name__ == "__main__":
    test_folder = test_file_organizer_direct()
    print(f"\n🎯 Your test folder is ready at: {test_folder}")
    print("You can now manually test file organization operations!")



