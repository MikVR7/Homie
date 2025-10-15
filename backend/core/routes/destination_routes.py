#!/usr/bin/env python3
"""
Destination Routes - Destination management endpoints
Handles: get-drives, get-destinations, delete-destination
"""

import logging
from flask import request, jsonify
import platform
import subprocess
from pathlib import Path

logger = logging.getLogger('DestinationRoutes')


def register_destination_routes(app, web_server):
    """Register destination management routes with the Flask app"""
    
    @app.route('/api/file-organizer/get-drives', methods=['GET'])
    def fo_get_drives():
        """Get available drives/mount points"""
        try:
            drives = []
            system = platform.system()
            
            if system == 'Windows':
                # Windows: Get drive letters
                import string
                from pathlib import Path
                for letter in string.ascii_uppercase:
                    drive = f"{letter}:\\"
                    if Path(drive).exists():
                        drives.append({
                            'path': drive,
                            'name': f"Drive {letter}:",
                            'type': 'local'
                        })
            else:
                # Linux/Mac: Get mount points
                try:
                    result = subprocess.run(['df', '-h'], capture_output=True, text=True)
                    lines = result.stdout.strip().split('\n')[1:]  # Skip header
                    
                    for line in lines:
                        parts = line.split()
                        if len(parts) >= 6:
                            mount_point = parts[5]
                            # Filter out system mounts
                            if mount_point.startswith('/home') or mount_point.startswith('/media') or mount_point.startswith('/mnt') or mount_point == '/':
                                drives.append({
                                    'path': mount_point,
                                    'name': mount_point,
                                    'type': 'local'
                                })
                except Exception as e:
                    logger.warning(f"Could not get mount points: {e}")
                    # Fallback to common locations
                    common_paths = ['/home', '/media', '/mnt']
                    for path in common_paths:
                        if Path(path).exists():
                            drives.append({
                                'path': path,
                                'name': path,
                                'type': 'local'
                            })
            
            return jsonify({'success': True, 'drives': drives})
            
        except Exception as e:
            logger.error(f"/get-drives error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

    @app.route('/api/file-organizer/get-destinations', methods=['GET'])
    def fo_get_destinations():
        """Get saved destination folders for the user"""
        try:
            user_id = request.args.get('user_id', 'dev_user')
            
            conn = web_server._get_file_organizer_db_connection()
            
            try:
                cursor = conn.execute("""
                    SELECT destination_id, path, name, is_default, created_at
                    FROM saved_destinations
                    WHERE user_id = ?
                    ORDER BY is_default DESC, created_at DESC
                """, (user_id,))
                
                destinations = []
                for row in cursor.fetchall():
                    destinations.append({
                        'destination_id': row[0],
                        'path': row[1],
                        'name': row[2],
                        'is_default': bool(row[3]),
                        'created_at': row[4]
                    })
                
                return jsonify({'success': True, 'destinations': destinations})
                
            finally:
                conn.close()
                
        except Exception as e:
            logger.error(f"/get-destinations error: {e}", exc_info=True)
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
                conn.execute("""
                    DELETE FROM saved_destinations
                    WHERE destination_id = ?
                """, (destination_id,))
                
                conn.commit()
                return jsonify({'success': True})
                
            except Exception as e:
                conn.rollback()
                raise e
            finally:
                conn.close()
                
        except Exception as e:
            logger.error(f"/delete-destination error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

