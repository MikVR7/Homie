#!/usr/bin/env python3
"""
App Manager - Module Registration and Lifecycle Management
Handles all application modules like FileOrganizer, FinancialManager, etc.
"""

import logging
from typing import Dict, Optional, Any, List
from datetime import datetime

logger = logging.getLogger('AppManager')


class AppManager:
    """
    Centralized application module manager
    
    Responsibilities:
    - Register all application modules (FileOrganizer, FinancialManager, etc.)
    - Handle module lifecycle (start/stop on demand)
    - Manage module dependencies
    - Provide clean interface for module access
    - Module health monitoring
    
    Like C# IServiceCollection + IServiceProvider pattern
    """
    
    def __init__(self, event_bus, shared_services):
        self.event_bus = event_bus
        self.shared_services = shared_services
        
        # Registry of available modules
        self.registered_modules: Dict[str, Dict[str, Any]] = {}
        
        # Active (started) module instances
        self.active_modules: Dict[str, object] = {}
        
        # Module startup order and dependencies
        self.module_registry = {
            'file_organizer': {
                'class_path': 'file_organizer.file_organizer_app.FileOrganizerApp',
                'dependencies': ['event_bus', 'shared_services'],
                'description': 'Smart file organization with AI assistance',
                'version': '2.0.0'
            },
            'financial_manager': {
                'class_path': 'financial_manager.financial_manager_app.FinancialManagerApp',
                'dependencies': ['event_bus', 'shared_services'],
                'description': 'Personal finance management and tracking',
                'version': '2.0.0',
                'enabled': False  # Not implemented yet
            },
            'media_manager': {
                'class_path': 'media_manager.media_manager_app.MediaManagerApp',
                'dependencies': ['event_bus', 'shared_services'],
                'description': 'Media library organization and streaming',
                'version': '2.0.0',
                'enabled': False  # Future module
            },
            'document_manager': {
                'class_path': 'document_manager.document_manager_app.DocumentManagerApp',
                'dependencies': ['event_bus', 'shared_services'],
                'description': 'Document scanning, OCR, and management',
                'version': '2.0.0',
                'enabled': False  # Future module
            }
        }
        
        logger.info("📦 AppManager initialized - Module registry loaded")
        self._log_available_modules()
        self._subscriptions = []
        self._subscribe_to_events()

    def _subscribe_to_events(self):
        """Listen for module lifecycle requests via EventBus."""
        try:
            self._subscriptions.append(
                self.event_bus.subscribe(
                    "module_start_requested", self._on_module_start_requested, "AppManager"
                )
            )
            self._subscriptions.append(
                self.event_bus.subscribe(
                    "module_stop_requested", self._on_module_stop_requested, "AppManager"
                )
            )
        except Exception as e:
            logger.warning(f"AppManager event subscription warning: {e}")

    async def _on_module_start_requested(self, data: Dict[str, Any]):
        module = data.get("module")
        if not module:
            return
        await self.start_module(module)

    async def _on_module_stop_requested(self, data: Dict[str, Any]):
        module = data.get("module")
        if not module:
            return
        await self.stop_module(module)
    
    def _log_available_modules(self):
        """Log available modules for debugging"""
        enabled_modules = [name for name, config in self.module_registry.items() 
                          if config.get('enabled', True)]
        disabled_modules = [name for name, config in self.module_registry.items() 
                           if not config.get('enabled', True)]
        
        logger.info(f"📋 Available modules: {enabled_modules}")
        if disabled_modules:
            logger.info(f"🚫 Disabled modules: {disabled_modules}")
    
    async def register_all_modules(self):
        """Register all enabled modules (create instances, don't start)"""
        logger.info("📦 Registering application modules...")
        
        for module_name, config in self.module_registry.items():
            if not config.get('enabled', True):
                logger.info(f"⏭️  Skipping disabled module: {module_name}")
                continue
                
            try:
                await self._register_module(module_name, config)
                logger.info(f"✅ Registered: {module_name}")
            except Exception as e:
                logger.error(f"❌ Failed to register {module_name}: {e}")
                # Continue with other modules
        
        logger.info(f"📦 Module registration complete - {len(self.registered_modules)} modules ready")
    
    async def _register_module(self, module_name: str, config: Dict[str, Any]):
        """Register a single module"""
        try:
            # Import the module class dynamically
            module_path, class_name = config['class_path'].rsplit('.', 1)
            module = __import__(module_path, fromlist=[class_name])
            module_class = getattr(module, class_name)
            
            # Prepare dependencies
            dependencies = self._prepare_dependencies(config.get('dependencies', []))
            
            # Create instance (constructor only - don't start)
            instance = module_class(**dependencies)
            
            # Store in registry
            self.registered_modules[module_name] = {
                'instance': instance,
                'config': config,
                'registered_at': datetime.now(),
                'started': False,
                'start_count': 0
            }
            
        except ImportError as e:
            logger.warning(f"⚠️  Module {module_name} not available (not implemented yet): {e}")
            # This is expected for future modules
        except Exception as e:
            logger.error(f"❌ Failed to register {module_name}: {e}")
            raise
    
    def _prepare_dependencies(self, dependency_names: List[str]) -> Dict[str, Any]:
        """Prepare dependency injection for module constructor"""
        dependencies = {}
        
        for dep_name in dependency_names:
            if dep_name == 'event_bus':
                dependencies['event_bus'] = self.event_bus
            elif dep_name == 'shared_services':
                dependencies['shared_services'] = self.shared_services
            else:
                logger.warning(f"⚠️  Unknown dependency: {dep_name}")
        
        return dependencies
    
    async def start_module(self, module_name: str) -> Dict[str, Any]:
        """Start a specific module on demand"""
        if module_name not in self.registered_modules:
            return {
                'success': False,
                'error': f'Module {module_name} not registered',
                'available_modules': list(self.registered_modules.keys())
            }
        
        module_info = self.registered_modules[module_name]
        
        # Check if already started
        if module_info['started']:
            logger.info(f"📱 Module {module_name} already running")
            return {
                'success': True,
                'message': f'Module {module_name} already running',
                'start_count': module_info['start_count']
            }
        
        try:
            logger.info(f"🚀 Starting module: {module_name}")
            
            instance = module_info['instance']
            
            # Call start() method if available
            if hasattr(instance, 'start'):
                await instance.start()
            
            # Update tracking
            module_info['started'] = True
            module_info['start_count'] += 1
            module_info['last_started'] = datetime.now()
            
            # Add to active modules
            self.active_modules[module_name] = instance
            
            # Emit event
            await self.event_bus.emit('module_started', {
                'module': module_name,
                'timestamp': datetime.now().isoformat()
            })
            
            logger.info(f"✅ Module {module_name} started successfully")
            
            return {
                'success': True,
                'message': f'Module {module_name} started',
                'start_count': module_info['start_count']
            }
            
        except Exception as e:
            logger.error(f"❌ Failed to start {module_name}: {e}")
            return {
                'success': False,
                'error': str(e)
            }
    
    async def stop_module(self, module_name: str) -> Dict[str, Any]:
        """Stop a specific module"""
        if module_name not in self.registered_modules:
            return {'success': False, 'error': f'Module {module_name} not registered'}
        
        module_info = self.registered_modules[module_name]
        
        if not module_info['started']:
            return {'success': True, 'message': f'Module {module_name} already stopped'}
        
        try:
            logger.info(f"🛑 Stopping module: {module_name}")
            
            instance = module_info['instance']
            
            # Call shutdown/stop method if available
            if hasattr(instance, 'shutdown'):
                await instance.shutdown()
            elif hasattr(instance, 'stop'):
                await instance.stop()
            
            # Update tracking
            module_info['started'] = False
            module_info['last_stopped'] = datetime.now()
            
            # Remove from active modules
            if module_name in self.active_modules:
                del self.active_modules[module_name]
            
            # Emit event
            await self.event_bus.emit('module_stopped', {
                'module': module_name,
                'timestamp': datetime.now().isoformat()
            })
            
            logger.info(f"✅ Module {module_name} stopped")
            
            return {'success': True, 'message': f'Module {module_name} stopped'}
            
        except Exception as e:
            logger.error(f"❌ Failed to stop {module_name}: {e}")
            return {'success': False, 'error': str(e)}
    
    def get_module(self, module_name: str) -> Optional[object]:
        """Get a module instance (whether started or not)"""
        if module_name in self.registered_modules:
            return self.registered_modules[module_name]['instance']
        return None
    
    def get_active_module(self, module_name: str) -> Optional[object]:
        """Get an active (started) module instance"""
        return self.active_modules.get(module_name)
    
    def list_modules(self) -> Dict[str, Any]:
        """List all modules with their status"""
        modules = {}
        
        for module_name, info in self.registered_modules.items():
            modules[module_name] = {
                'description': info['config'].get('description', ''),
                'version': info['config'].get('version', '1.0.0'),
                'started': info['started'],
                'start_count': info['start_count'],
                'registered_at': info['registered_at'].isoformat(),
                'dependencies': info['config'].get('dependencies', [])
            }
            
            if info['started']:
                modules[module_name]['last_started'] = info.get('last_started', '').isoformat() if info.get('last_started') else ''
        
        return {
            'total_modules': len(self.registered_modules),
            'active_modules': len(self.active_modules),
            'modules': modules
        }
    
    async def shutdown_all_modules(self):
        """Shutdown all active modules"""
        logger.info("🛑 Shutting down all active modules...")
        
        # Stop modules in reverse order (just in case of dependencies)
        active_module_names = list(self.active_modules.keys())
        active_module_names.reverse()
        
        for module_name in active_module_names:
            try:
                await self.stop_module(module_name)
            except Exception as e:
                logger.error(f"❌ Error stopping {module_name}: {e}")
        
        logger.info("✅ All modules shut down")
    
    async def health_check(self) -> Dict[str, Any]:
        """Health check for app manager and modules"""
        health = {
            'status': 'healthy',
            'registered_modules': len(self.registered_modules),
            'active_modules': len(self.active_modules),
            'modules': {}
        }
        
        # Check each registered module
        for module_name, info in self.registered_modules.items():
            module_health = {
                'registered': True,
                'started': info['started']
            }
            
            # Check module health if it has a health_check method
            if info['started']:
                instance = info['instance']
                if hasattr(instance, 'health_check'):
                    try:
                        module_health.update(await instance.health_check())
                    except Exception as e:
                        module_health['health_check_error'] = str(e)
                        health['status'] = 'degraded'
            
            health['modules'][module_name] = module_health
        
        return health