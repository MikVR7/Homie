#!/usr/bin/env python3
"""
Analysis Routes - Content analysis endpoints
Handles: analyze-content, analyze-content-batch, analyze-archive, scan-duplicates
"""

import logging
from flask import request, jsonify
from pathlib import Path

logger = logging.getLogger('AnalysisRoutes')


def register_analysis_routes(app, web_server):
    """Register analysis routes with the Flask app"""
    
    @app.route('/api/file-organizer/analyze-content', methods=['POST'])
    def fo_analyze_content():
        """Analyze a single file's content"""
        try:
            data = request.get_json(force=True, silent=True) or {}
            file_path = data.get('file_path')
            use_ai = data.get('use_ai', True)
            
            if not file_path:
                return jsonify({'success': False, 'error': 'file_path required'}), 400
            
            from file_organizer.ai_content_analyzer import AIContentAnalyzer
            shared_services = web_server.components.get('shared_services')
            analyzer = AIContentAnalyzer(shared_services=shared_services)
            
            result = analyzer.analyze_file(file_path, use_ai=use_ai)
            
            if not result.get('success'):
                return jsonify(result), 503
            
            return jsonify(result)
            
        except Exception as e:
            logger.error(f"/analyze-content error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

    @app.route('/api/file-organizer/analyze-content-batch', methods=['POST'])
    def fo_analyze_content_batch():
        """Analyze multiple files' content in a single batch"""
        try:
            data = request.get_json(force=True, silent=True) or {}
            file_paths = data.get('file_paths', [])
            use_ai = data.get('use_ai', True)
            
            if not file_paths:
                return jsonify({'success': False, 'error': 'file_paths required'}), 400
            
            # Use shared batch analysis method (SINGLE SOURCE OF TRUTH)
            batch_result = web_server._batch_analyze_files(file_paths, use_ai=use_ai)
            
            return jsonify(batch_result)
            
        except Exception as e:
            logger.error(f"/analyze-content-batch error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

    @app.route('/api/file-organizer/analyze-archive', methods=['POST'])
    def fo_analyze_archive():
        """Analyze the contents of an archive file"""
        try:
            data = request.get_json(force=True, silent=True) or {}
            archive_path = data.get('archive_path')
            
            if not archive_path:
                return jsonify({'success': False, 'error': 'archive_path required'}), 400
            
            from file_organizer.ai_content_analyzer import AIContentAnalyzer
            shared_services = web_server.components.get('shared_services')
            analyzer = AIContentAnalyzer(shared_services=shared_services)
            
            result = analyzer.analyze_archive(archive_path)
            return jsonify(result)
            
        except Exception as e:
            logger.error(f"/analyze-archive error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

    @app.route('/api/file-organizer/scan-duplicates', methods=['POST'])
    def fo_scan_duplicates():
        """Scan for duplicate files"""
        try:
            data = request.get_json(force=True, silent=True) or {}
            folder_path = data.get('folder_path')
            
            if not folder_path:
                return jsonify({'success': False, 'error': 'folder_path required'}), 400
            
            from file_organizer.ai_content_analyzer import AIContentAnalyzer
            shared_services = web_server.components.get('shared_services')
            analyzer = AIContentAnalyzer(shared_services=shared_services)
            
            result = analyzer.scan_duplicates(folder_path)
            return jsonify(result)
            
        except Exception as e:
            logger.error(f"/scan-duplicates error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500
