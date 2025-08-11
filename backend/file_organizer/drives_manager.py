#!/usr/bin/env python3
"""
DrivesManager

Lightweight drive discovery and monitoring used internally by PathMemoryManager.

Responsibilities:
- Provide a snapshot of currently available drives/mounts
- Optionally monitor changes and emit events via EventBus
"""

import asyncio
import logging
import os
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional


logger = logging.getLogger("DrivesManager")


@dataclass
class DriveInfo:
    path: str
    type: str  # 'local' | 'usb' | 'network' | 'cloud' (cloud placeholder)
    label: Optional[str] = None
    filesystem: Optional[str] = None
    is_connected: bool = True
    last_seen: Optional[str] = None


class DrivesManager:
    def __init__(self, event_bus):
        self.event_bus = event_bus
        self._monitor_task: Optional[asyncio.Task] = None
        self._running = False
        self._scan_interval_sec = 5
        self._last_snapshot: Dict[str, DriveInfo] = {}

    async def start(self) -> None:
        if self._running:
            return
        logger.info("🔌 Starting DrivesManager…")
        self._running = True
        # initial scan
        await self._rescan_and_emit_changes(initial=True)
        # background monitoring
        self._monitor_task = asyncio.create_task(self._monitor_loop())
        logger.info("✅ DrivesManager started")

    async def shutdown(self) -> None:
        if not self._running:
            return
        logger.info("🛑 Shutting down DrivesManager…")
        self._running = False
        if self._monitor_task:
            self._monitor_task.cancel()
            try:
                await self._monitor_task
            except asyncio.CancelledError:
                pass
        logger.info("✅ DrivesManager shut down")

    async def _monitor_loop(self) -> None:
        try:
            while self._running:
                await asyncio.sleep(self._scan_interval_sec)
                await self._rescan_and_emit_changes()
        except asyncio.CancelledError:
            return

    async def _rescan_and_emit_changes(self, initial: bool = False) -> None:
        snapshot = await self._scan_drives()

        # Detect removals
        removed = set(self._last_snapshot.keys()) - set(snapshot.keys())
        for path in removed:
            await self.event_bus.emit(
                "drive_removed",
                {"drive_path": path, "timestamp": datetime.now().isoformat()},
            )
            # Backward/compat: generic naming used by test client
            await self.event_bus.emit(
                "drive_disconnected",
                {"drive_path": path, "timestamp": datetime.now().isoformat()},
            )

        # Detect additions
        added = set(snapshot.keys()) - set(self._last_snapshot.keys())
        for path in added:
            info = snapshot[path]
            await self.event_bus.emit(
                "drive_added",
                {
                    "drive_path": path,
                    "label": info.label,
                    "type": info.type,
                    "filesystem": info.filesystem,
                },
            )
            # Backward/compat: generic naming used by test client
            await self.event_bus.emit(
                "drive_connected",
                {
                    "drive_path": path,
                    "label": info.label,
                    "type": info.type,
                    "filesystem": info.filesystem,
                },
            )

        # Emit full status (throttled by interval)
        payload = {"drives": [drive.__dict__ for drive in snapshot.values()]}
        await self.event_bus.emit("drive_status", payload)
        # Backward/compat broadcast name
        await self.event_bus.emit("drive_discovered", payload)

        self._last_snapshot = snapshot

        if initial:
            logger.info(f"💽 Initial drives snapshot: {list(snapshot.keys())}")

    async def _scan_drives(self) -> Dict[str, DriveInfo]:
        # Minimal cross-platform snapshot strategy
        # Linux/macOS: parse /proc/mounts or use psutil if added later
        drives: Dict[str, DriveInfo] = {}
        try:
            mounts_path = Path("/proc/mounts")
            if mounts_path.exists():
                with mounts_path.open("r", encoding="utf-8") as f:
                    for line in f:
                        parts = line.split()
                        if len(parts) < 3:
                            continue
                        device, mount_point, fs_type = parts[0], parts[1], parts[2]
                        # Filter system mounts
                        if mount_point.startswith("/proc") or mount_point.startswith("/sys"):
                            continue
                        drive_type = "local"
                        if mount_point.startswith("/media") or mount_point.startswith("/run/media"):
                            drive_type = "usb"
                        if ":" in device or fs_type.startswith("nfs"):
                            drive_type = "network"
                        drives[mount_point] = DriveInfo(
                            path=mount_point,
                            type=drive_type,
                            label=Path(mount_point).name,
                            filesystem=fs_type,
                            is_connected=True,
                            last_seen=datetime.now().isoformat(),
                        )
            else:
                # Fallback: list root and home (very minimal)
                for candidate in [Path("/"), Path.home()]:
                    drives[str(candidate)] = DriveInfo(
                        path=str(candidate), type="local", label=candidate.name or "/"
                    )
        except Exception as e:
            logger.warning(f"Drive scan warning: {e}")

        return drives

    async def get_status(self) -> Dict:
        return {"drives": [drive.__dict__ for drive in self._last_snapshot.values()]}


