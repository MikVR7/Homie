#!/usr/bin/env python3
"""
Real-Time Drive Monitor Service
Monitors file system for USB drive connections/disconnections without app restart
"""

import os
import time
import threading
import platform
import subprocess
from typing import Dict, List, Callable, Optional
from datetime import datetime
import logging
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

class DriveMonitor:
    """
    Real-time USB drive monitoring service
    Detects drive connections/disconnections and notifies callbacks
    """
    
    def __init__(self, smart_organizer, callback: Optional[Callable] = None):
        """
        Initialize drive monitor
        
        Args:
            smart_organizer: SmartOrganizer instance for drive operations
            callback: Function to call when drive status changes
        """
        self.smart_organizer = smart_organizer
        self.callback = callback
        self.is_monitoring = False
        self.observer = None
        self.system = platform.system()
        self.known_drives = {}
        self.monitoring_thread = None
        
        # Setup logging
        self.logger = logging.getLogger(__name__)
        
    def start_monitoring(self):
        """Start real-time drive monitoring"""
        if self.is_monitoring:
            return
            
        self.is_monitoring = True
        self.logger.info("Starting real-time drive monitoring...")
        
        # Initial drive scan
        self._scan_current_drives()
        
        # Start appropriate monitoring for the OS
        if self.system == "Linux":
            self._start_linux_monitoring()
        elif self.system == "Windows":
            self._start_windows_monitoring()
        elif self.system == "Darwin":  # macOS
            self._start_macos_monitoring()
            
        self.logger.info(f"Drive monitoring started for {self.system}")
    
    def stop_monitoring(self):
        """Stop drive monitoring"""
        self.is_monitoring = False
        
        if self.observer:
            self.observer.stop()
            self.observer.join()
            
        if self.monitoring_thread:
            self.monitoring_thread.join()
            
        self.logger.info("Drive monitoring stopped")
    
    def _scan_current_drives(self):
        """Scan for currently connected drives"""
        try:
            current_drives = self.smart_organizer.discover_available_drives()
            
            # Update known drives list
            for drive_type, drives in current_drives.items():
                for drive in drives:
                    drive_key = drive.get('path', '')
                    if drive_key:
                        self.known_drives[drive_key] = {
                            'type': drive_type,
                            'info': drive,
                            'connected': True,
                            'last_seen': datetime.now().isoformat()
                        }
                        
        except Exception as e:
            self.logger.error(f"Error scanning current drives: {e}")
    
    def _start_linux_monitoring(self):
        """Start Linux-specific drive monitoring"""
        # Monitor /media and /mnt for mount/unmount events
        mount_paths = ['/media', '/mnt', '/run/media']
        
        class LinuxDriveHandler(FileSystemEventHandler):
            def __init__(self, monitor):
                self.monitor = monitor
                
            def on_created(self, event):
                if event.is_directory:
                    self.monitor._handle_drive_event('connected', event.src_path)
                    
            def on_deleted(self, event):
                if event.is_directory:
                    self.monitor._handle_drive_event('disconnected', event.src_path)
        
        self.observer = Observer()
        handler = LinuxDriveHandler(self)
        
        for path in mount_paths:
            if os.path.exists(path):
                self.observer.schedule(handler, path, recursive=True)
                
        self.observer.start()
        
        # Also start periodic polling for more reliable detection
        self._start_polling_thread()
    
    def _start_windows_monitoring(self):
        """Start Windows-specific drive monitoring"""
        # Windows uses WMI for drive monitoring
        self._start_polling_thread(interval=2.0)  # More frequent polling on Windows
    
    def _start_macos_monitoring(self):
        """Start macOS-specific drive monitoring"""
        # Monitor /Volumes for mount/unmount events
        class MacOSDriveHandler(FileSystemEventHandler):
            def __init__(self, monitor):
                self.monitor = monitor
                
            def on_created(self, event):
                if event.is_directory and os.path.ismount(event.src_path):
                    self.monitor._handle_drive_event('connected', event.src_path)
                    
            def on_deleted(self, event):
                if event.is_directory:
                    self.monitor._handle_drive_event('disconnected', event.src_path)
        
        self.observer = Observer()
        handler = MacOSDriveHandler(self)
        
        volumes_path = '/Volumes'
        if os.path.exists(volumes_path):
            self.observer.schedule(handler, volumes_path, recursive=False)
            
        self.observer.start()
        
        # Also start periodic polling
        self._start_polling_thread()
    
    def _start_polling_thread(self, interval: float = 5.0):
        """Start periodic polling thread as fallback"""
        def polling_loop():
            while self.is_monitoring:
                try:
                    self._check_drive_changes()
                    time.sleep(interval)
                except Exception as e:
                    self.logger.error(f"Error in polling thread: {e}")
                    time.sleep(interval)
        
        self.monitoring_thread = threading.Thread(target=polling_loop, daemon=True)
        self.monitoring_thread.start()
    
    def _check_drive_changes(self):
        """Check for drive changes by comparing current vs known drives"""
        try:
            current_drives = self.smart_organizer.discover_available_drives()
            current_paths = set()
            
            # Collect all current drive paths
            for drive_type, drives in current_drives.items():
                for drive in drives:
                    path = drive.get('path', '')
                    if path:
                        current_paths.add(path)
                        
                        # Check if this is a new drive
                        if path not in self.known_drives:
                            self.known_drives[path] = {
                                'type': drive_type,
                                'info': drive,
                                'connected': True,
                                'last_seen': datetime.now().isoformat()
                            }
                            self._handle_drive_event('connected', path, drive)
                        else:
                            # Update existing drive
                            self.known_drives[path]['connected'] = True
                            self.known_drives[path]['last_seen'] = datetime.now().isoformat()
            
            # Check for disconnected drives
            for path, drive_info in self.known_drives.items():
                if path not in current_paths and drive_info['connected']:
                    drive_info['connected'] = False
                    self._handle_drive_event('disconnected', path)
                    
        except Exception as e:
            self.logger.error(f"Error checking drive changes: {e}")
    
    def _handle_drive_event(self, event_type: str, drive_path: str, drive_info: Dict = None):
        """Handle drive connection/disconnection events"""
        try:
            self.logger.info(f"Drive {event_type}: {drive_path}")
            
            if event_type == 'connected':
                # Try to register/update the drive in database
                if drive_info and 'usb' in drive_info.get('type', ''):
                    result = self.smart_organizer.register_usb_drive(drive_path)
                    if result.get('success'):
                        self.logger.info(f"USB drive registered: {result.get('message', '')}")
                
                # Update database connection status
                self._update_drive_connection_status(drive_path, True)
                
            elif event_type == 'disconnected':
                # Update database connection status
                self._update_drive_connection_status(drive_path, False)
            
            # Call callback if provided
            if self.callback:
                self.callback({
                    'event_type': event_type,
                    'drive_path': drive_path,
                    'drive_info': drive_info,
                    'timestamp': datetime.now().isoformat()
                })
                
        except Exception as e:
            self.logger.error(f"Error handling drive event: {e}")
    
    def _update_drive_connection_status(self, drive_path: str, is_connected: bool):
        """Update drive connection status in database"""
        try:
            # Find drive by path and update status
            drives = self.smart_organizer.db.get_user_drives(self.smart_organizer.user_id)
            
            for drive in drives:
                if drive.get('path') == drive_path:
                    self.smart_organizer.db.update_drive_connection_status(
                        user_id=self.smart_organizer.user_id,
                        primary_identifier=drive['primary_identifier'],
                        is_connected=is_connected,
                        current_path=drive_path if is_connected else None
                    )
                    break
                    
        except Exception as e:
            self.logger.error(f"Error updating drive connection status: {e}")
    
    def get_connected_drives(self) -> List[Dict]:
        """Get list of currently connected drives"""
        connected = []
        for path, drive_info in self.known_drives.items():
            if drive_info['connected']:
                connected.append({
                    'path': path,
                    'type': drive_info['type'],
                    'info': drive_info['info'],
                    'last_seen': drive_info['last_seen']
                })
        return connected
    
    def get_drive_history(self) -> Dict:
        """Get drive connection history"""
        return {
            'known_drives': self.known_drives,
            'total_drives': len(self.known_drives),
            'connected_count': len([d for d in self.known_drives.values() if d['connected']]),
            'disconnected_count': len([d for d in self.known_drives.values() if not d['connected']])
        }