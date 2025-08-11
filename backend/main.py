#!/usr/bin/env python3
"""
Homie Backend - Main Orchestrator
Starts and coordinates all backend components with clean modular architecture
"""

import asyncio
import logging
import signal
import sys
from pathlib import Path
from typing import Dict, Optional

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('homie_backend.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger('HomieOrchestrator')


class HomieOrchestrator:
    """
    Main orchestrator that manages all backend components
    
    Responsibilities:
    - Start/stop all services
    - Coordinate component lifecycle
    - Handle graceful shutdown
    - Monitor component health
    """
    
    def __init__(self):
        self.components: Dict[str, object] = {}
        self.running = False
        self.shutdown_event = asyncio.Event()
        
        logger.info("🏠 Homie Backend Orchestrator initialized")
    
    async def start(self):
        """Start all backend components"""
        try:
            logger.info("🚀 Starting Homie Backend...")
            
            # 1. Start core services first
            await self._start_core_services()
            
            # 2. Start application modules
            await self._register_application_modules()
            
            # 3. Start web server
            await self._start_web_server()
            
            self.running = True
            logger.info("✅ All components started successfully!")
            logger.info("🌐 Backend running at: http://localhost:8000")
            
            # Wait for shutdown signal
            await self.shutdown_event.wait()
            
        except Exception as e:
            logger.error(f"❌ Failed to start backend: {e}")
            await self.shutdown()
            raise
    
    async def _start_core_services(self):
        """Start core shared services"""
        logger.info("🔧 Starting core services...")
        
        # Import and start shared services
        from core.shared_services import SharedServices
        self.components['shared_services'] = SharedServices()
        
        # Import and start event bus
        from core.event_bus import EventBus
        self.components['event_bus'] = EventBus()
        
        # Import and start client manager
        from core.client_manager import ClientManager
        self.components['client_manager'] = ClientManager(
            event_bus=self.components['event_bus']
        )
        
        logger.info("✅ Core services started")
    
    async def _register_application_modules(self):
        """Initialize AppManager and register modules (don't start them)"""
        logger.info("📦 Initializing AppManager and registering modules...")
        
        # AppManager is the single owner of all app modules
        from core.app_manager import AppManager
        app_manager = AppManager(
            event_bus=self.components['event_bus'],
            shared_services=self.components['shared_services']
        )
        self.components['app_manager'] = app_manager
        
        # Inject AppManager into ClientManager for on-demand module start
        if 'client_manager' in self.components:
            self.components['client_manager'].set_app_manager(app_manager)
        
        # Register (construct) all enabled modules without starting
        await app_manager.register_all_modules()
        
        logger.info("✅ AppManager ready; modules registered (not started)")
    
    async def _start_web_server(self):
        """Start the web server"""
        logger.info("🌐 Starting web server...")
        
        # Import and start the web server component
        from core.web_server import WebServer
        web_server = WebServer(components=self.components)
        
        self.components['web_server'] = web_server
        await web_server.start()
    
    async def shutdown(self):
        """Gracefully shutdown all components"""
        if not self.running:
            return
            
        logger.info("🛑 Shutting down Homie Backend...")
        
        # Shutdown in reverse order
        components_to_shutdown = [
            'web_server',
            'app_manager',
            'client_manager',
            'event_bus',
            'shared_services'
        ]
        
        for component_name in components_to_shutdown:
            if component_name in self.components:
                try:
                    component = self.components[component_name]
                    # Special-case: AppManager owns module shutdown
                    if hasattr(component, 'shutdown_all_modules'):
                        await component.shutdown_all_modules()
                        logger.info("✅ All app modules shut down")
                    elif hasattr(component, 'shutdown'):
                        await component.shutdown()
                    elif hasattr(component, 'stop'):
                        await component.stop()
                    logger.info(f"✅ {component_name} shut down")
                except Exception as e:
                    logger.error(f"❌ Error shutting down {component_name}: {e}")
        
        self.running = False
        self.shutdown_event.set()
        logger.info("✅ Shutdown complete")
    
    def handle_signal(self, signum, frame):
        """Handle shutdown signals"""
        logger.info(f"📡 Received signal {signum}, initiating shutdown...")
        self.running = False
        # Signal gevent to exit gracefully
        import sys
        sys.exit(0)


async def main():
    """Main entry point"""
    orchestrator = HomieOrchestrator()
    
    # Setup signal handlers for graceful shutdown
    signal.signal(signal.SIGINT, orchestrator.handle_signal)
    signal.signal(signal.SIGTERM, orchestrator.handle_signal)
    
    try:
        await orchestrator.start()
    except KeyboardInterrupt:
        logger.info("📡 Keyboard interrupt received")
        await orchestrator.shutdown()
    except Exception as e:
        logger.error(f"💥 Fatal error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    # Print startup banner
    print("🏠" + "="*50)
    print("🏠 HOMIE BACKEND - New Clean Architecture")
    print("🏠" + "="*50)
    print("🏠 Starting orchestrator...")
    
    # Run the async main function
    asyncio.run(main())