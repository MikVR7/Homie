#!/usr/bin/env python3
"""
FileOperationManager

Executes abstract operations using pure Python (pathlib/shutil/os) with per-op results.
"""

from __future__ import annotations

import logging
import os
import shutil
import zipfile
import tarfile
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
                elif op_type == "extract":
                    result = self._op_extract(op)
                elif op_type == "get_info":
                    result = self._op_get_info(op)
                elif op_type == "get_size":
                    result = self._op_get_size(op)
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

    def _op_extract(self, op: Dict[str, Any]):
        """Extract archive file"""
        archive_path = Path(op["archive"]).expanduser()
        dest_path = Path(op["dest"]).expanduser()
        delete_after = op.get("delete_after", False)
        
        if not archive_path.exists():
            raise FileNotFoundError(f"Archive not found: {archive_path}")
        
        # Create destination directory
        dest_path.mkdir(parents=True, exist_ok=True)
        
        # Extract based on file type
        ext = archive_path.suffix.lower()
        
        if ext == ".zip":
            with zipfile.ZipFile(archive_path, 'r') as zip_ref:
                zip_ref.extractall(dest_path)
        elif ext in [".tar", ".tar.gz", ".tgz", ".tar.bz2"]:
            with tarfile.open(archive_path, 'r') as tar_ref:
                tar_ref.extractall(dest_path)
        else:
            raise ValueError(f"Unsupported archive format: {ext}")
        
        result = {"archive": str(archive_path), "dest": str(dest_path)}
        
        # Delete archive if requested
        if delete_after:
            archive_path.unlink()
            result["deleted"] = True
        
        return result

    def _op_get_info(self, op: Dict[str, Any]):
        """Get file/directory information"""
        path = Path(op["path"]).expanduser()
        
        if not path.exists():
            return {"path": str(path), "exists": False}
        
        stat = path.stat()
        return {
            "path": str(path),
            "exists": True,
            "is_file": path.is_file(),
            "is_dir": path.is_dir(),
            "size": stat.st_size,
            "modified": stat.st_mtime,
            "permissions": oct(stat.st_mode)[-3:]
        }

    def _op_get_size(self, op: Dict[str, Any]):
        """Get file/directory size"""
        path = Path(op["path"]).expanduser()
        
        if not path.exists():
            raise FileNotFoundError(f"Path not found: {path}")
        
        if path.is_file():
            size = path.stat().st_size
        else:
            # Calculate directory size recursively
            size = sum(f.stat().st_size for f in path.rglob('*') if f.is_file())
        
        return {"path": str(path), "size": size}


