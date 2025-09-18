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
                source_folder = data.get('source_folder')
                destination_folder = data.get('destination_folder')
                organization_style = data.get('organization_style', 'by_type')

                if not source_folder:
                    return jsonify({'success': False, 'error': 'source_folder required'}), 400
                if not destination_folder:
                    return jsonify({'success': False, 'error': 'destination_folder required'}), 400

                # Scan source folder and build real operations
                from pathlib import Path

                src_path = Path(source_folder).expanduser()
                dest_root = Path(destination_folder).expanduser()
                if not src_path.exists() or not src_path.is_dir():
                    return jsonify({'success': False, 'error': f'source_folder not found or not a directory: {source_folder}'}), 400

                # Extension → category folder mapping
                ext_map = {
                    # Documents
                    '.pdf': 'Documents', '.doc': 'Documents', '.docx': 'Documents', '.txt': 'Documents', '.rtf': 'Documents',
                    # Images
                    '.png': 'Pictures', '.jpg': 'Pictures', '.jpeg': 'Pictures', '.gif': 'Pictures', '.webp': 'Pictures',
                    # Videos
                    '.mkv': 'Videos', '.mp4': 'Videos', '.avi': 'Videos', '.mov': 'Videos', '.wmv': 'Videos',
                    # Archives
                    '.rar': 'Archives', '.zip': 'Archives', '.7z': 'Archives', '.tar': 'Archives', '.gz': 'Archives', '.bz2': 'Archives',
                    # Disk images
                    '.iso': 'Software', '.dmg': 'Software', '.img': 'Software',
                }

                files = [p for p in src_path.iterdir() if p.is_file()]

                operations = []
                stats_counts = {}
                warnings = []

                for f in files:
                    ext = f.suffix.lower()
                    category = ext_map.get(ext, 'Other')
                    stats_counts[category] = stats_counts.get(category, 0) + 1

                    dest_dir = dest_root / category
                    dest_path = dest_dir / f.name

                    operations.append({
                        'type': 'move',
                        'source': str(f),
                        'destination': str(dest_path),
                        'reason': f'Move {f.name} to {category}/'
                    })

                response = {
                    'success': True,
                    'operations': operations,
                    'total_files': len(files),
                    'organization_style': organization_style,
                    'stats': {
                        'by_category': stats_counts,
                    },
                    'warnings': warnings,
                }

                return jsonify(response)
                    
            except Exception as e:
                logger.error(f"/organize error: {e}")
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
                file_organizer_app = self.components.get('app_manager').get_app_instance("file_organizer")
                if not file_organizer_app:
                    return jsonify({'success': False, 'error': 'File Organizer module not found or not running'}), 404
                destinations = file_organizer_app.get_all_destination_paths()
                return jsonify({'success': True, 'destinations': destinations})
            except Exception as e:
                logger.error(f"Error getting destinations: {e}", exc_info=True)
                return jsonify({'success': False, 'error': 'Failed to get destinations'}), 500

        @self.app.route('/api/file-organizer/destinations', methods=['DELETE'])
        def fo_delete_destination():
            try:
                file_organizer_app = self.components.get('app_manager').get_app_instance("file_organizer")
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