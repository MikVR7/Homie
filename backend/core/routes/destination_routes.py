#!/usr/bin/env python3
"""
Destination Routes - Destination management endpoints
"""

import logging
from flask import request, jsonify
import platform
import subprocess
from pathlib import Path

logger = logging.getLogger('DestinationRoutes')

def register_destination_routes(app, web_server):
    """Register destination management routes with the Flask app"""

    @app.route('/api/file-organizer/destinations', methods=['GET'])
    def fo_get_destinations():
        """Get saved destination folders for the user"""
        try:
            user_id = request.args.get('user_id', 'dev_user')
            conn = web_server._get_file_organizer_db_connection()
            try:
                cursor = conn.execute("""
                    SELECT id, destination_path, file_category
                    FROM destination_mappings
                    WHERE user_id = ?
                    ORDER BY file_category ASC
                """, (user_id,))
                
                rows = cursor.fetchall()
                destinations = [{'id': row[0], 'path': row[1], 'name': row[2]} for row in rows]
                return jsonify({'success': True, 'destinations': destinations})
            finally:
                conn.close()
        except Exception as e:
            logger.error(f"/destinations error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

    @app.route('/api/file-organizer/get-drives', methods=['GET'])
    def fo_get_drives():
        """Get available drives/mount points"""
        try:
            drives = []
            system = platform.system()
            
            if system == 'Windows':
                import string
                for letter in string.ascii_uppercase:
                    drive = f"{letter}:\\"
                    if Path(drive).exists():
                        drives.append({'path': drive, 'name': f"Drive {letter}:", 'type': 'local'})
            else:
                try:
                    result = subprocess.run(['df', '-h'], capture_output=True, text=True)
                    lines = result.stdout.strip().split('\n')[1:]
                    for line in lines:
                        parts = line.split()
                        if len(parts) >= 6:
                            mount_point = parts[5]
                            if mount_point.startswith(('/home', '/media', '/mnt')) or mount_point == '/':
                                drives.append({'path': mount_point, 'name': mount_point, 'type': 'local'})
                except Exception as e:
                    logger.warning(f"Could not get mount points: {e}")
                    common_paths = ['/home', '/media', '/mnt']
                    for path in common_paths:
                        if Path(path).exists():
                            drives.append({'path': path, 'name': path, 'type': 'local'})
            
            return jsonify({'success': True, 'drives': drives})
        except Exception as e:
            logger.error(f"/get-drives error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

    @app.route('/api/file-organizer/delete-destination', methods=['POST'])
    def fo_delete_destination():
        """Delete a saved destination"""
        try:
            data = request.get_json(force=True, silent=True) or {}
            destination_id = data.get('destination_id')
            
            if not destination_id:
                return jsonify({'success': False, 'error': 'destination_id required'}), 400
            
            conn = web_server._get_file_organizer_db_connection()
            try:
                conn.execute("DELETE FROM destination_mappings WHERE id = ?", (destination_id,))
                conn.commit()
                return jsonify({'success': True})
            finally:
                conn.close()
        except Exception as e:
            logger.error(f"/delete-destination error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

