#!/usr/bin/env python3
"""
Client Manager - WebSocket Connection Management
Handles frontend connections, user sessions, and module lifecycle
"""

import logging
import uuid
from datetime import datetime
from typing import Dict, Optional, Set
from dataclasses import dataclass
from enum import Enum

logger = logging.getLogger('ClientManager')


class AppModule(Enum):
    """Available application modules"""
    MAIN_MENU = "main_menu"
    FILE_ORGANIZER = "file_organizer" 
    FINANCIAL_MANAGER = "financial_manager"


@dataclass
class UserSession:
    """User session data"""
    session_id: str
    user_id: Optional[str]
    current_module: AppModule
    connected_at: datetime
    last_activity: datetime
    socket_id: str
    user_credentials: Optional[Dict] = None


class ClientManager:
    """
    Manages frontend connections and user sessions
    
    Responsibilities:
    - WebSocket connection lifecycle
    - User authentication and sessions
    - Module switching and cleanup
    - Real-time event broadcasting
    """
    
    def __init__(self, event_bus):
        self.event_bus = event_bus
        self.sessions: Dict[str, UserSession] = {}  # socket_id -> UserSession
        self.user_sessions: Dict[str, Set[str]] = {}  # user_id -> set of socket_ids
        
        logger.info("🔌 Client Manager initialized")
    
    async def handle_connect(self, socket_id: str, auth_data: Optional[Dict] = None):
        """Handle new WebSocket connection"""
        try:
            session_id = str(uuid.uuid4())
            now = datetime.now()
            
            # Create new session
            session = UserSession(
                session_id=session_id,
                user_id=None,  # Will be set after authentication
                current_module=AppModule.MAIN_MENU,
                connected_at=now,
                last_activity=now,
                socket_id=socket_id,
                user_credentials=auth_data
            )
            
            self.sessions[socket_id] = session
            
            logger.info(f"🔌 New connection: {socket_id} (session: {session_id})")
            
            # Emit connection established event
            await self.event_bus.emit('client_connected', {
                'socket_id': socket_id,
                'session_id': session_id,
                'timestamp': now.isoformat()
            })
            
            return {
                'success': True,
                'session_id': session_id,
                'available_modules': [module.value for module in AppModule]
            }
            
        except Exception as e:
            logger.error(f"❌ Error handling connection {socket_id}: {e}")
            return {'success': False, 'error': str(e)}
    
    async def handle_disconnect(self, socket_id: str):
        """Handle WebSocket disconnection"""
        try:
            if socket_id not in self.sessions:
                return
                
            session = self.sessions[socket_id]
            
            # Clean up current module for this user
            await self._cleanup_user_module(session)
            
            # Remove from user sessions tracking
            if session.user_id and session.user_id in self.user_sessions:
                self.user_sessions[session.user_id].discard(socket_id)
                if not self.user_sessions[session.user_id]:
                    del self.user_sessions[session.user_id]
            
            # Remove session
            del self.sessions[socket_id]
            
            logger.info(f"🔌 Disconnected: {socket_id} (user: {session.user_id})")
            
            # Emit disconnection event
            await self.event_bus.emit('client_disconnected', {
                'socket_id': socket_id,
                'session_id': session.session_id,
                'user_id': session.user_id,
                'module': session.current_module.value,
                'timestamp': datetime.now().isoformat()
            })
            
        except Exception as e:
            logger.error(f"❌ Error handling disconnect {socket_id}: {e}")
    
    async def authenticate_user(self, socket_id: str, credentials: Dict):
        """Authenticate user and set up session"""
        try:
            if socket_id not in self.sessions:
                return {'success': False, 'error': 'Invalid session'}
            
            session = self.sessions[socket_id]
            
            # For now, simple credential validation
            # TODO: Implement proper authentication
            user_id = credentials.get('user_id', f"user_{socket_id[:8]}")
            
            session.user_id = user_id
            session.user_credentials = credentials
            session.last_activity = datetime.now()
            
            # Track user sessions
            if user_id not in self.user_sessions:
                self.user_sessions[user_id] = set()
            self.user_sessions[user_id].add(socket_id)
            
            logger.info(f"🔐 User authenticated: {user_id} (socket: {socket_id})")
            
            # Emit authentication event
            await self.event_bus.emit('user_authenticated', {
                'user_id': user_id,
                'socket_id': socket_id,
                'session_id': session.session_id,
                'timestamp': datetime.now().isoformat()
            })
            
            return {
                'success': True,
                'user_id': user_id,
                'session_id': session.session_id
            }
            
        except Exception as e:
            logger.error(f"❌ Authentication error for {socket_id}: {e}")
            return {'success': False, 'error': str(e)}
    
    async def switch_module(self, socket_id: str, new_module: str):
        """Switch user to a different application module"""
        try:
            if socket_id not in self.sessions:
                return {'success': False, 'error': 'Invalid session'}
            
            session = self.sessions[socket_id]
            old_module = session.current_module
            
            # Validate module
            try:
                new_module_enum = AppModule(new_module)
            except ValueError:
                return {'success': False, 'error': f'Invalid module: {new_module}'}
            
            # Clean up old module
            await self._cleanup_user_module(session)
            
            # Switch to new module
            session.current_module = new_module_enum
            session.last_activity = datetime.now()
            
            # Initialize new module
            await self._initialize_user_module(session)
            
            logger.info(f"🔄 Module switch: {session.user_id} {old_module.value} → {new_module}")
            
            # Emit module switch event
            await self.event_bus.emit('module_switched', {
                'user_id': session.user_id,
                'socket_id': socket_id,
                'old_module': old_module.value,
                'new_module': new_module,
                'timestamp': datetime.now().isoformat()
            })
            
            return {
                'success': True,
                'old_module': old_module.value,
                'new_module': new_module,
                'user_id': session.user_id
            }
            
        except Exception as e:
            logger.error(f"❌ Module switch error for {socket_id}: {e}")
            return {'success': False, 'error': str(e)}
    
    async def _cleanup_user_module(self, session: UserSession):
        """Clean up resources for user's current module"""
        try:
            if session.current_module == AppModule.FILE_ORGANIZER:
                await self.event_bus.emit('file_organizer_user_leaving', {
                    'user_id': session.user_id,
                    'socket_id': session.socket_id,
                    'session_id': session.session_id
                })
            elif session.current_module == AppModule.FINANCIAL_MANAGER:
                await self.event_bus.emit('financial_manager_user_leaving', {
                    'user_id': session.user_id,
                    'socket_id': session.socket_id,
                    'session_id': session.session_id
                })
            
            logger.debug(f"🧹 Cleaned up {session.current_module.value} for user {session.user_id}")
            
        except Exception as e:
            logger.error(f"❌ Module cleanup error: {e}")
    
    async def _initialize_user_module(self, session: UserSession):
        """Initialize resources for user's new module"""
        try:
            if session.current_module == AppModule.FILE_ORGANIZER:
                await self.event_bus.emit('file_organizer_user_joining', {
                    'user_id': session.user_id,
                    'socket_id': session.socket_id,
                    'session_id': session.session_id,
                    'credentials': session.user_credentials
                })
            elif session.current_module == AppModule.FINANCIAL_MANAGER:
                await self.event_bus.emit('financial_manager_user_joining', {
                    'user_id': session.user_id,
                    'socket_id': session.socket_id,
                    'session_id': session.session_id,
                    'credentials': session.user_credentials
                })
            
            logger.debug(f"🚀 Initialized {session.current_module.value} for user {session.user_id}")
            
        except Exception as e:
            logger.error(f"❌ Module initialization error: {e}")
    
    async def broadcast_to_user(self, user_id: str, event: str, data: Dict):
        """Send event to all sessions of a specific user"""
        if user_id not in self.user_sessions:
            return False
        
        success_count = 0
        for socket_id in self.user_sessions[user_id]:
            try:
                await self.event_bus.emit_to_socket(socket_id, event, data)
                success_count += 1
            except Exception as e:
                logger.error(f"❌ Failed to send to {socket_id}: {e}")
        
        return success_count > 0
    
    async def broadcast_to_module(self, module: AppModule, event: str, data: Dict):
        """Send event to all users currently in a specific module"""
        success_count = 0
        for session in self.sessions.values():
            if session.current_module == module:
                try:
                    await self.event_bus.emit_to_socket(session.socket_id, event, data)
                    success_count += 1
                except Exception as e:
                    logger.error(f"❌ Failed to send to {session.socket_id}: {e}")
        
        return success_count
    
    def get_session(self, socket_id: str) -> Optional[UserSession]:
        """Get session by socket ID"""
        return self.sessions.get(socket_id)
    
    def get_user_sessions(self, user_id: str) -> Set[str]:
        """Get all socket IDs for a user"""
        return self.user_sessions.get(user_id, set())
    
    def get_module_users(self, module: AppModule) -> Set[str]:
        """Get all user IDs currently in a module"""
        return {
            session.user_id for session in self.sessions.values()
            if session.current_module == module and session.user_id
        }
    
    async def shutdown(self):
        """Shutdown client manager and cleanup all sessions"""
        logger.info("🛑 Shutting down Client Manager...")
        
        # Cleanup all active sessions
        for socket_id in list(self.sessions.keys()):
            await self.handle_disconnect(socket_id)
        
        logger.info("✅ Client Manager shut down")