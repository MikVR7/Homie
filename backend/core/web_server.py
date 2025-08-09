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
        
        logger.info(f"🌐 Web Server initialized for {self.host}:{self.port}")
    
    async def start(self):
        """Start the Flask + SocketIO server"""
        try:
            # Create Flask app
            self.app = Flask(__name__)
            self.app.config['SECRET_KEY'] = 'homie-dev-secret-key'
            CORS(self.app)
            
            # Initialize SocketIO
            self.socketio = SocketIO(self.app, cors_allowed_origins="*", async_mode='eventlet')
            
            # Connect SocketIO to event bus
            if 'event_bus' in self.components:
                self.components['event_bus'].set_socketio(self.socketio)
            
            # Setup routes and handlers
            self._setup_http_routes()
            self._setup_websocket_handlers()
            
            logger.info(f"🚀 Web Server starting on {self.host}:{self.port}")
            
            # Start SocketIO server
            await self.socketio.run(
                self.app,
                host=self.host,
                port=self.port,
                debug=False,
                use_reloader=False
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
        
        @self.socketio.on('connect')
        async def handle_connect(auth):
            """Handle WebSocket connection - delegate to client manager"""
            try:
                logger.info(f"🔌 WebSocket connection: {request.sid}")
                
                if 'client_manager' in self.components:
                    client_manager = self.components['client_manager']
                    result = await client_manager.handle_connect(request.sid, auth)
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
        async def handle_disconnect():
            """Handle WebSocket disconnection - delegate to client manager"""
            try:
                logger.info(f"🔌 WebSocket disconnect: {request.sid}")
                
                if 'client_manager' in self.components:
                    client_manager = self.components['client_manager']
                    await client_manager.handle_disconnect(request.sid)
                    
            except Exception as e:
                logger.error(f"❌ Disconnect error: {e}")
        
        @self.socketio.on('authenticate')
        async def handle_authenticate(credentials):
            """Handle authentication - delegate to client manager"""
            try:
                if 'client_manager' in self.components:
                    client_manager = self.components['client_manager']
                    result = await client_manager.authenticate_user(request.sid, credentials)
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
        async def handle_module_switch(data):
            """Handle module switching - delegate to client manager"""
            try:
                if 'client_manager' in self.components:
                    client_manager = self.components['client_manager']
                    result = await client_manager.switch_module(request.sid, data.get('module'))
                    emit('module_switch_response', result)
                else:
                    emit('module_switch_response', {
                        'success': False,
                        'error': 'Client manager not available'
                    })
                    
            except Exception as e:
                logger.error(f"❌ Module switch error: {e}")
                emit('module_switch_response', {'success': False, 'error': str(e)})
        
        @self.socketio.on('test_event')
        async def handle_test_event(data):
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
                    await self.components['event_bus'].emit('test_event_received', {
                        'socket_id': request.sid,
                        'data': data
                    })
                    
            except Exception as e:
                logger.error(f"❌ Test event error: {e}")
                emit('test_event_response', {'success': False, 'error': str(e)})
    
    async def shutdown(self):
        """Shutdown web server"""
        logger.info("🛑 Shutting down Web Server...")
        
        if self.socketio:
            # Disconnect all clients
            await self.socketio.stop()
        
        logger.info("✅ Web Server shut down")