#!/usr/bin/env python3
"""
FileOperationManager

Executes abstract operations using pure Python (pathlib/shutil/os) with per-op results.
"""

from __future__ import annotations

import logging
import os
import shutil
from pathlib import Path
from typing import Dict, Any, List


logger = logging.getLogger("FileOperationManager")


class FileOperationManager:
    def __init__(self, event_bus):
        self.event_bus = event_bus

    async def shutdown(self) -> None:
        return

    async def execute_operations(self, operations: List[Dict[str, Any]], dry_run: bool = False) -> Dict[str, Any]:
        results: List[Dict[str, Any]] = []

        for op in operations or []:
            op_type = op.get("type")
            try:
                if dry_run:
                    results.append({"operation": op, "success": True, "dry_run": True})
                    continue

                if op_type == "mkdir":
                    result = self._op_mkdir(op)
                elif op_type == "move":
                    result = self._op_move(op)
                elif op_type == "copy":
                    result = self._op_copy(op)
                elif op_type == "delete":
                    result = self._op_delete(op)
                elif op_type == "rename":
                    result = self._op_rename(op)
                elif op_type == "check_exists":
                    result = self._op_check_exists(op)
                elif op_type == "list_dir":
                    result = self._op_list_dir(op)
                else:
                    raise ValueError(f"Unsupported operation type: {op_type}")

                results.append({"operation": op, "success": True, "result": result})
                await self.event_bus.emit("operation_progress", {"operation": op, "status": "done"})
            except Exception as e:
                err = str(e)
                logger.warning(f"Operation failed: {op_type} → {err}")
                results.append({"operation": op, "success": False, "error": err})
                await self.event_bus.emit("operation_failed", {"operation": op, "error": err})

        await self.event_bus.emit("operation_done", {"results": results})
        return {"success": True, "results": results}

    def _op_mkdir(self, op: Dict[str, Any]):
        path = Path(op["path"]).expanduser()
        if op.get("parents", True):
            path.mkdir(parents=True, exist_ok=True)
        else:
            path.mkdir(exist_ok=True)
        return {"path": str(path)}

    def _op_move(self, op: Dict[str, Any]):
        src = Path(op["src"]).expanduser()
        dest = Path(op["dest"]).expanduser()
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(src), str(dest))
        return {"src": str(src), "dest": str(dest)}

    def _op_copy(self, op: Dict[str, Any]):
        src = Path(op["src"]).expanduser()
        dest = Path(op["dest"]).expanduser()
        dest.parent.mkdir(parents=True, exist_ok=True)
        if src.is_dir():
            shutil.copytree(str(src), str(dest), dirs_exist_ok=True)
        else:
            shutil.copy2(str(src), str(dest))
        return {"src": str(src), "dest": str(dest)}

    def _op_delete(self, op: Dict[str, Any]):
        path = Path(op["path"]).expanduser()
        if path.is_dir():
            shutil.rmtree(str(path))
        elif path.exists():
            path.unlink()
        return {"path": str(path)}

    def _op_rename(self, op: Dict[str, Any]):
        src = Path(op["src"]).expanduser()
        dest = Path(op["dest"]).expanduser()
        src.rename(dest)
        return {"src": str(src), "dest": str(dest)}

    def _op_check_exists(self, op: Dict[str, Any]):
        path = Path(op["path"]).expanduser()
        return {"path": str(path), "exists": path.exists()}

    def _op_list_dir(self, op: Dict[str, Any]):
        path = Path(op["path"]).expanduser()
        show_hidden = bool(op.get("show_hidden", False))
        if not path.is_dir():
            raise FileNotFoundError(f"Not a directory: {path}")
        entries = []
        for entry in path.iterdir():
            if not show_hidden and entry.name.startswith("."):
                continue
            entries.append({
                "name": entry.name,
                "is_dir": entry.is_dir(),
                "path": str(entry),
                "size": entry.stat().st_size if entry.is_file() else None,
            })
        return {"entries": entries}


