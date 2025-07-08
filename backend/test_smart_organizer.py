#!/usr/bin/env python3
"""
Test script for Smart Organizer - Uses .env file for configuration
"""

import os
import sys
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Add the src directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from homie.smart_organizer import demo_organization_analysis

def main():
    print("🏠 Homie Smart Organizer Test")
    print("=" * 50)
    print("Loading configuration from .env file...")
    print()
    
    # Get configuration from environment variables
    api_key = os.getenv('GEMINI_API_KEY')
    debug = os.getenv('DEBUG', 'false').lower() == 'true'
    
    # Test paths - in production these will come from the UI
    downloads_path = '/home/mikele/Downloads'
    sorted_path = '/home/mikele/Desktop/sorted'
    
    if not api_key:
        print("❌ GEMINI_API_KEY not found in .env file!")
        print("\n📝 Setup instructions:")
        print("1. Copy .env.example to .env")
        print("2. Add your Gemini API key to the .env file")
        print("3. Get your API key from: https://makersuite.google.com/app/apikey")
        return
    
    if debug:
        print(f"🔧 Debug mode enabled")
        print(f"📁 Downloads path: {downloads_path}")
        print(f"📂 Sorted path: {sorted_path}")
        print(f"🔑 API key: {api_key[:8]}...")
        print()
    
    try:
        # Run the analysis
        analysis = demo_organization_analysis(downloads_path, sorted_path, api_key)
        
        print("\n🎉 Analysis complete!")
        print("Check the output above for AI suggestions.")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        print("\nMake sure:")
        print("1. Your API key is correct")
        print("2. You have internet connection")
        print("3. The paths exist:")
        print(f"   Downloads: {downloads_path}")
        print(f"   Sorted: {sorted_path}")

if __name__ == "__main__":
    main()
