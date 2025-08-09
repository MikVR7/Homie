#!/usr/bin/env python3
"""
Setup script to create .env file from template
"""

import os
import shutil

def main():
    print("🏠 Homie Environment Setup")
    print("=" * 40)
    
    # Check if .env already exists
    if os.path.exists('.env'):
        overwrite = input("📄 .env file already exists. Overwrite? (y/N): ").strip().lower()
        if overwrite != 'y':
            print("✅ Keeping existing .env file")
            return
    
    # Copy template
    if os.path.exists('.env.example'):
        shutil.copy('.env.example', '.env')
        print("✅ Created .env file from template")
    else:
        print("❌ .env.example template not found!")
        return
    
    print("\n📝 Next steps:")
    print("1. Edit the .env file with your actual values:")
    print("   nano .env")
    print("2. Get your Gemini API key from:")
    print("   https://makersuite.google.com/app/apikey")
    print("3. Run the test:")
    print("   python test_smart_organizer.py")
    
if __name__ == "__main__":
    main()
