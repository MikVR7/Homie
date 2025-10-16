#!/usr/bin/env python3
"""
AI Routes - AI-powered features
Handles: suggest-destination, explain-operation, suggest-alternatives
"""

import logging
from flask import request, jsonify
from pathlib import Path

logger = logging.getLogger('AIRoutes')


def register_ai_routes(app, web_server):
    """Register AI-powered routes with the Flask app"""
    
    @app.route('/api/file-organizer/suggest-destination', methods=['POST'])
    def fo_suggest_destination():
        """Get AI suggestion for where a file should go"""
        try:
            data = request.get_json(force=True, silent=True) or {}
            file_path = data.get('file_path')
            
            if not file_path:
                return jsonify({'success': False, 'error': 'file_path required'}), 400
            
            from file_organizer.ai_content_analyzer import AIContentAnalyzer
            shared_services = web_server.components.get('shared_services')
            analyzer = AIContentAnalyzer(shared_services=shared_services)
            
            result = analyzer.analyze_file(file_path, use_ai=True)
            
            if not result.get('success'):
                return jsonify(result), 503
            
            return jsonify({
                'success': True,
                'suggested_folder': result.get('suggested_folder', 'Other'),
                'content_type': result.get('content_type', 'unknown')
            })
            
        except Exception as e:
            logger.error(f"/suggest-destination error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

    @app.route('/api/file-organizer/explain-operation', methods=['POST'])
    def fo_explain_operation():
        """
        Generate a human-friendly explanation for why a file should be organized
        in a specific way. This is called on-demand when the user clicks "Why?"
        """
        try:
            data = request.get_json(force=True, silent=True) or {}
            source = data.get('source')
            destination = data.get('destination')
            operation_type = data.get('operation_type', 'move')
            
            if not source:
                return jsonify({'success': False, 'error': 'source required'}), 400
            
            # Build explanation prompt based on operation type
            if operation_type == 'delete':
                prompt = f"""Explain in 1-2 sentences why this file should be deleted:

File: {Path(source).name}
Reason: This is a redundant archive file - the content has already been extracted.

Return ONLY valid JSON with this structure:
{{"reason": "your friendly explanation here"}}"""
            else:
                if not destination:
                    return jsonify({'success': False, 'error': 'destination required for move/copy operations'}), 400
                
                prompt = f"""Explain in 2-3 sentences why this file organization makes sense:

File: {Path(source).name}
Action: {operation_type}
Destination: {destination}

Provide a friendly, human-readable explanation that helps the user understand the reasoning.
Return ONLY valid JSON with this structure:
{{"reason": "your explanation here"}}"""
            
            # Call AI to generate explanation
            result = web_server._call_ai_with_recovery(prompt)
            
            if not result.get('success'):
                return jsonify(result), 503
            
            # Extract reason from JSON response
            reason = result.get('data', {}).get('reason', '').strip()
            
            if not reason:
                reason = "This file has been categorized based on its content and metadata."
            
            return jsonify({
                'success': True,
                'reason': reason
            })
            
        except Exception as e:
            logger.error(f"/explain-operation error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

    @app.route('/api/file-organizer/suggest-alternatives', methods=['POST'])
    def fo_suggest_alternatives():
        """
        When user disagrees with a suggestion, provide 3-5 alternative organization options.
        """
        try:
            data = request.get_json(force=True, silent=True) or {}
            rejected_operation = data.get('rejected_operation')
            
            if not rejected_operation:
                return jsonify({'success': False, 'error': 'rejected_operation required'}), 400
            
            # Validate rejected_operation structure
            required_fields = ['source', 'destination', 'type']
            for field in required_fields:
                if field not in rejected_operation:
                    return jsonify({'success': False, 'error': f'rejected_operation.{field} required'}), 400
            
            from file_organizer.ai_content_analyzer import AIContentAnalyzer
            shared_services = web_server.components.get('shared_services')
            analyzer = AIContentAnalyzer(shared_services=shared_services)
            
            result = analyzer.suggest_alternatives(rejected_operation)
            
            if not result.get('success'):
                return jsonify(result), 503
            
            return jsonify(result)
            
        except Exception as e:
            logger.error(f"/suggest-alternatives error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

