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
        'message': 'Homie API is running!'
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
        
        # Reuse existing organizer if same API key, otherwise create new one
        if (not hasattr(app, 'organizer_instance') or 
            app.organizer_instance is None or 
            getattr(app, 'organizer_api_key', None) != api_key):
            organizer = SmartOrganizer(api_key)
            app.organizer_instance = organizer
            app.organizer_api_key = api_key
        else:
            organizer = app.organizer_instance
        
        analysis = organizer.analyze_downloads_folder(downloads_path, sorted_path)
        
        # Check if the analysis contains quota or other API errors
        if 'error_type' in analysis:
            error_type = analysis['error_type']
            
            if error_type == 'quota_exceeded':
                print(f"⚠️  Quota exceeded during AI analysis")
                return jsonify({
                    'success': False,
                    'error_type': 'quota_exceeded',
                    'error': analysis['error'],
                    'error_details': analysis['error_details'],
                    'suggestions': analysis['suggestions'],
                    'quota_info': analysis.get('quota_info', {}),
                    'fallback_available': analysis.get('fallback_available', False)
                }), 429  # 429 Too Many Requests
                
            elif error_type == 'auth_error':
                print(f"🔑 Authentication error during AI analysis")
                return jsonify({
                    'success': False,
                    'error_type': 'auth_error',
                    'error': analysis['error'],
                    'error_details': analysis['error_details'],
                    'suggestions': analysis['suggestions']
                }), 401  # 401 Unauthorized
                
            elif error_type == 'api_error':
                print(f"🔧 API error during AI analysis")
                return jsonify({
                    'success': False,
                    'error_type': 'api_error',
                    'error': analysis['error'],
                    'error_details': analysis['error_details'],
                    'suggestions': analysis['suggestions'],
                    'fallback_available': analysis.get('fallback_available', False)
                }), 502  # 502 Bad Gateway (upstream API error)
                
            else:  # generic_error
                print(f"❌ Generic error during AI analysis")
                return jsonify({
                    'success': False,
                    'error_type': 'generic_error',
                    'error': analysis['error'],
                    'error_details': analysis['error_details'],
                    'suggestions': analysis['suggestions'],
                    'fallback_available': analysis.get('fallback_available', False)
                }), 500
        
        # Success case
        print(f"✅ AI analysis completed: {analysis['total_files']} files analyzed")
        
        return jsonify({
            'success': True,
            'data': analysis
        })
        
    except Exception as e:
        print(f"❌ Error during AI organization: {e}")
        return jsonify({
            'success': False,
            'error_type': 'server_error',
            'error': 'Server Error',
            'error_details': f'An unexpected server error occurred: {str(e)}',
            'suggestions': [
                'Try again in a few moments',
                'Check that all required parameters are provided',
                'Contact support if the problem persists'
            ]
        }), 500



@app.route('/api/status', methods=['GET'])
def get_status():
    """Get system status"""
    return jsonify({
        'status': 'running',
        'version': '1.0.0',
        'endpoints': [
            '/api/health',
            '/api/discover', 
            '/api/organize',
            '/api/browse-folders',
            '/api/status'
        ]
    })

if __name__ == '__main__':
    print("🏠 Starting Homie API Server...")
    print("=" * 50)
    print("Frontend should connect to: http://localhost:8000")
    print("API endpoints available:")
    print("  GET  /api/health        - Health check")
    print("  POST /api/discover      - Folder discovery")
    print("  POST /api/organize      - AI-powered organization analysis")
    print("  POST /api/browse-folders - File system folder browsing")
    print("  GET  /api/status        - System status")
    print("-" * 50)
    
    app.run(host='0.0.0.0', port=8000, debug=True)
