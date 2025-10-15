#!/usr/bin/env python3
"""
File Organizer Routes - Core organization endpoints
Handles: organize, execute, add-granularity
"""

import logging
from flask import request, jsonify
from pathlib import Path

logger = logging.getLogger('FileOrganizerRoutes')


def register_file_organizer_routes(app, web_server):
    """Register file organizer routes with the Flask app"""
    
    @app.route('/api/file-organizer/organize', methods=['POST'])
    def fo_organize():
        try:
            data = request.get_json(force=True, silent=True) or {}
            source_folder = data.get('source_path')
            destination_folder = data.get('destination_path')
            organization_style = data.get('organization_style', 'by_type')

            if not source_folder:
                return jsonify({'success': False, 'error': 'source_path required'}), 400
            if not destination_folder:
                return jsonify({'success': False, 'error': 'destination_path required'}), 400

            # Note: The user_id would typically come from an auth system.
            # For now, we'll use a hardcoded developer ID.
            user_id = "dev_user"

            # Get the File Organizer App instance
            app_manager = web_server.components.get('app_manager')
            if not app_manager:
                return jsonify({'success': False, 'error': 'app_manager_unavailable'}), 500
            
            # For now, bypass the module system and work directly with the database
            # This is a temporary solution until we fix the async module startup
            pass

            # until the AI generator is fully re-integrated.
            from file_organizer.ai_content_analyzer import AIContentAnalyzer
            
            src_path = Path(source_folder).expanduser()
            dest_root = Path(destination_folder).expanduser()
            if not src_path.exists() or not src_path.is_dir():
                return jsonify({'success': False, 'error': f'source_folder not found: {source_folder}'}), 400

            files = [p for p in src_path.iterdir() if p.is_file()]
            file_paths = [str(f) for f in files]
            
            # Use shared batch analysis method (SINGLE SOURCE OF TRUTH)
            batch_result = web_server._batch_analyze_files(file_paths, use_ai=True)
            
            if not batch_result.get('success'):
                return jsonify({
                    'success': False,
                    'error': f"Batch analysis failed: {batch_result.get('error')}"
                }), 503
            
            operations = []
            errors = []
            results = batch_result.get('results', {})
            
            for f in files:
                file_path = str(f)
                file_result = results.get(file_path)
                
                if not file_result:
                    error_msg = f"No analysis result for {f.name}"
                    logger.warning(error_msg)
                    errors.append({
                        'file': file_path,
                        'error': 'No analysis result returned'
                    })
                    continue
                
                suggested_folder = file_result.get('suggested_folder', 'Other')
                # NO REASON - will be generated on-demand when user asks "why?"
                
                dest_path = dest_root / suggested_folder / f.name
                operations.append({
                    'type': 'move',
                    'source': file_path,
                    'destination': str(dest_path),
                    # reason will be generated on-demand via /explain endpoint
                })
            
            # If ALL files failed, return error
            if not operations and errors:
                return jsonify({
                    'success': False, 
                    'error': 'All files failed to analyze',
                    'details': errors
                }), 503

            # Create a persistent analysis session directly in the database
            import uuid
            import json
            from datetime import datetime
            
            analysis_id = str(uuid.uuid4())
            now = datetime.now().isoformat()
            
            # Connect to the database using shared method
            conn = web_server._get_file_organizer_db_connection()
            
            try:
                # Insert analysis session
                conn.execute("""
                    INSERT INTO analysis_sessions 
                    (analysis_id, user_id, source_path, destination_path, organization_style, 
                     file_count, created_at, updated_at, status, metadata)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    analysis_id,
                    user_id,
                    source_folder,
                    destination_folder,
                    organization_style,
                    len(operations),
                    now,
                    now,
                    'pending',
                    json.dumps({
                        'total_files': len(files),
                        'successful_operations': len(operations),
                        'failed_files': len(errors)
                    })
                ))
                
                # Insert operations
                for idx, op in enumerate(operations):
                    operation_id = f"{analysis_id}_op_{idx}"
                    conn.execute("""
                        INSERT INTO analysis_operations
                        (operation_id, analysis_id, operation_type, source_path, destination_path,
                         file_name, operation_status, created_at, metadata)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, (
                        operation_id,
                        analysis_id,
                        op['type'],
                        op['source'],
                        op['destination'],
                        Path(op['source']).name,
                        'pending',
                        now,
                        json.dumps({})
                    ))
                    # Add operation_id to response
                    op['operation_id'] = operation_id
                    op['status'] = 'pending'
                
                conn.commit()
                
                response = {
                    'success': True,
                    'analysis_id': analysis_id,
                    'operations': operations
                }
                
                # Include errors if any (partial success)
                if errors:
                    response['errors'] = errors
                
                return jsonify(response)
                
            except Exception as db_error:
                conn.rollback()
                logger.error(f"Database error: {db_error}", exc_info=True)
                return jsonify({'success': False, 'error': f'Database error: {str(db_error)}'}), 500
            finally:
                conn.close()
                
        except Exception as e:
            logger.error(f"/organize error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

    @app.route('/api/file-organizer/execute', methods=['POST'])
    def fo_execute_ops():
        """Execute approved file operations"""
        try:
            data = request.get_json(force=True, silent=True) or {}
            analysis_id = data.get('analysis_id')
            operation_ids = data.get('operation_ids', [])
            
            if not analysis_id:
                return jsonify({'success': False, 'error': 'analysis_id required'}), 400
            
            # Direct database access
            conn = web_server._get_file_organizer_db_connection()
            
            try:
                results = []
                for op_id in operation_ids:
                    # Get operation details
                    cursor = conn.execute("""
                        SELECT operation_type, source_path, destination_path
                        FROM analysis_operations
                        WHERE operation_id = ? AND analysis_id = ?
                    """, (op_id, analysis_id))
                    
                    row = cursor.fetchone()
                    if not row:
                        results.append({'operation_id': op_id, 'success': False, 'error': 'Operation not found'})
                        continue
                    
                    op_type, source, dest = row
                    
                    # Execute the operation
                    import shutil
                    import os
                    
                    try:
                        # Create destination directory if needed
                        dest_dir = Path(dest).parent
                        dest_dir.mkdir(parents=True, exist_ok=True)
                        
                        if op_type == 'move':
                            shutil.move(source, dest)
                        elif op_type == 'copy':
                            shutil.copy2(source, dest)
                        
                        # Update operation status
                        from datetime import datetime
                        conn.execute("""
                            UPDATE analysis_operations
                            SET operation_status = 'applied', applied_at = ?
                            WHERE operation_id = ?
                        """, (datetime.now().isoformat(), op_id))
                        
                        results.append({'operation_id': op_id, 'success': True})
                        
                    except Exception as exec_error:
                        logger.error(f"Execution error for {op_id}: {exec_error}")
                        results.append({'operation_id': op_id, 'success': False, 'error': str(exec_error)})
                
                conn.commit()
                return jsonify({'success': True, 'results': results})
                
            except Exception as e:
                conn.rollback()
                raise e
            finally:
                conn.close()
                
        except Exception as e:
            logger.error(f"/execute error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

    @app.route('/api/file-organizer/add-granularity', methods=['POST'])
    def fo_add_granularity():
        """
        Add ONE level of granularity to files in a specific folder.
        AI decides which files should go into subfolders and which should stay.
        """
        try:
            data = request.get_json(force=True, silent=True) or {}
            folder_path = data.get('folder_path')
            analysis_id = data.get('analysis_id')  # Optional: to track this as part of an analysis session
            
            if not folder_path:
                return jsonify({'success': False, 'error': 'folder_path is required'}), 400
            
            import os
            
            folder = Path(folder_path)
            if not folder.exists() or not folder.is_dir():
                return jsonify({'success': False, 'error': f'Folder does not exist: {folder_path}'}), 404
            
            # Get all items (files and subfolders) in this folder
            items = []
            for item in folder.iterdir():
                items.append({
                    'path': str(item),
                    'name': item.name,
                    'is_file': item.is_file(),
                    'is_dir': item.is_dir(),
                    'extension': item.suffix.lower() if item.is_file() else None
                })
            
            if not items:
                return jsonify({
                    'success': True,
                    'operations': [],
                    'message': 'Folder is empty'
                })
            
            # Call AI to add granularity
            from file_organizer.ai_content_analyzer import AIContentAnalyzer
            shared_services = web_server.components.get('shared_services')
            analyzer = AIContentAnalyzer(shared_services=shared_services)
            
            result = analyzer.add_granularity(folder_path, items)
            
            if not result.get('success'):
                return jsonify(result), 503
            
            # Convert AI suggestions into FileOperation format
            operations = []
            for item_path, suggestion in result.get('suggestions', {}).items():
                subfolder = suggestion.get('subfolder')
                
                # If subfolder is None or empty, skip (file stays in current location)
                if not subfolder:
                    continue
                
                # Create operation
                item_name = Path(item_path).name
                new_destination = str(folder / subfolder / item_name)
                
                operations.append({
                    'type': 'move',
                    'source': item_path,
                    'destination': new_destination,
                    # reason will be generated on-demand
                })
            
            return jsonify({
                'success': True,
                'operations': operations,
                'folder': folder_path,
                'items_analyzed': len(items),
                'items_to_organize': len(operations)
            })
            
        except Exception as e:
            logger.error(f"/add-granularity error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500


