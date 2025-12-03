#!/usr/bin/env python3
"""
Destination Routes - Destination management endpoints
"""

import logging
import os
from flask import request, jsonify
import platform
import subprocess
from pathlib import Path

logger = logging.getLogger('DestinationRoutes')

def register_destination_routes(app, web_server):
    """Register destination management routes with the Flask app"""

    def _get_destination_manager():
        """Get DestinationMemoryManager instance"""
        try:
            file_organizer_app = web_server.app_manager.get_module('file_organizer')
            if file_organizer_app and hasattr(file_organizer_app, 'path_memory_manager'):
                path_mgr = file_organizer_app.path_memory_manager
                if hasattr(path_mgr, '_destination_manager'):
                    return path_mgr._destination_manager
        except Exception as e:
            logger.warning(f"Could not get DestinationMemoryManager: {e}")
        return None

    def _get_drive_manager():
        """Get DriveManager instance"""
        try:
            file_organizer_app = web_server.app_manager.get_module('file_organizer')
            if file_organizer_app and hasattr(file_organizer_app, 'path_memory_manager'):
                path_mgr = file_organizer_app.path_memory_manager
                if hasattr(path_mgr, '_drive_manager'):
                    return path_mgr._drive_manager
        except Exception as e:
            logger.warning(f"Could not get DriveManager: {e}")
        return None

    @app.route('/api/file-organizer/destinations', methods=['GET', 'POST'])
    def fo_destinations():
        """Get or add destinations"""
        if request.method == 'GET':
            return _get_destinations()
        else:
            return _add_destination()

    def _get_destinations():
        """Get all active destinations for current user"""
        try:
            user_id = request.args.get('user_id', 'dev_user')
            client_id = request.args.get('client_id', 'default_client')
            
            dest_manager = _get_destination_manager()
            drive_manager = _get_drive_manager()
            
            if not dest_manager:
                # Fallback to legacy method
                logger.warning("Using legacy destination retrieval")
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
            
            # Use new DestinationMemoryManager
            destinations = dest_manager.get_destinations_for_client(user_id, client_id)
            
            # Format response
            result = []
            for dest in destinations:
                dest_dict = {
                    'id': dest.id,
                    'path': dest.path,
                    'category': dest.category,
                    'color': dest.color,  # Include color
                    'drive_id': dest.drive_id,
                    'usage_count': dest.usage_count,
                    'last_used_at': dest.last_used_at.isoformat() if dest.last_used_at else None,
                    'created_at': dest.created_at.isoformat() if dest.created_at else None,
                    'is_active': dest.is_active
                }
                
                # Add drive information if available
                if drive_manager and dest.drive_id:
                    try:
                        # Get drive info from client drives
                        client_drives = drive_manager.get_client_drives(user_id, client_id)
                        drive = next((d for d in client_drives if d.id == dest.drive_id), None)
                        if drive:
                            dest_dict['drive_type'] = drive.drive_type
                            dest_dict['drive_label'] = drive.volume_label
                            dest_dict['cloud_provider'] = drive.cloud_provider
                    except Exception as e:
                        logger.debug(f"Could not get drive info: {e}")
                
                result.append(dest_dict)
            
            return jsonify({'success': True, 'destinations': result})
            
        except Exception as e:
            logger.error(f"GET /destinations error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

    def _add_destination():
        """Manually add a new destination"""
        try:
            data = request.get_json(force=True, silent=True) or {}
            user_id = data.get('user_id', 'dev_user')
            client_id = data.get('client_id', 'default_client')
            path = data.get('path')
            category = data.get('category')
            color = data.get('color')  # Optional color from frontend
            
            # Validate required fields
            if not path:
                return jsonify({'success': False, 'error': 'path is required'}), 400
            if not category:
                return jsonify({'success': False, 'error': 'category is required'}), 400
            
            # Validate path exists
            if not os.path.exists(path):
                return jsonify({'success': False, 'error': f'Path does not exist: {path}'}), 400
            
            dest_manager = _get_destination_manager()
            drive_manager = _get_drive_manager()
            
            if not dest_manager:
                return jsonify({'success': False, 'error': 'DestinationMemoryManager not available'}), 500
            
            # Determine drive_id
            drive_id = None
            if drive_manager:
                try:
                    drive = drive_manager.get_drive_for_path(user_id, path, client_id)
                    if drive:
                        drive_id = drive.id
                except Exception as e:
                    logger.warning(f"Could not determine drive_id: {e}")
            
            # Add destination (with optional color)
            destination = dest_manager.add_destination(user_id, path, category, client_id, drive_id, color)
            
            if not destination:
                return jsonify({'success': False, 'error': 'Failed to add destination'}), 500
            
            # Format response
            result = {
                'id': destination.id,
                'path': destination.path,
                'category': destination.category,
                'color': destination.color,  # Include color in response
                'drive_id': destination.drive_id,
                'usage_count': destination.usage_count,
                'created_at': destination.created_at.isoformat() if destination.created_at else None,
                'is_active': destination.is_active
            }
            
            return jsonify({'success': True, 'destination': result}), 201
            
        except Exception as e:
            logger.error(f"POST /destinations error: {e}", exc_info=True)
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

    @app.route('/api/file-organizer/destinations/<destination_id>', methods=['DELETE', 'PUT'])
    def fo_manage_destination(destination_id):
        """Update or remove a destination"""
        if request.method == 'DELETE':
            return _delete_destination(destination_id)
        else:
            return _update_destination(destination_id)
    
    def _delete_destination(destination_id):
        """Remove a destination (soft delete)"""
        try:
            user_id = request.args.get('user_id', 'dev_user')
            
            if not destination_id:
                return jsonify({'success': False, 'error': 'destination_id required'}), 400
            
            dest_manager = _get_destination_manager()
            
            if not dest_manager:
                # Fallback to legacy method
                logger.warning("Using legacy destination deletion")
                conn = web_server._get_file_organizer_db_connection()
                try:
                    conn.execute("DELETE FROM destination_mappings WHERE id = ?", (destination_id,))
                    conn.commit()
                    return jsonify({'success': True, 'message': 'Destination removed successfully'})
                finally:
                    conn.close()
            
            # Use new DestinationMemoryManager (soft delete)
            success = dest_manager.remove_destination(user_id, destination_id)
            
            if success:
                return jsonify({'success': True, 'message': 'Destination removed successfully'})
            else:
                return jsonify({'success': False, 'error': 'Destination not found'}), 404
                
        except Exception as e:
            logger.error(f"DELETE /destinations/{destination_id} error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500
    
    def _update_destination(destination_id):
        """Update a destination's properties"""
        try:
            data = request.get_json(force=True, silent=True) or {}
            user_id = data.get('user_id', 'dev_user')
            path = data.get('path')
            category = data.get('category')
            color = data.get('color')
            
            if not destination_id:
                return jsonify({'success': False, 'error': 'destination_id required'}), 400
            
            dest_manager = _get_destination_manager()
            
            if not dest_manager:
                return jsonify({'success': False, 'error': 'DestinationMemoryManager not available'}), 500
            
            # Update destination
            destination = dest_manager.update_destination(
                user_id=user_id,
                destination_id=destination_id,
                path=path,
                category=category,
                color=color
            )
            
            if not destination:
                return jsonify({'success': False, 'error': 'Failed to update destination or destination not found'}), 404
            
            # Format response
            result = {
                'id': destination.id,
                'path': destination.path,
                'category': destination.category,
                'color': destination.color,
                'drive_id': destination.drive_id,
                'usage_count': destination.usage_count,
                'last_used_at': destination.last_used_at.isoformat() if destination.last_used_at else None,
                'created_at': destination.created_at.isoformat() if destination.created_at else None,
                'is_active': destination.is_active
            }
            
            return jsonify({'success': True, 'destination': result})
            
        except Exception as e:
            logger.error(f"PUT /destinations/{destination_id} error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

    @app.route('/api/file-organizer/destinations/capture', methods=['POST'])
    def fo_capture_destinations():
        """Auto-capture destinations from file operations"""
        try:
            data = request.get_json(force=True, silent=True) or {}
            user_id = data.get('user_id', 'dev_user')
            client_id = data.get('client_id', 'default_client')
            operations = data.get('operations', [])
            
            if not operations:
                return jsonify({'success': True, 'destinations': []})
            
            logger.info(f"📸 Capture request received: {len(operations)} operations")
            
            dest_manager = _get_destination_manager()
            drive_manager = _get_drive_manager()
            
            if not dest_manager:
                logger.error("DestinationMemoryManager not available")
                return jsonify({'success': False, 'error': 'DestinationMemoryManager not available'}), 500
            
            # Convert operations to the format expected by auto_capture
            formatted_ops = []
            for op in operations:
                formatted_ops.append({
                    'source': op.get('source'),
                    'destination': op.get('destination'),
                    'type': op.get('type', 'move')
                })
            
            logger.info(f"🔍 Formatted operations: {formatted_ops}")
            
            # Auto-capture destinations
            captured_destinations = dest_manager.auto_capture_destinations(
                user_id=user_id,
                operations=formatted_ops,
                client_id=client_id
            )
            
            logger.info(f"✅ Captured {len(captured_destinations)} destinations")
            
            # Format response
            result = []
            for dest in captured_destinations:
                dest_dict = {
                    'id': dest.id,
                    'path': dest.path,
                    'category': dest.category,
                    'color': dest.color,  # Include color
                    'drive_id': dest.drive_id,
                    'usage_count': dest.usage_count,
                    'last_used_at': dest.last_used_at.isoformat() if dest.last_used_at else None,
                    'created_at': dest.created_at.isoformat() if dest.created_at else None,
                    'is_active': dest.is_active
                }
                
                # Add drive information if available
                if drive_manager and dest.drive_id:
                    try:
                        client_drives = drive_manager.get_client_drives(user_id, client_id)
                        drive = next((d for d in client_drives if d.id == dest.drive_id), None)
                        if drive:
                            dest_dict['drive_type'] = drive.drive_type
                            dest_dict['drive_label'] = drive.volume_label
                            dest_dict['cloud_provider'] = drive.cloud_provider
                            dest_dict['is_available'] = drive.is_available
                    except Exception as e:
                        logger.debug(f"Could not get drive info: {e}")
                
                result.append(dest_dict)
            
            return jsonify({'success': True, 'destinations': result})
            
        except Exception as e:
            logger.error(f"POST /destinations/capture error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500


    # Legacy endpoint for backward compatibility
    @app.route('/api/file-organizer/delete-destination', methods=['POST'])
    def fo_delete_destination_legacy():
        """Delete a saved destination (legacy endpoint)"""
        try:
            data = request.get_json(force=True, silent=True) or {}
            destination_id = data.get('destination_id')
            user_id = data.get('user_id', 'dev_user')
            
            if not destination_id:
                return jsonify({'success': False, 'error': 'destination_id required'}), 400
            
            dest_manager = _get_destination_manager()
            
            if not dest_manager:
                conn = web_server._get_file_organizer_db_connection()
                try:
                    conn.execute("DELETE FROM destination_mappings WHERE id = ?", (destination_id,))
                    conn.commit()
                    return jsonify({'success': True})
                finally:
                    conn.close()
            
            success = dest_manager.remove_destination(user_id, destination_id)
            
            if success:
                return jsonify({'success': True})
            else:
                return jsonify({'success': False, 'error': 'Destination not found'}), 404
                
        except Exception as e:
            logger.error(f"/delete-destination error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

