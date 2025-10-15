#!/usr/bin/env python3
"""
Operation Routes - Operation management endpoints
Handles: get-analyses, update-operation-status, batch-update-status
"""

import logging
from flask import request, jsonify
from datetime import datetime

logger = logging.getLogger('OperationRoutes')


def register_operation_routes(app, web_server):
    """Register operation management routes with the Flask app"""
    
    @app.route('/api/file-organizer/get-analyses', methods=['GET'])
    def fo_get_analyses():
        """Get all analysis sessions for the current user"""
        try:
            user_id = request.args.get('user_id', 'dev_user')
            
            conn = web_server._get_file_organizer_db_connection()
            
            try:
                cursor = conn.execute("""
                    SELECT analysis_id, source_path, destination_path, organization_style,
                           file_count, created_at, updated_at, status, metadata
                    FROM analysis_sessions
                    WHERE user_id = ?
                    ORDER BY created_at DESC
                """, (user_id,))
                
                analyses = []
                for row in cursor.fetchall():
                    import json
                    analyses.append({
                        'analysis_id': row[0],
                        'source_path': row[1],
                        'destination_path': row[2],
                        'organization_style': row[3],
                        'file_count': row[4],
                        'created_at': row[5],
                        'updated_at': row[6],
                        'status': row[7],
                        'metadata': json.loads(row[8]) if row[8] else {}
                    })
                
                return jsonify({'success': True, 'analyses': analyses})
                
            finally:
                conn.close()
                
        except Exception as e:
            logger.error(f"/get-analyses error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

    @app.route('/api/file-organizer/update-operation-status', methods=['POST'])
    def fo_update_operation_status():
        """Update the status of a specific operation"""
        try:
            data = request.get_json(force=True, silent=True) or {}
            operation_id = data.get('operation_id')
            new_status = data.get('status')
            
            if not operation_id or not new_status:
                return jsonify({'success': False, 'error': 'operation_id and status required'}), 400
            
            conn = web_server._get_file_organizer_db_connection()
            
            try:
                now = datetime.now().isoformat()
                conn.execute("""
                    UPDATE analysis_operations
                    SET operation_status = ?, updated_at = ?
                    WHERE operation_id = ?
                """, (new_status, now, operation_id))
                
                conn.commit()
                return jsonify({'success': True})
                
            except Exception as e:
                conn.rollback()
                raise e
            finally:
                conn.close()
                
        except Exception as e:
            logger.error(f"/update-operation-status error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

    @app.route('/api/file-organizer/batch-update-status', methods=['POST'])
    def fo_batch_update_status():
        """Update status for multiple operations at once"""
        try:
            data = request.get_json(force=True, silent=True) or {}
            updates = data.get('updates', [])
            
            if not updates:
                return jsonify({'success': False, 'error': 'updates array required'}), 400
            
            conn = web_server._get_file_organizer_db_connection()
            
            try:
                now = datetime.now().isoformat()
                for update in updates:
                    operation_id = update.get('operation_id')
                    new_status = update.get('status')
                    
                    if operation_id and new_status:
                        conn.execute("""
                            UPDATE analysis_operations
                            SET operation_status = ?, updated_at = ?
                            WHERE operation_id = ?
                        """, (new_status, now, operation_id))
                
                conn.commit()
                return jsonify({'success': True})
                
            except Exception as e:
                conn.rollback()
                raise e
            finally:
                conn.close()
                
        except Exception as e:
            logger.error(f"/batch-update-status error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

