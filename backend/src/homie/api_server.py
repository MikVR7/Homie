#!/usr/bin/env python3
"""
Homie Flask API Server
Provides REST API endpoints for the Homie frontend
"""

import os
import sys
import time
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS

# Add the src directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from homie.discover import discover_folders
from homie.smart_organizer import SmartOrganizer

app = Flask(__name__)
CORS(app)  # Enable CORS for frontend communication

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'message': 'Homie backend is running',
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/discover', methods=['POST'])
def discover():
    """Folder discovery endpoint"""
    try:
        data = request.get_json()
        if not data or 'path' not in data:
            return jsonify({
                'success': False,
                'error': 'Path is required'
            }), 400
        
        scan_path = data['path']
        if not os.path.exists(scan_path):
            return jsonify({
                'success': False,
                'error': f'Path does not exist: {scan_path}'
            }), 400
        
        print(f"Starting folder discovery for: {scan_path}")
        start_time = time.time()
        
        # Use the existing discover_folders function
        folder_map = discover_folders(scan_path)
        
        end_time = time.time()
        scan_duration = end_time - start_time
        
        # Convert folder_map to the format expected by frontend
        folder_structure = {}
        total_files = 0
        
        for folder_path, folder_data in folder_map.items():
            folder_name = os.path.basename(folder_path) or folder_path
            file_count = len(folder_data.get('files', {}))
            total_files += file_count
            
            folder_structure[folder_name] = {
                'file_count': file_count,
                'subfolders': {}
            }
            
            # Add subdirectories from the dirs list
            for subdir_name in folder_data.get('dirs', []):
                # For now, just add the subdir name with 0 files
                # The actual file count will be calculated when we iterate over that subdirectory
                folder_structure[folder_name]['subfolders'][subdir_name] = {
                    'file_count': 0  # Will be updated when we process that directory
                }
        
        # Generate insights
        insights = []
        if len(folder_map) > 10:
            insights.append(f"Found {len(folder_map)} directories - quite a large structure!")
        if total_files > 1000:
            insights.append(f"Discovered {total_files} files total - substantial collection")
        if scan_duration > 5:
            insights.append(f"Scan took {scan_duration:.1f}s - consider optimizing for large directories")
        
        response_data = {
            'success': True,
            'data': {
                'total_folders': len(folder_map),
                'total_files': total_files,
                'scan_time': f"{scan_duration:.2f}s",
                'folder_structure': folder_structure,
                'insights': insights
            }
        }
        
        print(f"✅ Discovery completed: {len(folder_map)} folders, {total_files} files in {scan_duration:.2f}s")
        return jsonify(response_data)
        
    except Exception as e:
        print(f"❌ Error during discovery: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/organize', methods=['POST'])
def smart_organize():
    """AI-powered smart organization analysis"""
    try:
        data = request.get_json()
        if not data or 'downloads_path' not in data or 'sorted_path' not in data:
            return jsonify({
                'success': False,
                'error': 'downloads_path and sorted_path are required'
            }), 400
        
        downloads_path = data['downloads_path']
        sorted_path = data['sorted_path']
        api_key = data.get('api_key')
        
        if not api_key:
            return jsonify({
                'success': False,
                'error': 'Gemini API key is required for AI analysis'
            }), 400
        
        if not os.path.exists(downloads_path):
            return jsonify({
                'success': False,
                'error': f'Downloads path does not exist: {downloads_path}'
            }), 400
            
        if not os.path.exists(sorted_path):
            return jsonify({
                'success': False,
                'error': f'Sorted path does not exist: {sorted_path}'
            }), 400
        
        print(f"🤖 Starting AI organization analysis...")
        print(f"   Downloads: {downloads_path}")
        print(f"   Sorted: {sorted_path}")
        
        organizer = SmartOrganizer(api_key)
        analysis = organizer.analyze_downloads_folder(downloads_path, sorted_path)
        
        print(f"✅ AI analysis completed: {analysis['total_files_to_organize']} files analyzed")
        
        return jsonify({
            'success': True,
            'data': analysis
        })
        
    except Exception as e:
        print(f"❌ Error during AI organization: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/status', methods=['GET'])
def status():
    """Get current system status"""
    return jsonify({
        'backend_running': True,
        'version': '0.1.0',
        'phase': 'Phase 1 - File Discovery'
    })

if __name__ == '__main__':
    print("🏠 Starting Homie API Server...")
    print("=" * 50)
    print("Frontend should connect to: http://localhost:8000")
    print("API endpoints available:")
    print("  GET  /api/health   - Health check")
    print("  POST /api/discover - Folder discovery")
    print("  POST /api/organize - AI-powered organization analysis")
    print("  GET  /api/status   - System status")
    print("-" * 50)
    
    app.run(host='0.0.0.0', port=8000, debug=True)
