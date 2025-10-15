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
    
    def _get_file_organizer_db_connection(self):
        """
        SINGLE SOURCE OF TRUTH for file organizer database connection.
        Returns: sqlite3.Connection object
        """
        import sqlite3
        import os
        db_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data", "modules", "homie_file_organizer.db")
        return sqlite3.connect(db_path)
    
    def _call_ai_with_recovery(self, prompt):
        """
        SINGLE SOURCE OF TRUTH for AI calls with automatic model recovery.
        Handles deprecated/failed models by discovering and retrying with a working model.
        
        Args:
            prompt: The prompt string to send to the AI
            
        Returns:
            dict with 'success', 'data', 'error' fields
        """
        import json
        
        shared_services = self.components.get('shared_services')
        
        if not shared_services or not shared_services.is_ai_available():
            return {
                'success': False,
                'error': 'AI service not available'
            }
        
        try:
            response = shared_services.ai_model.generate_content(prompt)
            response_text = response.text.strip()
            
            # Parse JSON response
            if response_text.startswith('```json'):
                response_text = response_text[7:]
            if response_text.endswith('```'):
                response_text = response_text[:-3]
            response_text = response_text.strip()
            
            data = json.loads(response_text)
            return {
                'success': True,
                'data': data
            }
            
        except Exception as first_error:
            # If model fails (e.g., deprecated), try discovery and retry once
            logger.warning(f"AI model failed, attempting recovery: {str(first_error)[:100]}")
            shared_services._model_discovery_attempted = False  # Reset flag to allow retry
            shared_services._discover_and_select_model()
            
            # Retry with recovered model
            recovered_model = shared_services.ai_model
            if not recovered_model:
                return {
                    'success': False,
                    'error': 'AI service unavailable after recovery attempt'
                }
            
            try:
                logger.info("🔄 Retrying with recovered model...")
                response = recovered_model.generate_content(prompt)
                response_text = response.text.strip()
                
                # Parse JSON response
                if response_text.startswith('```json'):
                    response_text = response_text[7:]
                if response_text.endswith('```'):
                    response_text = response_text[:-3]
                response_text = response_text.strip()
                
                data = json.loads(response_text)
                return {
                    'success': True,
                    'data': data
                }
            except Exception as retry_error:
                return {
                    'success': False,
                    'error': f'AI call failed after recovery: {str(retry_error)}'
                }
    
    def _batch_analyze_files(self, file_paths, use_ai=True):
        """
        SINGLE SOURCE OF TRUTH for batch file analysis.
        Both /organize and /analyze-content-batch call this method.
        
        Returns: dict with 'success', 'results', 'ai_enabled', 'error' (if failed)
        """
        from file_organizer.ai_content_analyzer import AIContentAnalyzer
        
        shared_services = self.components.get('shared_services')
        analyzer = AIContentAnalyzer(shared_services=shared_services)
        
        if use_ai:
            # Use batch analysis for AI (ONE call for all files!)
            batch_result = analyzer.analyze_files_batch(file_paths)
            
            if not batch_result.get('success'):
                logger.warning(f"Batch AI analysis failed: {batch_result.get('error')}")
                return {
                    'success': False,
                    'error': batch_result.get('error'),
                    'ai_enabled': False
                }
            
            results = batch_result.get('results', {})
            # Ensure all results have success flag
            for file_path in file_paths:
                if file_path in results:
                    results[file_path]['success'] = True
                else:
                    results[file_path] = {
                        'success': False,
                        'error': 'No result from batch analysis',
                        'content_type': 'unknown'
                    }
            
            return {
                'success': True,
                'ai_enabled': True,
                'results': results
            }
        
        # Non-AI path: analyze files individually
        results = {}
        for file_path in file_paths:
            try:
                result = analyzer.analyze_file(file_path, use_ai=False)
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
        
        return {
            'success': True,
            'ai_enabled': False,
            'results': results
        }
    
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

        # ===== FILE ORGANIZER ROUTES (MODULAR) =====
        # Import and register all file organizer routes from separate modules
        from core.routes.destination_routes import register_destination_routes
        from core.routes.file_organizer_routes import register_file_organizer_routes
        from core.routes.analysis_routes import register_analysis_routes
        from core.routes.operation_routes import register_operation_routes
        from core.routes.ai_routes import register_ai_routes
        
        # Register all route modules
        register_destination_routes(self.app, self)
        register_file_organizer_routes(self.app, self)
        register_analysis_routes(self.app, self)
        register_operation_routes(self.app, self)
        register_ai_routes(self.app, self)

        @self.app.route('/api/file-organizer/destinations', methods=['GET'])
        def fo_get_destinations():
            """Get saved destination folders for the user"""
            try:
                user_id = request.args.get('user_id', 'dev_user')
                conn = self._get_file_organizer_db_connection()
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
