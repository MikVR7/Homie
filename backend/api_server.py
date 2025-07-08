#!/usr/bin/env python3
"""
Flask API Server for Homie Frontend Integration
Connects Svelte frontend to Python backend via REST API
"""

import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Import our smart organizer
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))
from homie.smart_organizer import SmartOrganizer

app = Flask(__name__)
CORS(app)  # Enable CORS for Svelte frontend

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "message": "Homie backend is running"
    })

@app.route('/api/discover', methods=['POST'])
def discover_folders():
    """Original folder discovery endpoint (legacy)"""
    try:
        data = request.get_json()
        path = data.get('path', '')
        
        if not path or not os.path.exists(path):
            return jsonify({
                "success": False,
                "error": f"Path does not exist: {path}"
            }), 400
        
        # Basic folder scan
        total_files = 0
        total_folders = 0
        
        for root, dirs, files in os.walk(path):
            total_folders += len(dirs)
            total_files += len(files)
        
        return jsonify({
            "success": True,
            "data": {
                "path": path,
                "total_files": total_files,
                "total_folders": total_folders,
                "message": f"Scanned {total_files} files in {total_folders} folders"
            }
        })
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/api/organize', methods=['POST'])
def ai_organize():
    """AI-powered organization endpoint"""
    try:
        data = request.get_json()
        downloads_path = data.get('downloads_path', '')
        sorted_path = data.get('sorted_path', '')
        
        if not downloads_path or not sorted_path:
            return jsonify({
                "success": False,
                "error": "Both downloads_path and sorted_path are required"
            }), 400
        
        if not os.path.exists(downloads_path):
            return jsonify({
                "success": False,
                "error": f"Downloads path does not exist: {downloads_path}"
            }), 400
        
        # Get API key from environment
        api_key = os.getenv('GEMINI_API_KEY')
        if not api_key:
            return jsonify({
                "success": False,
                "error": "GEMINI_API_KEY not configured in environment"
            }), 500
        
        # Run AI organization analysis
        organizer = SmartOrganizer(api_key)
        analysis = organizer.analyze_downloads_folder(downloads_path, sorted_path)
        
        return jsonify({
            "success": True,
            "data": analysis
        })
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

if __name__ == '__main__':
    print("🏠 Starting Homie API Server...")
    print("Frontend will be available at: http://localhost:3000")
    print("API will be available at: http://localhost:8000")
    print()
    
    # Check if API key is configured
    if not os.getenv('GEMINI_API_KEY'):
        print("⚠️  Warning: GEMINI_API_KEY not found in .env file")
        print("AI organization features will not work without API key")
    else:
        print("✅ GEMINI_API_KEY configured")
    
    app.run(host='0.0.0.0', port=8000, debug=True)
