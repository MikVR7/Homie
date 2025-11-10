#!/usr/bin/env python3
"""
Drive Routes - Drive management endpoints
"""

import logging
import os
from flask import request, jsonify

logger = logging.getLogger('DriveRoutes')


def register_drive_routes(app, web_server):
    """Register drive management routes with the Flask app"""

    def _get_drive_manager():
        """Get DriveManager instance"""
        try:
            file_organizer_app = web_server.app_manager.get_module('file_organizer')
            if not file_organizer_app:
                logger.warning("FileOrganizerApp not found")
                return None
                
            # Check if module is started
            module_info = web_server.app_manager.registered_modules.get('file_organizer', {})
            if not module_info.get('started', False):
                logger.warning("FileOrganizerApp not started - module needs to be started first")
                return None
            
            if hasattr(file_organizer_app, 'path_memory_manager'):
                path_mgr = file_organizer_app.path_memory_manager
                if hasattr(path_mgr, '_drive_manager'):
                    return path_mgr._drive_manager
                else:
                    logger.warning("PathMemoryManager has no _drive_manager attribute")
            else:
                logger.warning("FileOrganizerApp has no path_memory_manager attribute")
        except Exception as e:
            logger.error(f"Could not get DriveManager: {e}", exc_info=True)
        return None

    def _get_available_space(mount_point: str) -> float:
        """Get available space in GB for a mount point"""
        try:
            if not os.path.exists(mount_point):
                return None
            
            stat = os.statvfs(mount_point)
            available_bytes = stat.f_bavail * stat.f_frsize
            available_gb = available_bytes / (1024 ** 3)
            return round(available_gb, 1)
        except Exception as e:
            logger.debug(f"Could not get available space for {mount_point}: {e}")
            return None

    @app.route('/api/file-organizer/drives', methods=['GET', 'POST'])
    def fo_drives():
        """Get or register drives (deprecated for POST - use /drives/batch instead)"""
        if request.method == 'GET':
            return _get_drives()
        else:
            return _register_drive()

    @app.route('/api/file-organizer/drives/batch', methods=['POST'])
    def fo_drives_batch():
        """Register multiple drives in a single request"""
        return _register_drives_batch()

    def _get_drives():
        """Retrieve all known drives for current user"""
        try:
            user_id = request.args.get('user_id', 'dev_user')
            
            drive_manager = _get_drive_manager()
            
            if not drive_manager:
                return jsonify({
                    'success': False,
                    'error': 'DriveManager not available'
                }), 500
            
            # Get all drives for user
            drives = drive_manager.get_drives(user_id)
            
            # Format response
            result = []
            for drive in drives:
                drive_dict = {
                    'id': drive.id,
                    'unique_identifier': drive.unique_identifier,
                    'mount_point': drive.mount_point,
                    'volume_label': drive.volume_label,
                    'drive_type': drive.drive_type,
                    'cloud_provider': drive.cloud_provider,
                    'is_available': drive.is_available,
                    'last_seen_at': drive.last_seen_at.isoformat() if drive.last_seen_at else None,
                    'created_at': drive.created_at.isoformat() if drive.created_at else None
                }
                
                # Add available space
                available_space = _get_available_space(drive.mount_point)
                if available_space is not None:
                    drive_dict['available_space_gb'] = available_space
                
                # Add client mounts information
                if drive.client_mounts:
                    drive_dict['client_mounts'] = []
                    for mount in drive.client_mounts:
                        mount_dict = {
                            'client_id': mount.client_id,
                            'mount_point': mount.mount_point,
                            'is_available': mount.is_available,
                            'last_seen_at': mount.last_seen_at.isoformat() if mount.last_seen_at else None
                        }
                        # Get space for this specific mount point
                        mount_space = _get_available_space(mount.mount_point)
                        if mount_space is not None:
                            mount_dict['available_space_gb'] = mount_space
                        drive_dict['client_mounts'].append(mount_dict)
                
                result.append(drive_dict)
            
            return jsonify({'success': True, 'drives': result})
            
        except Exception as e:
            logger.error(f"GET /drives error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

    def _register_drive():
        """Register a new drive detected by frontend (deprecated - use batch endpoint)"""
        try:
            data = request.get_json(force=True, silent=True) or {}
            user_id = data.get('user_id', 'dev_user')
            client_id = data.get('client_id', 'default_client')
            
            # Log what we received for debugging
            logger.debug(f"Drive registration request: {data}")
            
            # Extract drive info
            unique_id = data.get('unique_identifier')
            mount_point = data.get('mount_point')
            
            # Validate mount_point first
            if not mount_point:
                logger.warning(f"Drive registration missing mount_point: {data}")
                return jsonify({
                    'success': False,
                    'error': 'mount_point is required'
                }), 400
            
            # If unique_identifier is empty or same as mount_point, use mount_point as identifier
            # This is common for internal drives where we don't have a hardware UUID
            if not unique_id or unique_id == mount_point:
                unique_id = f"mount:{mount_point}"  # Prefix to make it clear it's a mount-based ID
            
            drive_info = {
                'unique_identifier': unique_id,
                'mount_point': mount_point,
                'volume_label': data.get('volume_label') or mount_point,  # Use mount_point as fallback label
                'drive_type': data.get('drive_type'),
                'cloud_provider': data.get('cloud_provider')
            }
            
            if not drive_info['drive_type']:
                return jsonify({
                    'success': False,
                    'error': 'drive_type is required'
                }), 400
            
            drive_manager = _get_drive_manager()
            
            if not drive_manager:
                return jsonify({
                    'success': False,
                    'error': 'DriveManager not available'
                }), 500
            
            # Register drive
            drive = drive_manager.register_drive(user_id, drive_info, client_id)
            
            if not drive:
                return jsonify({
                    'success': False,
                    'error': 'Failed to register drive'
                }), 500
            
            # Format response
            result = {
                'id': drive.id,
                'unique_identifier': drive.unique_identifier,
                'mount_point': drive.mount_point,
                'volume_label': drive.volume_label,
                'drive_type': drive.drive_type,
                'cloud_provider': drive.cloud_provider,
                'is_available': drive.is_available,
                'last_seen_at': drive.last_seen_at.isoformat() if drive.last_seen_at else None,
                'created_at': drive.created_at.isoformat() if drive.created_at else None
            }
            
            # Add available space
            available_space = _get_available_space(drive.mount_point)
            if available_space is not None:
                result['available_space_gb'] = available_space
            
            # Add client mounts
            if drive.client_mounts:
                result['client_mounts'] = []
                for mount in drive.client_mounts:
                    result['client_mounts'].append({
                        'client_id': mount.client_id,
                        'mount_point': mount.mount_point,
                        'is_available': mount.is_available,
                        'last_seen_at': mount.last_seen_at.isoformat() if mount.last_seen_at else None
                    })
            
            return jsonify({'success': True, 'drive': result}), 201
            
        except Exception as e:
            logger.error(f"POST /drives error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

    def _register_drives_batch():
        """Register multiple drives in a single request with transaction support"""
        try:
            data = request.get_json(force=True, silent=True) or {}
            user_id = data.get('user_id', 'dev_user')
            client_id = data.get('client_id', 'default_client')
            drives_data = data.get('drives', [])
            
            # Validate input
            if not isinstance(drives_data, list):
                return jsonify({
                    'success': False,
                    'error': 'drives must be an array'
                }), 400
            
            if not drives_data:
                return jsonify({
                    'success': False,
                    'error': 'drives array cannot be empty'
                }), 400
            
            logger.info(f"Batch drive registration: {len(drives_data)} drives from client {client_id}")
            
            drive_manager = _get_drive_manager()
            
            if not drive_manager:
                return jsonify({
                    'success': False,
                    'error': 'DriveManager not available'
                }), 500
            
            # Process all drives in a batch
            registered_drives = drive_manager.register_drives_batch(user_id, drives_data, client_id)
            
            if registered_drives is None:
                return jsonify({
                    'success': False,
                    'error': 'Failed to register drives'
                }), 500
            
            # Format response
            result = []
            for drive in registered_drives:
                drive_dict = {
                    'id': drive.id,
                    'unique_identifier': drive.unique_identifier,
                    'mount_point': drive.mount_point,
                    'volume_label': drive.volume_label,
                    'drive_type': drive.drive_type,
                    'cloud_provider': drive.cloud_provider,
                    'is_available': drive.is_available,
                    'last_seen_at': drive.last_seen_at.isoformat() if drive.last_seen_at else None,
                    'created_at': drive.created_at.isoformat() if drive.created_at else None
                }
                
                # Add available space
                available_space = _get_available_space(drive.mount_point)
                if available_space is not None:
                    drive_dict['available_space_gb'] = available_space
                
                # Add client mounts
                if drive.client_mounts:
                    drive_dict['client_mounts'] = []
                    for mount in drive.client_mounts:
                        drive_dict['client_mounts'].append({
                            'client_id': mount.client_id,
                            'mount_point': mount.mount_point,
                            'is_available': mount.is_available,
                            'last_seen_at': mount.last_seen_at.isoformat() if mount.last_seen_at else None
                        })
                
                result.append(drive_dict)
            
            return jsonify({
                'success': True,
                'drives': result,
                'count': len(result)
            }), 201
            
        except Exception as e:
            logger.error(f"POST /drives/batch error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

    @app.route('/api/file-organizer/drives/<drive_id>', methods=['GET'])
    def fo_get_drive(drive_id):
        """Get a specific drive by ID"""
        try:
            user_id = request.args.get('user_id', 'dev_user')
            
            drive_manager = _get_drive_manager()
            
            if not drive_manager:
                return jsonify({
                    'success': False,
                    'error': 'DriveManager not available'
                }), 500
            
            # Get all drives and find the one with matching ID
            drives = drive_manager.get_drives(user_id)
            drive = next((d for d in drives if d.id == drive_id), None)
            
            if not drive:
                return jsonify({
                    'success': False,
                    'error': 'Drive not found'
                }), 404
            
            # Format response
            result = {
                'id': drive.id,
                'unique_identifier': drive.unique_identifier,
                'mount_point': drive.mount_point,
                'volume_label': drive.volume_label,
                'drive_type': drive.drive_type,
                'cloud_provider': drive.cloud_provider,
                'is_available': drive.is_available,
                'last_seen_at': drive.last_seen_at.isoformat() if drive.last_seen_at else None,
                'created_at': drive.created_at.isoformat() if drive.created_at else None
            }
            
            # Add available space
            available_space = _get_available_space(drive.mount_point)
            if available_space is not None:
                result['available_space_gb'] = available_space
            
            # Add client mounts
            if drive.client_mounts:
                result['client_mounts'] = []
                for mount in drive.client_mounts:
                    mount_dict = {
                        'client_id': mount.client_id,
                        'mount_point': mount.mount_point,
                        'is_available': mount.is_available,
                        'last_seen_at': mount.last_seen_at.isoformat() if mount.last_seen_at else None
                    }
                    mount_space = _get_available_space(mount.mount_point)
                    if mount_space is not None:
                        mount_dict['available_space_gb'] = mount_space
                    result['client_mounts'].append(mount_dict)
            
            return jsonify({'success': True, 'drive': result})
            
        except Exception as e:
            logger.error(f"GET /drives/{drive_id} error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

    @app.route('/api/file-organizer/drives/availability', methods=['PUT'])
    def fo_update_drive_availability():
        """Update drive availability status"""
        try:
            data = request.get_json(force=True, silent=True) or {}
            user_id = data.get('user_id', 'dev_user')
            client_id = data.get('client_id', 'default_client')
            unique_identifier = data.get('unique_identifier')
            is_available = data.get('is_available')
            
            # Validate required fields
            if not unique_identifier:
                return jsonify({
                    'success': False,
                    'error': 'unique_identifier is required'
                }), 400
            
            if is_available is None:
                return jsonify({
                    'success': False,
                    'error': 'is_available is required'
                }), 400
            
            drive_manager = _get_drive_manager()
            
            if not drive_manager:
                return jsonify({
                    'success': False,
                    'error': 'DriveManager not available'
                }), 500
            
            # Update availability
            success = drive_manager.update_drive_availability(
                user_id, unique_identifier, is_available, client_id
            )
            
            if success:
                return jsonify({
                    'success': True,
                    'message': 'Drive availability updated'
                })
            else:
                return jsonify({
                    'success': False,
                    'error': 'Drive not found'
                }), 404
                
        except Exception as e:
            logger.error(f"PUT /drives/availability error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500
