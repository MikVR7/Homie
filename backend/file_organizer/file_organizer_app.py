#!/usr/bin/env python3
"""
FileOrganizerApp

High-level coordinator for the File Organizer module.

Responsibilities:
- Wire sub-managers and coordinate their lifecycle
- Subscribe to/join/leave events via EventBus
- Provide simple APIs to generate operations and execute them (via managers)

Note: DrivesManager is owned internally by PathMemoryManager (composition).
"""

from __future__ import annotations

import logging
from typing import Dict, Any, Optional


logger = logging.getLogger("FileOrganizerApp")


class FileOrganizerApp:
    def __init__(self, event_bus, shared_services):
        self.event_bus = event_bus
        self.shared_services = shared_services

        # Managers (initialized in start())
        self.path_memory_manager = None
        self.ai_command_generator = None
        self.file_operation_manager = None

        self._started = False
        self._component_name = "FileOrganizerApp"
        self._subscriptions: list[str] = []

    async def start(self) -> None:
        if self._started:
            return

        logger.info("📁 Starting FileOrganizerApp…")

        # Lazy imports to avoid circulars
        from .path_memory_manager import PathMemoryManager
        from .ai_command_generator import AICommandGenerator
        from .file_operation_manager import FileOperationManager

        # Instantiate managers
        self.path_memory_manager = PathMemoryManager(
            event_bus=self.event_bus,
            shared_services=self.shared_services,
        )
        await self.path_memory_manager.start()

        self.ai_command_generator = AICommandGenerator(
            event_bus=self.event_bus, shared_services=self.shared_services
        )
        self.file_operation_manager = FileOperationManager(event_bus=self.event_bus)

        # Subscribe to relevant events
        self._subscribe_events()

        self._started = True
        logger.info("✅ FileOrganizerApp started")

    async def shutdown(self) -> None:
        if not self._started:
            return
        logger.info("🛑 Shutting down FileOrganizerApp…")

        # Unsubscribe all
        self.event_bus.unsubscribe_component(self._component_name)
        self._subscriptions.clear()

        # Shutdown managers (reverse order)
        if self.file_operation_manager and hasattr(
            self.file_operation_manager, "shutdown"
        ):
            await self.file_operation_manager.shutdown()

        if self.ai_command_generator and hasattr(self.ai_command_generator, "shutdown"):
            await self.ai_command_generator.shutdown()

        if self.path_memory_manager:
            await self.path_memory_manager.shutdown()

        self._started = False
        logger.info("✅ FileOrganizerApp shut down")

    def _subscribe_events(self) -> None:
        # User joining/leaving file organizer module
        self._subscriptions.append(
            self.event_bus.subscribe(
                "file_organizer_user_joining", self._on_user_joining, self._component_name
            )
        )
        self._subscriptions.append(
            self.event_bus.subscribe(
                "file_organizer_user_leaving", self._on_user_leaving, self._component_name
            )
        )

    async def _on_user_joining(self, data: Dict[str, Any]):
        user_id = data.get("user_id")
        socket_id = data.get("socket_id")
        logger.info(f"👋 User joined File Organizer: {user_id} ({socket_id})")

        # Emit current drive status to the joining user (if available)
        try:
            if self.path_memory_manager:
                drive_status = await self.path_memory_manager.get_drive_status()
                await self.event_bus.emit_to_socket(
                    socket_id,
                    "file_organizer_drive_status",
                    {"drives": drive_status.get("drives", [])},
                )
        except Exception as e:
            logger.warning(f"Failed to send drive status: {e}")

    async def _on_user_leaving(self, data: Dict[str, Any]):
        user_id = data.get("user_id")
        socket_id = data.get("socket_id")
        logger.info(f"👋 User left File Organizer: {user_id} ({socket_id})")

    async def organize_folder(self, folder_path: str, intent: Optional[str] = None) -> Dict:
        """Generate abstract operations for a given folder (no execution)."""
        if not self._started:
            return {"success": False, "error": "module_not_started"}

        return await self.ai_command_generator.generate_operations(
            folder_path=folder_path,
            history_provider=self.path_memory_manager,
            intent=intent,
        )

    async def execute_operations(self, operations: list, dry_run: bool = False) -> Dict:
        if not self._started:
            return {"success": False, "error": "module_not_started"}
        return await self.file_operation_manager.execute_operations(
            operations, dry_run=dry_run
        )

    async def get_drives(self) -> Dict[str, Any]:
        if not self._started or not self.path_memory_manager:
            return {"drives": []}
        return await self.path_memory_manager.get_drive_status()

    async def get_folder_history(self, folder_path: str, limit: int = 50) -> Dict[str, Any]:
        if not self._started or not self.path_memory_manager:
            return {"success": False, "error": "module_not_started"}
        history = self.path_memory_manager.get_folder_history(folder_path, limit)
        return {
            "success": True,
            "folder_path": folder_path,
            "history": [
                {
                    "action_type": r.action_type,
                    "file_name": r.file_name,
                    "destination_path": r.destination_path,
                    "success": r.success,
                    "error_message": r.error_message,
                    "timestamp": r.timestamp.isoformat(),
                }
                for r in history
            ],
        }

    async def get_folder_summary(self, folder_path: str) -> Dict[str, Any]:
        if not self._started or not self.path_memory_manager:
            return {"success": False, "error": "module_not_started"}
        summary = self.path_memory_manager.get_folder_summary(folder_path)
        summary["success"] = True
        return summary

    async def health_check(self) -> Dict[str, Any]:
        return {
            "status": "healthy" if self._started else "stopped",
            "path_memory": await self.path_memory_manager.health_check()
            if self.path_memory_manager
            else {"status": "not_initialized"},
        }


