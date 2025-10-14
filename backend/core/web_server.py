#!/usr/bin/env python3
"""
Web Server Component - Flask + SocketIO Server
Handles HTTP API and WebSocket connections independently
"""

import logging
from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_socketio import SocketIO, emit
from datetime import datetime

logger = logging.getLogger('WebServer')


class WebServer:
    """
    Web server component that provides HTTP API and WebSocket endpoints
    
    This component ONLY handles:
    - HTTP API routes
    - WebSocket connection events
    - Routing requests to appropriate components
    
    It does NOT handle:
    - Business logic
    - User management
    - Module-specific functionality
    """
    
    def __init__(self, components):
        self.components = components
        
        # Web server configuration - modify these values here
        self.host = '0.0.0.0'
        self.port = 8000
        
        self.app = None
        self.socketio = None
        self._server_task = None
        self._server_thread = None
        self._shutdown_flag = False
        
        logger.info(f"🌐 Web Server initialized for {self.host}:{self.port}")
    
    async def start(self):
        """Start the Flask + SocketIO server (non-blocking)."""
        try:
            # Create Flask app
            self.app = Flask(__name__)
            self.app.config['SECRET_KEY'] = 'homie-dev-secret-key'
            CORS(self.app)
            
            # Initialize SocketIO (use gevent for clean shutdown)
            self.socketio = SocketIO(self.app, cors_allowed_origins="*", async_mode='gevent')
            
            # Connect SocketIO to event bus
            if 'event_bus' in self.components:
                self.components['event_bus'].set_socketio(self.socketio)
            
            # Setup routes and handlers
            self._setup_http_routes()
            self._setup_websocket_handlers()
            
            logger.info(f"🚀 Web Server starting on {self.host}:{self.port}")
            
            # Start server directly (gevent handles signals properly)
            logger.info("🚀 Starting Flask-SocketIO server with gevent...")
            self.socketio.run(
                self.app,
                host=self.host,
                port=self.port,
                debug=False,
                use_reloader=False,
            )
            
        except Exception as e:
            logger.error(f"❌ Failed to start web server: {e}")
            raise
    
    def _setup_http_routes(self):
        """Setup HTTP API routes"""
        
        @self.app.route('/health', methods=['GET'])
        def simple_health_check():
            """A simple health check endpoint for the frontend to poll."""
            return jsonify({"status": "ok"})

        @self.app.route('/api/health', methods=['GET'])
        def health_check():
            """Health check endpoint"""
            return jsonify({
                'status': 'healthy',
                'message': 'Homie Backend is running!',
                'timestamp': datetime.now().isoformat(),
                'components': list(self.components.keys()),
                'version': '2.0.0-clean'
            })
        
        @self.app.route('/api/status', methods=['GET'])
        async def get_status():
            """Get system status"""
            status = {
                'status': 'running',
                'version': '2.0.0-clean',
                'timestamp': datetime.now().isoformat(),
                'components': {}
            }
            
            # Check each component health
            for name, component in self.components.items():
                try:
                    if hasattr(component, 'health_check'):
                        health = await component.health_check()
                        status['components'][name] = health
                    else:
                        status['components'][name] = {'status': 'running'}
                except Exception as e:
                    status['components'][name] = {'status': 'error', 'error': str(e)}
            
            return jsonify(status)

        @self.app.route('/__internal__/shutdown', methods=['POST'])
        def internal_shutdown():
            """Development-only endpoint to gracefully stop the dev server."""
            try:
                # Only allow localhost
                if request.remote_addr not in ('127.0.0.1', '::1'):
                    return jsonify({'success': False, 'error': 'forbidden'}), 403

                logger.info("🛑 Internal shutdown requested")
                self._shutdown_flag = True
                
                # Try to shutdown Werkzeug server
                func = request.environ.get('werkzeug.server.shutdown')
                if func:
                    func()
                    return jsonify({'success': True, 'method': 'werkzeug'})
                else:
                    # Fallback: signal the main process to exit
                    import os, signal
                    os.kill(os.getpid(), signal.SIGTERM)
                    return jsonify({'success': True, 'method': 'sigterm'})
                    
            except Exception as e:
                return jsonify({'success': False, 'error': str(e)}), 500

        @self.app.route('/api/file-organizer/organize', methods=['POST'])
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
                app_manager = self.components.get('app_manager')
                if not app_manager:
                    return jsonify({'success': False, 'error': 'app_manager_unavailable'}), 500
                
                # For now, bypass the module system and work directly with the database
                # This is a temporary solution until we fix the async module startup
                pass

                # until the AI generator is fully re-integrated.
                from pathlib import Path
                from file_organizer.ai_content_analyzer import AIContentAnalyzer
                
                src_path = Path(source_folder).expanduser()
                dest_root = Path(destination_folder).expanduser()
                if not src_path.exists() or not src_path.is_dir():
                    return jsonify({'success': False, 'error': f'source_folder not found: {source_folder}'}), 400

                shared_services = self.components.get('shared_services')
                analyzer = AIContentAnalyzer(shared_services=shared_services)

                files = [p for p in src_path.iterdir() if p.is_file()]
                operations = []
                errors = []
                
                for f in files:
                    analysis = analyzer.analyze_file(str(f))
                    if not analysis.get('success'):
                        # Log the error but continue with other files
                        error_msg = f"Failed to analyze {f.name}: {analysis.get('error')}"
                        logger.warning(error_msg)
                        errors.append({
                            'file': str(f),
                            'error': analysis.get('error')
                        })
                        continue

                    # Use AI-generated folder suggestion directly
                    suggested_folder = analysis.get('suggested_folder', 'Other')
                    reason = analysis.get('reason', 'File categorized for organization.')

                    dest_path = dest_root / suggested_folder / f.name
                    operations.append({
                        'type': 'move',
                        'source': str(f),
                        'destination': str(dest_path),
                        'reason': reason
                    })
                
                # If ALL files failed, return error
                if not operations and errors:
                    return jsonify({
                        'success': False, 
                        'error': 'All files failed to analyze',
                        'details': errors
                    }), 503

                # Create a persistent analysis session directly in the database
                import sqlite3
                import uuid
                import json
                from datetime import datetime
                
                analysis_id = str(uuid.uuid4())
                now = datetime.now().isoformat()
                
                # Connect to the database directly
                import os
                db_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data", "modules", "homie_file_organizer.db")
                conn = sqlite3.connect(db_path)
                
                try:
                    # Insert analysis session
                    conn.execute("""
                        INSERT INTO analysis_sessions 
                        (analysis_id, user_id, source_path, destination_path, organization_style, file_count, created_at, updated_at, status, metadata)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, (analysis_id, user_id, source_folder, destination_folder, organization_style, len(files), now, now, 'active', json.dumps({})))
                    
                    # Insert operations and add operation_id to each operation
                    for i, op in enumerate(operations):
                        operation_id = f"{analysis_id}_op_{i}"
                        conn.execute("""
                            INSERT INTO analysis_operations
                            (operation_id, analysis_id, operation_type, source_path, destination_path, file_name, operation_status, metadata)
                            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                        """, (operation_id, analysis_id, op['type'], op['source'], op['destination'], 
                              Path(op['source']).name, 'pending', json.dumps({'reason': op.get('reason', '')})))
                        
                        # Add operation_id to the operation for the response
                        op['operation_id'] = operation_id
                        op['status'] = 'pending'
                    
                    conn.commit()
                    
                    # Prepare response
                    analysis = {
                        "analysis_id": analysis_id,
                        "user_id": user_id,
                        "source_path": source_folder,
                        "destination_path": destination_folder,
                        "organization_style": organization_style,
                        "file_count": len(files),
                        "created_at": now,
                        "updated_at": now,
                        "status": "active"
                    }
                    
                    response = {
                        "success": True,
                        "errors": errors if errors else None,
                        "analysis_id": analysis_id,
                        "analysis": analysis,
                        "operations": operations
                    }
                    
                finally:
                    conn.close()
                
                return jsonify(response)
                    
            except Exception as e:
                logger.error(f"/organize error: {e}", exc_info=True)
                return jsonify({'success': False, 'error': str(e)}), 500

        @self.app.route('/api/file-organizer/execute-operations', methods=['POST'])
        def fo_execute_ops():
            try:
                payload = request.get_json(force=True, silent=True) or {}
                operations = payload.get('operations', [])
                dry_run = bool(payload.get('dry_run', False))

                app_manager = self.components.get('app_manager')
                if not app_manager:
                    return jsonify({'success': False, 'error': 'app_manager_unavailable'}), 500
                
                # Use gevent's async support directly
                import gevent
                from gevent import spawn
                
                def run_async_task():
                    import asyncio
                    loop = asyncio.new_event_loop()
                    asyncio.set_event_loop(loop)
                    try:
                        loop.run_until_complete(app_manager.start_module('file_organizer'))
                        file_organizer = app_manager.get_active_module('file_organizer')
                        if not file_organizer:
                            return {'success': False, 'error': 'module_not_running'}
                        return loop.run_until_complete(file_organizer.execute_operations(operations, dry_run=dry_run))
                    finally:
                        loop.close()
                
                # Run in separate greenlet to avoid event loop conflicts
                greenlet = spawn(run_async_task)
                result = greenlet.get()
                
                if isinstance(result, dict) and not result.get('success', True):
                    return jsonify(result), 500
                    
                return jsonify(result)
                    
            except Exception as e:
                logger.error(f"/execute-operations error: {e}")
                return jsonify({'success': False, 'error': str(e)}), 500


        @self.app.route('/api/file-organizer/analyses', methods=['GET'])
        def fo_get_analyses():
            try:
                # Hardcoded user_id for now
                user_id = "dev_user"
                
                # Direct database access (bypassing module system due to async issues)
                import sqlite3
                import os
                
                db_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data", "modules", "homie_file_organizer.db")
                conn = sqlite3.connect(db_path)
                
                try:
                    # Get all analysis sessions for the user
                    cursor = conn.execute("""
                        SELECT analysis_id, user_id, source_path, destination_path, organization_style, 
                               file_count, created_at, updated_at, status, metadata
                        FROM analysis_sessions 
                        WHERE user_id = ?
                        ORDER BY created_at DESC
                    """, (user_id,))
                    
                    analyses = []
                    for row in cursor.fetchall():
                        analyses.append({
                            'analysis_id': row[0],
                            'user_id': row[1],
                            'source_path': row[2],
                            'destination_path': row[3],
                            'organization_style': row[4],
                            'file_count': row[5],
                            'created_at': row[6],
                            'updated_at': row[7],
                            'status': row[8],
                            'metadata': row[9]
                        })
                    
                    return jsonify({'success': True, 'analyses': analyses})
                    
                finally:
                    conn.close()
                    
            except Exception as e:
                logger.error(f"/analyses error: {e}", exc_info=True)
                return jsonify({'success': False, 'error': str(e)}), 500

        @self.app.route('/api/file-organizer/analyses/<analysis_id>', methods=['GET'])
        def fo_get_analysis_detail(analysis_id):
            try:
                user_id = "dev_user"
                
                # Direct database access (bypassing module system due to async issues)
                import sqlite3
                import os
                import json
                
                db_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data", "modules", "homie_file_organizer.db")
                conn = sqlite3.connect(db_path)
                
                try:
                    # Get the analysis session
                    cursor = conn.execute("""
                        SELECT analysis_id, user_id, source_path, destination_path, organization_style, 
                               file_count, created_at, updated_at, status, metadata
                        FROM analysis_sessions 
                        WHERE user_id = ? AND analysis_id = ?
                    """, (user_id, analysis_id))
                    
                    analysis_row = cursor.fetchone()
                    if not analysis_row:
                        return jsonify({'success': False, 'error': 'Analysis not found'}), 404
                    
                    analysis = {
                        'analysis_id': analysis_row[0],
                        'user_id': analysis_row[1],
                        'source_path': analysis_row[2],
                        'destination_path': analysis_row[3],
                        'organization_style': analysis_row[4],
                        'file_count': analysis_row[5],
                        'created_at': analysis_row[6],
                        'updated_at': analysis_row[7],
                        'status': analysis_row[8],
                        'metadata': analysis_row[9]
                    }
                    
                    # Get the operations for this analysis
                    cursor = conn.execute("""
                        SELECT operation_id, analysis_id, operation_type, source_path, destination_path, 
                               file_name, operation_status, applied_at, reverted_at, metadata
                        FROM analysis_operations 
                        WHERE analysis_id = ?
                        ORDER BY operation_id
                    """, (analysis_id,))
                    
                    operations = []
                    for row in cursor.fetchall():
                        op_metadata = json.loads(row[9]) if row[9] else {}
                        operations.append({
                            'operation_id': row[0],
                            'analysis_id': row[1],
                            'type': row[2],
                            'source': row[3],
                            'destination': row[4],
                            'file_name': row[5],
                            'status': row[6],
                            'applied_at': row[7],
                            'reverted_at': row[8],
                            'reason': op_metadata.get('reason', '')
                        })
                    
                    return jsonify({
                        'success': True,
                        'analysis': analysis,
                        'operations': operations
                    })
                    
                finally:
                    conn.close()
                    
            except Exception as e:
                logger.error(f"/analyses/{analysis_id} error: {e}", exc_info=True)
                return jsonify({'success': False, 'error': str(e)}), 500

        @self.app.route('/api/file-organizer/operations/<operation_id>/status', methods=['PUT'])
        def fo_update_operation_status(operation_id):
            try:
                user_id = "dev_user"
                data = request.get_json(force=True, silent=True) or {}
                status = data.get('status')
                timestamp = data.get('timestamp', datetime.now().isoformat())

                if not status:
                    return jsonify({'success': False, 'error': 'Status is required'}), 400

                # Validate status
                valid_statuses = ['pending', 'applied', 'ignored', 'reverted', 'removed']
                if status not in valid_statuses:
                    return jsonify({'success': False, 'error': f'Invalid status. Must be one of: {valid_statuses}'}), 400

                # Direct database access (bypassing module system due to async issues)
                import sqlite3
                import os
                import json
                
                db_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data", "modules", "homie_file_organizer.db")
                conn = sqlite3.connect(db_path)
                
                try:
                    # First check if the operation exists and belongs to the user
                    cursor = conn.execute("""
                        SELECT ao.operation_id, ao.analysis_id, ao.operation_type, ao.source_path, 
                               ao.destination_path, ao.file_name, ao.operation_status, ao.applied_at, 
                               ao.reverted_at, ao.metadata
                        FROM analysis_operations ao
                        JOIN analysis_sessions as_ ON ao.analysis_id = as_.analysis_id
                        WHERE ao.operation_id = ? AND as_.user_id = ?
                    """, (operation_id, user_id))
                    
                    operation_row = cursor.fetchone()
                    if not operation_row:
                        return jsonify({'success': False, 'error': 'Operation not found'}), 404
                    
                    # Update the operation status
                    update_fields = ['operation_status']
                    update_values = [status]
                    
                    # Set timestamp fields based on status
                    if status == 'applied':
                        update_fields.append('applied_at')
                        update_values.append(timestamp)
                    elif status == 'reverted':
                        update_fields.append('reverted_at')
                        update_values.append(timestamp)
                    
                    update_values.append(operation_id)
                    
                    update_query = f"UPDATE analysis_operations SET {', '.join([f'{field} = ?' for field in update_fields])} WHERE operation_id = ?"
                    conn.execute(update_query, update_values)
                    conn.commit()
                    
                    # Get the updated operation
                    cursor = conn.execute("""
                        SELECT operation_id, analysis_id, operation_type, source_path, destination_path, 
                               file_name, operation_status, applied_at, reverted_at, metadata
                        FROM analysis_operations 
                        WHERE operation_id = ?
                    """, (operation_id,))
                    
                    updated_row = cursor.fetchone()
                    op_metadata = json.loads(updated_row[9]) if updated_row[9] else {}
                    
                    updated_operation = {
                        'operation_id': updated_row[0],
                        'analysis_id': updated_row[1],
                        'type': updated_row[2],
                        'source': updated_row[3],
                        'destination': updated_row[4],
                        'file_name': updated_row[5],
                        'status': updated_row[6],
                        'applied_at': updated_row[7],
                        'reverted_at': updated_row[8],
                        'reason': op_metadata.get('reason', '')
                    }

                    return jsonify({'success': True, 'message': 'Operation status updated', 'operation': updated_operation})
                    
                finally:
                    conn.close()
                    
            except Exception as e:
                logger.error(f"/operations/{operation_id}/status error: {e}", exc_info=True)
                return jsonify({'success': False, 'error': str(e)}), 500

        @self.app.route('/api/file-organizer/operations/batch-status', methods=['PUT'])
        def fo_batch_update_operation_status():
            try:
                user_id = "dev_user"
                data = request.get_json(force=True, silent=True) or {}
                operation_ids = data.get('operation_ids', [])
                status = data.get('status')
                timestamp = data.get('timestamp', datetime.now().isoformat())

                if not status or not operation_ids:
                    return jsonify({'success': False, 'error': 'Status and operation_ids are required'}), 400

                # Validate status
                valid_statuses = ['pending', 'applied', 'ignored', 'reverted', 'removed']
                if status not in valid_statuses:
                    return jsonify({'success': False, 'error': f'Invalid status. Must be one of: {valid_statuses}'}), 400

                # Direct database access (bypassing module system due to async issues)
                import sqlite3
                import os
                import json
                
                db_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data", "modules", "homie_file_organizer.db")
                conn = sqlite3.connect(db_path)
                
                try:
                    updated_operations = []
                    
                    # Process each operation
                    for operation_id in operation_ids:
                        # First check if the operation exists and belongs to the user
                        cursor = conn.execute("""
                            SELECT ao.operation_id, ao.analysis_id, ao.operation_type, ao.source_path, 
                                   ao.destination_path, ao.file_name, ao.operation_status, ao.applied_at, 
                                   ao.reverted_at, ao.metadata
                            FROM analysis_operations ao
                            JOIN analysis_sessions as_ ON ao.analysis_id = as_.analysis_id
                            WHERE ao.operation_id = ? AND as_.user_id = ?
                        """, (operation_id, user_id))
                        
                        operation_row = cursor.fetchone()
                        if not operation_row:
                            continue  # Skip operations that don't exist or don't belong to user
                        
                        # Update the operation status
                        update_fields = ['operation_status']
                        update_values = [status]
                        
                        # Set timestamp fields based on status
                        if status == 'applied':
                            update_fields.append('applied_at')
                            update_values.append(timestamp)
                        elif status == 'reverted':
                            update_fields.append('reverted_at')
                            update_values.append(timestamp)
                        
                        update_values.append(operation_id)
                        
                        update_query = f"UPDATE analysis_operations SET {', '.join([f'{field} = ?' for field in update_fields])} WHERE operation_id = ?"
                        conn.execute(update_query, update_values)
                        
                        # Get the updated operation
                        cursor = conn.execute("""
                            SELECT operation_id, analysis_id, operation_type, source_path, destination_path, 
                                   file_name, operation_status, applied_at, reverted_at, metadata
                            FROM analysis_operations 
                            WHERE operation_id = ?
                        """, (operation_id,))
                        
                        updated_row = cursor.fetchone()
                        if updated_row:
                            op_metadata = json.loads(updated_row[9]) if updated_row[9] else {}
                            
                            updated_operations.append({
                                'operation_id': updated_row[0],
                                'analysis_id': updated_row[1],
                                'type': updated_row[2],
                                'source': updated_row[3],
                                'destination': updated_row[4],
                                'file_name': updated_row[5],
                                'status': updated_row[6],
                                'applied_at': updated_row[7],
                                'reverted_at': updated_row[8],
                                'reason': op_metadata.get('reason', '')
                            })
                    
                    conn.commit()
                    
                    return jsonify({
                        'success': True, 
                        'message': f'{len(updated_operations)} operations updated',
                        'updated_operations': updated_operations
                    })
                    
                finally:
                    conn.close()
                    
            except Exception as e:
                logger.error(f"/operations/batch-status error: {e}", exc_info=True)
                return jsonify({'success': False, 'error': str(e)}), 500


        @self.app.route('/api/test-ai', methods=['POST'])
        async def test_ai():
            """Test AI connection"""
            try:
                if 'shared_services' not in self.components:
                    return jsonify({'success': False, 'error': 'Shared services not available'}), 500
                
                shared_services = self.components['shared_services']
                result = await shared_services.test_ai_connection()
                
                return jsonify(result)
            except Exception as e:
                return jsonify({'success': False, 'error': str(e)}), 500
        
        # ==================== Phase 5: Advanced AI Features ====================
        
        @self.app.route('/api/file-organizer/analyze-content', methods=['POST'])
        def fo_analyze_content():
            """Analyze a single file and extract rich metadata"""
            try:
                from file_organizer.ai_content_analyzer import AIContentAnalyzer
                
                data = request.get_json(force=True, silent=True) or {}
                file_path = data.get('file_path')
                
                if not file_path:
                    return jsonify({'success': False, 'error': 'file_path is required'}), 400
                
                analyzer = AIContentAnalyzer()
                result = analyzer.analyze_file(file_path)
                
                return jsonify(result)
                
            except Exception as e:
                logger.error(f"/analyze-content error: {e}", exc_info=True)
                return jsonify({'success': False, 'error': str(e)}), 500
        
        @self.app.route('/api/file-organizer/analyze-content-batch', methods=['POST'])
        def fo_analyze_content_batch():
            """Analyze multiple files at once using AI when available"""
            try:
                from file_organizer.ai_content_analyzer import AIContentAnalyzer
                
                data = request.get_json(force=True, silent=True) or {}
                files = data.get('files', [])
                use_ai = data.get('use_ai', True)  # Enable AI by default
                
                if not files:
                    return jsonify({'success': False, 'error': 'files array is required'}), 400
                
                if len(files) > 50:
                    return jsonify({'success': False, 'error': 'Maximum 50 files per batch'}), 400
                
                # Initialize analyzer with shared_services for AI access
                shared_services = self.components.get('shared_services')
                analyzer = AIContentAnalyzer(shared_services=shared_services)
                results = {}
                
                for file_path in files:
                    try:
                        result = analyzer.analyze_file(file_path, use_ai=use_ai)
                        # If analysis failed, ensure content_type is set for backward compatibility
                        if not result.get('success'):
                            result['content_type'] = 'unknown'
                        results[file_path] = result
                    except Exception as e:
                        logger.warning(f"Error analyzing {file_path}: {e}")
                        results[file_path] = {
                            'success': False,
                            'error': str(e),
                            'content_type': 'unknown'
                        }
                
                return jsonify({
                    'success': True,
                    'ai_enabled': shared_services.is_ai_available() and use_ai if shared_services else False,
                    'results': results
                })
                
            except Exception as e:
                logger.error(f"/analyze-content-batch error: {e}", exc_info=True)
                return jsonify({'success': False, 'error': str(e)}), 500
        
        @self.app.route('/api/file-organizer/scan-duplicates', methods=['POST'])
        def fo_scan_duplicates():
            """Scan for duplicate files based on content hash"""
            try:
                from file_organizer.ai_content_analyzer import AIContentAnalyzer
                
                data = request.get_json(force=True, silent=True) or {}
                files = data.get('files', [])
                
                if not files:
                    return jsonify({'success': False, 'error': 'files array is required'}), 400
                
                analyzer = AIContentAnalyzer()
                result = analyzer.scan_duplicates(files)
                
                return jsonify(result)
                
            except Exception as e:
                logger.error(f"/scan-duplicates error: {e}", exc_info=True)
                return jsonify({'success': False, 'error': str(e)}), 500
        
        @self.app.route('/api/file-organizer/analyze-archive', methods=['POST'])
        def fo_analyze_archive():
            """Analyze archive contents without extracting"""
            try:
                from file_organizer.ai_content_analyzer import AIContentAnalyzer
                
                data = request.get_json(force=True, silent=True) or {}
                archive_path = data.get('archive_path')
                
                if not archive_path:
                    return jsonify({'success': False, 'error': 'archive_path is required'}), 400
                
                analyzer = AIContentAnalyzer()
                result = analyzer.analyze_archive(archive_path)
                
                return jsonify(result)
                
            except Exception as e:
                logger.error(f"/analyze-archive error: {e}", exc_info=True)
                return jsonify({'success': False, 'error': str(e)}), 500
        
        @self.app.route('/api/file-organizer/suggest-destination', methods=['POST'])
        def fo_suggest_destination():
            """Suggest destinations based on file content and user history"""
            try:
                from file_organizer.ai_content_analyzer import AIContentAnalyzer
                from pathlib import Path
                
                data = request.get_json(force=True, silent=True) or {}
                file_path = data.get('file_path')
                content_metadata = data.get('content_metadata', {})
                user_id = "dev_user"  # Hardcoded for now
                
                if not file_path:
                    return jsonify({'success': False, 'error': 'file_path is required'}), 400
                
                # If no metadata provided, analyze the file first
                if not content_metadata:
                    analyzer = AIContentAnalyzer()
                    analysis_result = analyzer.analyze_file(file_path)
                    if analysis_result.get('success'):
                        content_metadata = analysis_result
                
                # Get user history suggestions
                app_manager = self.components.get('app_manager')
                if not app_manager:
                    return jsonify({'success': False, 'error': 'app_manager_unavailable'}), 500
                
                file_organizer = app_manager.get_active_module('file_organizer')
                if not file_organizer:
                    # Start the module if not running
                    import asyncio
                    import gevent
                    def start_module():
                        loop = asyncio.new_event_loop()
                        asyncio.set_event_loop(loop)
                        try:
                            loop.run_until_complete(app_manager.start_module('file_organizer'))
                        finally:
                            loop.close()
                    gevent.spawn(start_module).get()
                    file_organizer = app_manager.get_active_module('file_organizer')
                
                if not file_organizer:
                    return jsonify({'success': False, 'error': 'File Organizer module not available'}), 500
                
                # Get suggestions from history
                content_type = content_metadata.get('content_type')
                company = content_metadata.get('company')
                file_extension = Path(file_path).suffix.lower()
                
                suggestions = file_organizer.path_memory_manager.get_destination_suggestions(
                    user_id=user_id,
                    content_type=content_type,
                    company=company,
                    file_extension=file_extension
                )
                
                # No hardcoded fallback suggestions - let the AI decide everything
                
                return jsonify({
                    'success': True,
                    'suggestions': suggestions
                })
                
            except Exception as e:
                logger.error(f"/suggest-destination error: {e}", exc_info=True)
                return jsonify({'success': False, 'error': str(e)}), 500
        
        @self.app.route('/api/file-organizer/suggest-alternatives', methods=['POST'])
        def fo_suggest_alternatives():
            """Suggest alternative destinations when a user disagrees with a suggestion."""
            try:
                data = request.get_json(force=True, silent=True) or {}
                analysis_id = data.get('analysis_id')
                rejected_operation = data.get('rejected_operation')

                if not analysis_id or not rejected_operation:
                    return jsonify({'success': False, 'error': 'analysis_id and rejected_operation are required'}), 400

                # 1. Validate analysis_id by checking if it exists in the database
                import sqlite3
                import os
                db_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data", "modules", "homie_file_organizer.db")
                conn = sqlite3.connect(db_path)
                try:
                    cursor = conn.execute("SELECT 1 FROM analysis_sessions WHERE analysis_id = ?", (analysis_id,))
                    if not cursor.fetchone():
                        return jsonify({'success': False, 'error': 'Analysis ID not found'}), 404
                finally:
                    conn.close()

                file_path = rejected_operation.get('source')
                if not file_path or not os.path.exists(file_path):
                    return jsonify({'success': False, 'error': 'File path from rejected_operation does not exist'}), 404

                # 2. Generate alternative suggestions
                from file_organizer.ai_content_analyzer import AIContentAnalyzer
                shared_services = self.components.get('shared_services')
                analyzer = AIContentAnalyzer(shared_services=shared_services)
                
                suggestions = analyzer.suggest_alternatives(rejected_operation)
                
                if not suggestions.get('success'):
                    return jsonify(suggestions), 503

                return jsonify(suggestions)

            except Exception as e:
                logger.error(f"/suggest-alternatives error: {e}", exc_info=True)
                return jsonify({'success': False, 'error': str(e)}), 500

    def _setup_websocket_handlers(self):
        """Setup WebSocket event handlers"""
        
        def run_async(coro):
            """Helper to run async functions in gevent context"""
            import asyncio
            import inspect
            
            # If it's already a coroutine, we need to run it
            if inspect.iscoroutine(coro):
                try:
                    # Try to get existing event loop
                    loop = asyncio.get_event_loop()
                    if loop.is_running():
                        # If loop is running, create a task
                        import concurrent.futures
                        import threading
                        
                        # Run in a separate thread with its own event loop
                        def run_in_thread():
                            new_loop = asyncio.new_event_loop()
                            asyncio.set_event_loop(new_loop)
                            try:
                                return new_loop.run_until_complete(coro)
                            finally:
                                new_loop.close()
                        
                        with concurrent.futures.ThreadPoolExecutor() as executor:
                            future = executor.submit(run_in_thread)
                            return future.result(timeout=30)  # 30 second timeout
                    else:
                        return loop.run_until_complete(coro)
                except RuntimeError:
                    # No event loop in current thread, create one
                    return asyncio.run(coro)
            else:
                # Not a coroutine, just return the result
                return coro
        
        # HTTP routes that use run_async (must be after run_async definition)
        @self.app.route('/api/file_organizer/drives', methods=['GET'])
        def fo_get_drives():
            try:
                app_manager = self.components.get('app_manager')
                if not app_manager:
                    return jsonify({'success': False, 'error': 'app_manager_unavailable'}), 500
                run_async(app_manager.start_module('file_organizer'))

                file_organizer = app_manager.get_active_module('file_organizer')
                if not file_organizer:
                    return jsonify({'success': False, 'error': 'module_not_running'}), 500

                result = run_async(file_organizer.get_drives())
                return jsonify({'success': True, **result})
            except Exception as e:
                logger.error(f"/drives error: {e}")
                return jsonify({'success': False, 'error': str(e)}), 500
        
        @self.app.route('/api/file-organizer/destinations', methods=['GET'])
        def fo_get_destinations():
            try:
                app_manager = self.components.get('app_manager')
                if not app_manager:
                    return jsonify({'success': False, 'error': 'app_manager_unavailable'}), 500
                
                # Ensure the module is started before trying to access it
                run_async(app_manager.start_module('file_organizer'))
                
                file_organizer_app = self.components.get('app_manager').get_active_module("file_organizer")
                if not file_organizer_app:
                    return jsonify({'success': False, 'error': 'File Organizer module not found or not running'}), 404
                destinations = file_organizer_app.get_all_destination_paths()
                return jsonify(destinations)
            except Exception as e:
                logger.error(f"Error getting destinations: {e}", exc_info=True)
                return jsonify({'success': False, 'error': 'Failed to get destinations'}), 500

        @self.app.route('/api/file-organizer/destinations', methods=['DELETE'])
        def fo_delete_destination():
            try:
                file_organizer_app = self.components.get('app_manager').get_active_module("file_organizer")
                if not file_organizer_app:
                    return jsonify({'success': False, 'error': 'File Organizer module not found or not running'}), 404

                data = request.get_json(force=True, silent=True) or {}
                path = data.get('path')

                if not path:
                    return jsonify({'success': False, 'error': 'Path is required'}), 400

                result = file_organizer_app.remove_destination_path(path)

                if result:
                    return jsonify({'success': True, 'message': 'Destination removed'}), 200
                else:
                    return jsonify({'success': False, 'error': 'Path not found'}), 404
            except Exception as e:
                logger.error(f"Error deleting destination: {e}", exc_info=True)
                return jsonify({'success': False, 'error': 'Failed to delete destination'}), 500
        
        @self.socketio.on('connect')
        def handle_connect(auth):
            """Handle WebSocket connection - delegate to client manager"""
            try:
                logger.info(f"🔌 WebSocket connection: {request.sid}")
                
                if 'client_manager' in self.components:
                    client_manager = self.components['client_manager']
                    result = run_async(client_manager.handle_connect(request.sid, auth))
                    emit('connection_response', result)
                else:
                    emit('connection_response', {
                        'success': False,
                        'error': 'Client manager not available'
                    })
                    
            except Exception as e:
                logger.error(f"❌ Connection error: {e}")
                emit('connection_response', {'success': False, 'error': str(e)})
        
        @self.socketio.on('disconnect')
        def handle_disconnect():
            """Handle WebSocket disconnection - delegate to client manager"""
            try:
                logger.info(f"🔌 WebSocket disconnect: {request.sid}")
                
                if 'client_manager' in self.components:
                    client_manager = self.components['client_manager']
                    run_async(client_manager.handle_disconnect(request.sid))
                    
            except Exception as e:
                logger.error(f"❌ Disconnect error: {e}")
        
        @self.socketio.on('authenticate')
        def handle_authenticate(credentials):
            """Handle authentication - delegate to client manager"""
            try:
                if 'client_manager' in self.components:
                    client_manager = self.components['client_manager']
                    result = run_async(client_manager.authenticate_user(request.sid, credentials))
                    emit('auth_response', result)
                else:
                    emit('auth_response', {
                        'success': False,
                        'error': 'Client manager not available'
                    })
                    
            except Exception as e:
                logger.error(f"❌ Authentication error: {e}")
                emit('auth_response', {'success': False, 'error': str(e)})
        
        @self.socketio.on('switch_module')
        def handle_module_switch(data):
            """Handle module switching - delegate to client manager"""
            try:
                if 'client_manager' in self.components:
                    client_manager = self.components['client_manager']
                    result = run_async(client_manager.switch_module(request.sid, data.get('module')))
                    emit('module_switch_response', result)
                else:
                    emit('module_switch_response', {
                        'success': False,
                        'error': 'Client manager not available'
                    })
                    
            except Exception as e:
                logger.error(f"❌ Module switch error: {e}")
                emit('module_switch_response', {'success': False, 'error': str(e)})
        
        @self.socketio.on('request_folder_history')
        def handle_request_folder_history(data):
            try:
                folder_path = (data or {}).get('folder_path')
                limit = int((data or {}).get('limit', 50))
                if not folder_path:
                    emit('folder_history_response', {'success': False, 'error': 'folder_path_required'})
                    return

                app_manager = self.components.get('app_manager')
                if not app_manager:
                    emit('folder_history_response', {'success': False, 'error': 'app_manager_unavailable'})
                    return
                run_async(app_manager.start_module('file_organizer'))

                file_organizer = app_manager.get_active_module('file_organizer')
                if not file_organizer:
                    emit('folder_history_response', {'success': False, 'error': 'module_not_running'})
                    return

                result = run_async(file_organizer.get_folder_history(folder_path, limit=limit))
                emit('folder_history_response', result)
            except Exception as e:
                logger.error(f"❌ request_folder_history error: {e}")
                emit('folder_history_response', {'success': False, 'error': str(e)})

        @self.socketio.on('request_folder_summary')
        def handle_request_folder_summary(data):
            try:
                folder_path = (data or {}).get('folder_path')
                if not folder_path:
                    emit('folder_summary_response', {'success': False, 'error': 'folder_path_required'})
                    return

                app_manager = self.components.get('app_manager')
                if not app_manager:
                    emit('folder_summary_response', {'success': False, 'error': 'app_manager_unavailable'})
                    return
                run_async(app_manager.start_module('file_organizer'))

                file_organizer = app_manager.get_active_module('file_organizer')
                if not file_organizer:
                    emit('folder_summary_response', {'success': False, 'error': 'module_not_running'})
                    return

                result = run_async(file_organizer.get_folder_summary(folder_path))
                emit('folder_summary_response', result)
            except Exception as e:
                logger.error(f"❌ request_folder_summary error: {e}")
                emit('folder_summary_response', {'success': False, 'error': str(e)})
        @self.socketio.on('test_event')
        def handle_test_event(data):
            """Handle test event"""
            try:
                logger.info(f"🧪 Test event received: {request.sid}")
                
                response_data = {
                    'received_data': data,
                    'server_timestamp': datetime.now().isoformat(),
                    'socket_id': request.sid
                }
                
                emit('test_event_response', response_data)
                
                # Broadcast to event bus
                if 'event_bus' in self.components:
                    run_async(self.components['event_bus'].emit('test_event_received', {
                        'socket_id': request.sid,
                        'data': data
                    }))
                    
            except Exception as e:
                logger.error(f"❌ Test event error: {e}")
                emit('test_event_response', {'success': False, 'error': str(e)})

        @self.socketio.on('request_drive_status')
        def handle_request_drive_status(data):
            """Return current drive snapshot to the requesting socket."""
            try:
                app_manager = self.components.get('app_manager')
                if not app_manager:
                    emit('file_organizer_drive_status', {'success': False, 'error': 'app_manager_unavailable'})
                    return
                run_async(app_manager.start_module('file_organizer'))

                file_organizer = app_manager.get_active_module('file_organizer')
                if not file_organizer:
                    emit('file_organizer_drive_status', {'success': False, 'error': 'module_not_running'})
                    return

                result = run_async(file_organizer.get_drives())
                emit('file_organizer_drive_status', {'success': True, **result})
            except Exception as e:
                logger.error(f"❌ request_drive_status error: {e}")
                emit('file_organizer_drive_status', {'success': False, 'error': str(e)})
    
    async def shutdown(self):
        """Shutdown web server"""
        logger.info("🛑 Web Server shutdown (gevent handles this automatically)")
        # With gevent, the server will stop when the process receives SIGINT/SIGTERM