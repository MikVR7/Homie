#!/usr/bin/env python3
"""
Homie - Intelligent Home File Organizer
Main entry point for the application
"""

import os
import sys
import json
import logging
from pathlib import Path

# Add the src directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from homie.discover import discover_folders, save_folder_map

def setup_logging(log_level="INFO"):
    """Set up logging configuration"""
    logging.basicConfig(
        level=getattr(logging, log_level.upper()),
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler('logs/homie.log'),
            logging.StreamHandler(sys.stdout)
        ]
    )
    return logging.getLogger(__name__)

def load_config(config_path="config/user_config.json"):
    """Load user configuration or create from template"""
    if not os.path.exists(config_path):
        template_path = "config/config_template.json"
        if os.path.exists(template_path):
            with open(template_path, 'r') as template_file:
                config = json.load(template_file)
            with open(config_path, 'w') as config_file:
                json.dump(config, config_file, indent=4)
            print(f"Created user config from template: {config_path}")
        else:
            raise FileNotFoundError("Configuration template not found")
    
    with open(config_path, 'r') as config_file:
        return json.load(config_file)

def main():
    """Main application entry point"""
    print("🏠 Homie - Intelligent Home File Organizer")
    print("=" * 50)
    
    # Ensure necessary directories exist
    os.makedirs("logs", exist_ok=True)
    os.makedirs("config", exist_ok=True)
    
    # Load configuration
    try:
        config = load_config()
        logger = setup_logging(config.get('settings', {}).get('log_level', 'INFO'))
        logger.info("Homie started successfully")
    except Exception as e:
        print(f"Error loading configuration: {e}")
        return 1
    
    # Phase 1 - Folder Discovery
    print("\n📁 Phase 1: Folder Discovery")
    print("-" * 30)
    
    # Get current directory for initial scan
    current_path = os.getcwd()
    print(f"Scanning directory: {current_path}")
    
    try:
        folder_map = discover_folders(current_path)
        save_folder_map(folder_map)
        
        print(f"✅ Discovered {len(folder_map)} directories")
        print("📄 Folder map saved to config/folder_map.json")
        
        # Display summary
        total_subdirs = sum(len(subdirs) for subdirs in folder_map.values())
        print(f"📊 Total subdirectories: {total_subdirs}")
        
        logger.info(f"Folder discovery completed. Found {len(folder_map)} directories with {total_subdirs} subdirectories")
        
    except Exception as e:
        logger.error(f"Error during folder discovery: {e}")
        print(f"❌ Error: {e}")
        return 1
    
    print("\n🎉 Homie Phase 1 completed successfully!")
    print("Next steps: Implement file analysis and organization logic")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
