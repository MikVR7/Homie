# Abstract Command System

## 🎯 **Universal Operations for Cross-Platform File Management**

The AI generates **abstract operations** that work on any platform - Windows, Linux, macOS, Android, iOS.

## 📋 **Complete Command Set**

### **File System Navigation & Information**
```json
{
  "operations": [
    {"type": "list_dir", "path": "/source", "show_hidden": false},
    {"type": "get_info", "path": "/file.txt"},
    {"type": "get_permissions", "path": "/folder"},
    {"type": "check_exists", "path": "/maybe/file.txt"},
    {"type": "get_size", "path": "/large/file.mkv"},
    {"type": "get_disk_space", "path": "/media/usb"}
  ]
}
```

### **File & Directory Operations**
```json
{
  "operations": [
    {"type": "mkdir", "path": "/Movies", "parents": true},
    {"type": "move", "src": "/source/file.mkv", "dest": "/Movies/file.mkv"},
    {"type": "copy", "src": "/source/doc.pdf", "dest": "/backup/doc.pdf"},
    {"type": "delete", "path": "/redundant.rar"},
    {"type": "rename", "src": "/old_name.txt", "dest": "/new_name.txt"}
  ]
}
```

### **Archive Operations**
```json
{
  "operations": [
    {"type": "extract", "archive": "/source.zip", "dest": "/extracted/", "delete_after": true},
    {"type": "compress", "files": ["/file1.txt", "/file2.txt"], "dest": "/backup.zip"},
    {"type": "list_archive", "archive": "/mystery.rar"}
  ]
}
```

### **Permission & Security Operations**
```json
{
  "operations": [
    {"type": "set_permissions", "path": "/script.sh", "mode": "755"},
    {"type": "change_owner", "path": "/file.txt", "owner": "user:group"},
    {"type": "unlock_file", "path": "/locked.doc", "method": "request_admin"},
    {"type": "check_access", "path": "/protected/", "permission": "write"}
  ]
}
```

### **Content Analysis**
```json
{
  "operations": [
    {"type": "read_text", "path": "/document.txt", "encoding": "utf-8"},
    {"type": "get_metadata", "path": "/movie.mkv"},
    {"type": "hash_file", "path": "/file.txt", "algorithm": "md5"},
    {"type": "find_duplicates", "paths": ["/folder1", "/folder2"]}
  ]
}
```

## 🔒 **Handling Locked/Protected Files**

### **Permission Levels**
```python
PERMISSION_LEVELS = {
    "public": "Anyone can access",
    "user": "Current user only", 
    "admin": "Requires administrator/root",
    "system": "System files - dangerous to modify",
    "encrypted": "Requires decryption key",
    "network": "Network permission required"
}
```

### **Lock Detection & Handling**
```json
{
  "operations": [
    {
      "type": "check_access",
      "path": "/protected/secret.txt",
      "permission": "read"
    }
  ],
  "fallback_strategies": [
    {"type": "request_admin", "reason": "Need admin access for system file"},
    {"type": "skip_file", "reason": "File is locked by another process"},
    {"type": "copy_unlocked", "reason": "Move copy instead of original"},
    {"type": "schedule_later", "reason": "Retry when file is not in use"}
  ]
}
```

## 🖥️ **Platform Translation Examples**

### **Directory Listing**
```json
{"type": "list_dir", "path": "/source", "show_hidden": false}
```

**Translates to:**
- **Linux/Mac**: `ls -la "/source"`
- **Windows**: `dir "C:\source" /A`
- **Python**: `os.listdir("/source")`
- **Mobile**: `Directory.listSync()`

### **File Operations**
```json
{"type": "move", "src": "/file.txt", "dest": "/new/file.txt"}
```

**Translates to:**
- **Linux/Mac**: `mv "/file.txt" "/new/file.txt"`
- **Windows**: `move "C:\file.txt" "C:\new\file.txt"`
- **Python**: `shutil.move("/file.txt", "/new/file.txt")`
- **Mobile**: `File.copy() + File.delete()`

