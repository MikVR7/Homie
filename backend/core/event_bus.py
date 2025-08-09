#!/usr/bin/env python3
"""
Event Bus - Component Communication System
Handles events between components and WebSocket communication
"""

import asyncio
import logging
from typing import Dict, List, Callable, Any, Optional
from dataclasses import dataclass
from datetime import datetime
import json

logger = logging.getLogger('EventBus')


@dataclass
class EventSubscription:
    """Event subscription data"""
    event_type: str
    callback: Callable
    component_name: str
    subscription_id: str


class EventBus:
    """
    Event bus for component communication and WebSocket events
    
    Responsibilities:
    - Internal component event handling
    - WebSocket event broadcasting
    - Event subscription management
    - Event history and debugging
    """
    
    def __init__(self):
        self.subscriptions: Dict[str, List[EventSubscription]] = {}
        self.socketio_instance = None
        self.event_history: List[Dict] = []
        self.max_history = 1000
        
        logger.info("🎯 Event Bus initialized")
    
    def set_socketio(self, socketio):
        """Set SocketIO instance for WebSocket communication"""
        self.socketio_instance = socketio
        logger.info("🔌 SocketIO instance connected to Event Bus")
    
    def subscribe(self, event_type: str, callback: Callable, component_name: str = "unknown") -> str:
        """Subscribe to an event type"""
        import uuid
        subscription_id = str(uuid.uuid4())
        
        subscription = EventSubscription(
            event_type=event_type,
            callback=callback,
            component_name=component_name,
            subscription_id=subscription_id
        )
        
        if event_type not in self.subscriptions:
            self.subscriptions[event_type] = []
        
        self.subscriptions[event_type].append(subscription)
        
        logger.debug(f"📝 {component_name} subscribed to '{event_type}' (ID: {subscription_id[:8]})")
        return subscription_id
    
    def unsubscribe(self, subscription_id: str):
        """Unsubscribe from an event"""
        for event_type, subs in self.subscriptions.items():
            self.subscriptions[event_type] = [
                sub for sub in subs if sub.subscription_id != subscription_id
            ]
        
        logger.debug(f"🗑️ Unsubscribed: {subscription_id[:8]}")
    
    def unsubscribe_component(self, component_name: str):
        """Unsubscribe all events for a component"""
        removed_count = 0
        for event_type, subs in self.subscriptions.items():
            original_count = len(subs)
            self.subscriptions[event_type] = [
                sub for sub in subs if sub.component_name != component_name
            ]
            removed_count += original_count - len(self.subscriptions[event_type])
        
        logger.info(f"🗑️ Unsubscribed {removed_count} events for component: {component_name}")
    
    async def emit(self, event_type: str, data: Dict[str, Any]):
        """Emit event to internal subscribers and WebSocket clients"""
        try:
            # Add timestamp and event metadata
            enriched_data = {
                **data,
                'event_type': event_type,
                'timestamp': datetime.now().isoformat(),
                'source': 'backend'
            }
            
            # Store in history
            self._add_to_history(event_type, enriched_data)
            
            # Emit to internal subscribers
            await self._emit_internal(event_type, enriched_data)
            
            # Emit to WebSocket clients
            await self._emit_websocket(event_type, enriched_data)
            
        except Exception as e:
            logger.error(f"❌ Error emitting event '{event_type}': {e}")
    
    async def _emit_internal(self, event_type: str, data: Dict[str, Any]):
        """Emit to internal component subscribers"""
        if event_type not in self.subscriptions:
            return
        
        subscribers = self.subscriptions[event_type]
        if not subscribers:
            return
        
        logger.debug(f"📡 Emitting '{event_type}' to {len(subscribers)} internal subscribers")
        
        # Call all subscribers
        for subscription in subscribers:
            try:
                if asyncio.iscoroutinefunction(subscription.callback):
                    await subscription.callback(data)
                else:
                    subscription.callback(data)
            except Exception as e:
                logger.error(f"❌ Error in subscriber {subscription.component_name}: {e}")
    
    async def _emit_websocket(self, event_type: str, data: Dict[str, Any]):
        """Emit to WebSocket clients"""
        if not self.socketio_instance:
            return
        
        try:
            # Emit to all connected clients
            await self.socketio_instance.emit(event_type, data)
            logger.debug(f"🔌 Emitted '{event_type}' to WebSocket clients")
        except Exception as e:
            logger.error(f"❌ Error emitting to WebSocket: {e}")
    
    async def emit_to_socket(self, socket_id: str, event_type: str, data: Dict[str, Any]):
        """Emit event to specific WebSocket client"""
        if not self.socketio_instance:
            return
        
        try:
            enriched_data = {
                **data,
                'event_type': event_type,
                'timestamp': datetime.now().isoformat(),
                'source': 'backend'
            }
            
            await self.socketio_instance.emit(event_type, enriched_data, room=socket_id)
            logger.debug(f"🎯 Emitted '{event_type}' to socket {socket_id[:8]}")
        except Exception as e:
            logger.error(f"❌ Error emitting to socket {socket_id}: {e}")
    
    async def emit_to_room(self, room: str, event_type: str, data: Dict[str, Any]):
        """Emit event to WebSocket room"""
        if not self.socketio_instance:
            return
        
        try:
            enriched_data = {
                **data,
                'event_type': event_type,
                'timestamp': datetime.now().isoformat(),
                'source': 'backend'
            }
            
            await self.socketio_instance.emit(event_type, enriched_data, room=room)
            logger.debug(f"🏠 Emitted '{event_type}' to room '{room}'")
        except Exception as e:
            logger.error(f"❌ Error emitting to room {room}: {e}")
    
    def _add_to_history(self, event_type: str, data: Dict[str, Any]):
        """Add event to history for debugging"""
        event_record = {
            'event_type': event_type,
            'timestamp': datetime.now().isoformat(),
            'data_keys': list(data.keys()),
            'subscriber_count': len(self.subscriptions.get(event_type, []))
        }
        
        self.event_history.append(event_record)
        
        # Keep history within limits
        if len(self.event_history) > self.max_history:
            self.event_history = self.event_history[-self.max_history:]
    
    def get_event_history(self, limit: int = 50) -> List[Dict]:
        """Get recent event history for debugging"""
        return self.event_history[-limit:]
    
    def get_subscription_stats(self) -> Dict[str, Any]:
        """Get subscription statistics"""
        stats = {
            'total_event_types': len(self.subscriptions),
            'total_subscriptions': sum(len(subs) for subs in self.subscriptions.values()),
            'events_by_type': {},
            'components': set()
        }
        
        for event_type, subs in self.subscriptions.items():
            stats['events_by_type'][event_type] = {
                'subscriber_count': len(subs),
                'components': [sub.component_name for sub in subs]
            }
            stats['components'].update(sub.component_name for sub in subs)
        
        stats['components'] = list(stats['components'])
        return stats
    
    async def health_check(self) -> Dict[str, Any]:
        """Health check for event bus"""
        stats = self.get_subscription_stats()
        
        return {
            'status': 'healthy',
            'socketio_connected': self.socketio_instance is not None,
            'subscription_stats': stats,
            'recent_events': len(self.event_history),
            'max_history': self.max_history
        }
    
    async def shutdown(self):
        """Shutdown event bus"""
        logger.info("🛑 Shutting down Event Bus...")
        
        # Clear all subscriptions
        self.subscriptions.clear()
        
        # Clear history
        self.event_history.clear()
        
        # Disconnect SocketIO
        self.socketio_instance = None
        
        logger.info("✅ Event Bus shut down")