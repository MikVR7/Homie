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

    def _get_destination_manager():
        """Get DestinationMemoryManager instance"""
        try:
            file_organizer_app = web_server.app_manager.get_module_app('file_organizer')
            if file_organizer_app and hasattr(file_organizer_app, 'path_memory_manager'):
                path_mgr = file_organizer_app.path_memory_manager
                if hasattr(path_mgr, '_destination_manager'):
                    return path_mgr._destination_manager
        except Exception as e:
            logger.warning(f"Could not get DestinationMemoryManager: {e}")
        return None

    @app.route('/api/file-organizer/suggest-alternatives', methods=['POST'])
    def fo_suggest_alternatives():
        """
        When user disagrees with a suggestion, provide 3-5 alternative organization options.
        First tries to suggest other known destinations in the same category.
        Falls back to AI-generated alternatives if no known destinations exist.
        """
        try:
            data = request.get_json(force=True, silent=True) or {}
            rejected_operation = data.get('rejected_operation')
            user_id = data.get('user_id', 'dev_user')
            client_id = data.get('client_id', 'default_client')
            
            if not rejected_operation:
                return jsonify({'success': False, 'error': 'rejected_operation required'}), 400
            
            # Validate rejected_operation structure
            required_fields = ['source', 'destination', 'type']
            for field in required_fields:
                if field not in rejected_operation:
                    return jsonify({'success': False, 'error': f'rejected_operation.{field} required'}), 400
            
            # Try to get alternatives from known destinations first
            alternatives = []
            dest_manager = _get_destination_manager()
            
            if dest_manager:
                try:
                    from pathlib import Path
                    import uuid
                    
                    # Extract category from rejected destination
                    rejected_dest = rejected_operation['destination']
                    rejected_dest_folder = str(Path(rejected_dest).parent)
                    category = dest_manager.extract_category_from_path(rejected_dest_folder)
                    
                    logger.info(f"Looking for alternatives in category: {category}")
                    
                    # Get other destinations in same category
                    category_destinations = dest_manager.get_destinations_by_category(user_id, category)
                    
                    # Exclude the rejected destination
                    alternative_destinations = [
                        d for d in category_destinations 
                        if d.path != rejected_dest_folder
                    ]
                    
                    # Create alternative operations
                    source_file = rejected_operation['source']
                    source_filename = Path(source_file).name
                    
                    for dest in alternative_destinations[:5]:  # Limit to 5 alternatives
                        alt_dest_path = str(Path(dest.path) / source_filename)
                        
                        # Build reason
                        reason_parts = [f"Alternative: {dest.category} folder"]
                        if dest.usage_count > 0:
                            reason_parts.append(f"used {dest.usage_count} time{'s' if dest.usage_count != 1 else ''} previously")
                        reason = " - ".join(reason_parts)
                        
                        alternatives.append({
                            'operation_id': f"alt_{str(uuid.uuid4())[:8]}",
                            'type': rejected_operation['type'],
                            'source': source_file,
                            'destination': alt_dest_path,
                            'reason': reason,
                            'status': 'pending'
                        })
                    
                    if alternatives:
                        logger.info(f"Found {len(alternatives)} alternative destination(s) from known destinations")
                        return jsonify({
                            'success': True,
                            'alternatives': alternatives,
                            'source': 'known_destinations'
                        })
                
                except Exception as dest_error:
                    logger.warning(f"Could not get alternatives from known destinations: {dest_error}")
            
            # Fallback to AI-generated alternatives
            logger.info("No known alternatives found, falling back to AI generation")
            
            from file_organizer.ai_content_analyzer import AIContentAnalyzer
            shared_services = web_server.components.get('shared_services')
            analyzer = AIContentAnalyzer(shared_services=shared_services)
            
            result = analyzer.suggest_alternatives(rejected_operation)
            
            if not result.get('success'):
                return jsonify(result), 503
            
            # Add source indicator
            if result.get('success'):
                result['source'] = 'ai_generated'
            
            return jsonify(result)
            
        except Exception as e:
            logger.error(f"/suggest-alternatives error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

