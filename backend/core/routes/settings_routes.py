#!/usr/bin/env python3
"""
Settings API Routes

Provides endpoints for managing user settings including file naming conventions,
AI behavior preferences, and organization rules.
"""

import logging
from flask import request, jsonify

logger = logging.getLogger('SettingsRoutes')

def register_settings_routes(app, web_server):
    """Register settings routes with the Flask app"""
    
    def _get_settings_manager():
        """Get UserSettingsManager instance"""
        try:
            # Get the file organizer database path
            from file_organizer.user_settings_manager import UserSettingsManager
            
            # Use the same database as file organizer
            db_path = web_server._get_file_organizer_db_path()
            return UserSettingsManager(db_path)
        except Exception as e:
            logger.error(f"Error getting settings manager: {e}")
            return None
    
    @app.route('/api/settings/file-naming', methods=['GET'])
    def get_file_naming_settings():
        """
        Get user's file naming settings.
        
        Returns:
            JSON object with current file naming preferences
        """
        try:
            user_id = request.args.get('user_id', 'dev_user')
            
            settings_manager = _get_settings_manager()
            if not settings_manager:
                return jsonify({'success': False, 'error': 'Settings service unavailable'}), 500
            
            settings = settings_manager.get_file_naming_settings(user_id)
            
            return jsonify({
                'success': True,
                'settings': settings
            })
            
        except Exception as e:
            logger.error(f"/api/settings/file-naming GET error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500
    
    @app.route('/api/settings/file-naming', methods=['POST'])
    def save_file_naming_settings():
        """
        Save user's file naming settings.
        
        Request Body:
            JSON object with file naming preferences
            
        Returns:
            Success/error status
        """
        try:
            data = request.get_json(force=True, silent=True) or {}
            user_id = data.get('user_id', 'dev_user')
            settings = data.get('settings', {})
            
            if not settings:
                return jsonify({'success': False, 'error': 'Settings object required'}), 400
            
            settings_manager = _get_settings_manager()
            if not settings_manager:
                return jsonify({'success': False, 'error': 'Settings service unavailable'}), 500
            
            success = settings_manager.save_file_naming_settings(user_id, settings)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': 'File naming settings saved successfully'
                })
            else:
                return jsonify({
                    'success': False, 
                    'error': 'Failed to save settings - validation error'
                }), 400
                
        except Exception as e:
            logger.error(f"/api/settings/file-naming POST error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500
    
    @app.route('/api/settings/file-naming/prompt', methods=['GET'])
    def get_file_naming_prompt():
        """
        Get AI prompt based on user's file naming settings.
        Useful for testing and debugging.
        
        Returns:
            Generated AI prompt string
        """
        try:
            user_id = request.args.get('user_id', 'dev_user')
            
            settings_manager = _get_settings_manager()
            if not settings_manager:
                return jsonify({'success': False, 'error': 'Settings service unavailable'}), 500
            
            prompt = settings_manager.generate_file_naming_prompt(user_id)
            
            return jsonify({
                'success': True,
                'prompt': prompt
            })
            
        except Exception as e:
            logger.error(f"/api/settings/file-naming/prompt GET error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500
    
    @app.route('/api/settings/template-variables', methods=['GET'])
    def get_template_variables():
        """
        Get available template variables for a specific file type.
        
        Query params:
            file_type: 'document', 'image', 'media', or 'code'
        
        Returns:
            Dictionary of available variables with descriptions
        """
        try:
            file_type = request.args.get('file_type', 'document')
            
            from file_organizer.template_processor import TemplateProcessor
            processor = TemplateProcessor()
            variables = processor.get_available_variables(file_type)
            
            return jsonify({
                'success': True,
                'file_type': file_type,
                'variables': variables
            })
            
        except Exception as e:
            logger.error(f"/api/settings/template-variables GET error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500
    
    @app.route('/api/settings/test-template', methods=['POST'])
    def test_template():
        """
        Test a custom template with sample data.
        
        Request Body:
            {
                "template": "{date:yyyy-MM-dd} - {ai_description}",
                "file_type": "document",
                "sample_data": {...}  // Optional sample metadata
            }
        
        Returns:
            Processed filename result
        """
        try:
            data = request.get_json(force=True, silent=True) or {}
            template = data.get('template', '')
            file_type = data.get('file_type', 'document')
            sample_data = data.get('sample_data', {})
            
            if not template:
                return jsonify({'success': False, 'error': 'Template required'}), 400
            
            # Build sample file_info based on file type
            file_info = {
                'original_name_no_ext': 'sample_file',
                'parent_folder': 'TestFolder',
                'ai_description': 'Sample AI Description',
                **sample_data
            }
            
            # Add type-specific defaults
            if file_type == 'image':
                file_info.setdefault('width', 1920)
                file_info.setdefault('height', 1080)
                file_info.setdefault('dimensions', '1920x1080')
                file_info.setdefault('camera_model', 'Canon EOS 5D')
                file_info.setdefault('date_taken', '2024:12:17 10:30:00')
            elif file_type == 'media':
                file_info.setdefault('artist', 'Sample Artist')
                file_info.setdefault('title', 'Sample Title')
                file_info.setdefault('album', 'Sample Album')
                file_info.setdefault('year', 2024)
                file_info.setdefault('genre', 'Rock')
            elif file_type == 'document':
                file_info.setdefault('author', 'John Doe')
                file_info.setdefault('page_count', 42)
            elif file_type == 'code':
                file_info.setdefault('language', 'Python')
                file_info.setdefault('main_function', 'process_data')
                file_info.setdefault('framework', 'Flask')
            
            from file_organizer.template_processor import process_template
            result = process_template(template, file_info)
            
            return jsonify({
                'success': True,
                'template': template,
                'result': result,
                'file_info_used': file_info
            })
            
        except Exception as e:
            logger.error(f"/api/settings/test-template POST error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500