### **Permission Checking**
```json
{"type": "check_access", "path": "/protected", "permission": "write"}
```

**Translates to:**
- **Linux/Mac**: `test -w "/protected" && echo "writable"`
- **Windows**: `icacls "C:\protected" | findstr "Write"`
- **Python**: `os.access("/protected", os.W_OK)`
- **Mobile**: `File.stat().mode & permissions`

## 🧠 **AI Intelligence Benefits**

### **Smart Fallbacks**
```json
{
  "primary_operation": {"type": "move", "src": "/locked.txt", "dest": "/dest/"},
  "fallback_operations": [
    {"type": "copy", "src": "/locked.txt", "dest": "/dest/locked.txt"},
    {"type": "request_admin", "reason": "File requires elevated permissions"}
  ]
}
```

### **Context-Aware Commands**
The AI can generate intelligent command sequences:

```json
{
  "strategy": "Safely organize locked system files",
  "operations": [
    {"type": "check_access", "path": "/system/file.log", "permission": "read"},
    {"type": "copy", "src": "/system/file.log", "dest": "/backup/system_file.log"},
    {"type": "set_permissions", "path": "/backup/system_file.log", "mode": "644"}
  ]
}
```

## 🔧 **Implementation Architecture**

### **Backend Command Translator**
```python
class AbstractCommandExecutor:
    def execute_operations(self, operations: List[Dict]) -> Dict:
        results = []
        for op in operations:
            try:
                if op["type"] == "list_dir":
                    result = self._list_directory(op["path"], op.get("show_hidden", False))
                elif op["type"] == "move":
                    result = self._move_file(op["src"], op["dest"])
                elif op["type"] == "check_access":
                    result = self._check_permissions(op["path"], op["permission"])
                # ... handle all operation types
                results.append({"operation": op, "success": True, "result": result})
            except PermissionError:
                results.append({"operation": op, "success": False, "error": "permission_denied"})
            except FileNotFoundError:
                results.append({"operation": op, "success": False, "error": "file_not_found"})
        return {"results": results}
```

### **Platform-Specific Implementations**
```python
class LinuxCommandExecutor(AbstractCommandExecutor):
    def _list_directory(self, path: str, show_hidden: bool) -> List[str]:
        cmd = f'ls -la "{path}"' if show_hidden else f'ls -l "{path}"'
        return subprocess.run(cmd, shell=True, capture_output=True, text=True)

class WindowsCommandExecutor(AbstractCommandExecutor):
    def _list_directory(self, path: str, show_hidden: bool) -> List[str]:
        cmd = f'dir "{path}" /A' if show_hidden else f'dir "{path}"'
        return subprocess.run(cmd, shell=True, capture_output=True, text=True)

class MobileFileExecutor(AbstractCommandExecutor):
    def _list_directory(self, path: str, show_hidden: bool) -> List[str]:
        # Use Flutter/Dart file system APIs
        return Directory(path).listSync(followLinks: false)
```

## 🚀 **Benefits of Abstract Command System**

### **For AI**
- ✅ **Single command vocabulary** - no platform-specific knowledge needed
- ✅ **Rich operation set** - can list, check, analyze files
- ✅ **Smart fallbacks** - handle permissions gracefully
- ✅ **Context awareness** - understand file system state

### **For System**
- ✅ **Platform agnostic** - works on any OS
- ✅ **Permission handling** - proper error handling for locked files
- ✅ **Security first** - controlled operations with proper validation
- ✅ **Extensible** - easy to add new operation types

### **For Users**
- ✅ **Consistent behavior** - same AI intelligence on any device
- ✅ **Safe operations** - proper permission checking
- ✅ **Transparent** - can see exactly what operations are planned
- ✅ **Fallback options** - AI suggests alternatives for locked files

This system gives the AI **full file system intelligence** while maintaining **security and cross-platform compatibility**!