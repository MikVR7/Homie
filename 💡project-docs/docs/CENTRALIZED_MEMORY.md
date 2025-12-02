# Centralized Memory System & USB Drive Features

## 🚨 **Problem Solved: No More Memory Files in Folders**

### **Previous Problem**
The old system was creating `.homie_memory.json` files in every folder, which was:
- ❌ **Cluttering** your file system
- ❌ **Not scalable** 
- ❌ **Hard to manage**
- ❌ **Poor user experience**

### **New Solution: Centralized Memory System**
All memory is now stored in a centralized SQLite database:
- ✅ **Clean file system** - No more memory files in folders
- ✅ **Scalable** - Handles thousands of operations efficiently
- ✅ **Easy to manage** - All data in one place
- ✅ **Better performance** - Fast database queries
- ✅ **User isolation** - Each user has their own memory
- ✅ **Module isolation** - Each module has its own database

## 🧠 **Centralized Memory Architecture**

### **Database Structure**
```
backend/data/
├── homie_users.db              # User management and authentication
└── modules/
    ├── homie_file_organizer.db    # File organization and destination memory
    ├── homie_financial_manager.db # Financial data and transactions
    ├── homie_media_manager.db     # Media library and watch history
    └── homie_document_manager.db  # Document management and OCR
```

### **File Organizer Database Tables**
- `destination_mappings` - Learned file category → destination mappings
- `series_mappings` - TV series episode organization
- `user_drives` - USB drive memory and purposes
- `file_actions` - File operation audit trail
- `module_data` - Module-specific configuration

## 💾 **USB Drive Memory System**

### **Features**
- **Drive Recognition**: Automatically detects USB drives when connected
- **Purpose Memory**: Remembers what each drive is used for
- **File Type Mapping**: Associates drives with specific file types
- **Connection Status**: Tracks which drives are currently connected
- **Persistent Memory**: Remembers drives even when disconnected

### **Ownership & Structure**
- `DrivesManager` is an internal dependency of `PathMemoryManager` (composition). Paths live on drives, so drive discovery/monitoring is encapsulated inside the path memory domain.
- External components do not call `DrivesManager` directly; they interact with `FileOrganizerApp`/`PathMemoryManager` APIs or listen to events on `EventBus` (`drive_added`, `drive_removed`, `drive_status`).

### **How It Works**

#### **1. Drive Registration**
When you connect a USB drive, you can register it with a purpose:

```bash
# Example: Register a drive for movies
curl -X POST http://localhost:8000/api/file-organizer/register-usb-drive \
  -H "Content-Type: application/json" \
  -d '{
    "drive_path": "/media/usb1",
    "purpose": "Movies and TV Shows",
    "file_types": ["mp4", "mkv", "avi", "mov"]
  }'
```

#### **2. Automatic Recognition**
The system remembers your drives and their purposes:

```bash
# Get all registered USB drives
curl http://localhost:8000/api/file-organizer/usb-drives
```

#### **3. Smart Suggestions**
When you have a file to organize, it suggests appropriate drives:

```bash
# Get destination suggestions for a movie file
curl -X POST http://localhost:8000/api/file-organizer/suggest-destination \
  -H "Content-Type: application/json" \
  -d '{
    "file_path": "movie.mp4",
    "file_type": "mp4"
  }'
```

### **Example Workflow**

1. **Connect USB Drive**: Plug in a USB drive for movies
2. **Register Purpose**: Tell the system it's for "Movies and TV Shows"
3. **System Remembers**: The system stores this information
4. **File Organization**: When you have a movie file, it suggests this drive
5. **Disconnect/Reconnect**: Even when disconnected, the system remembers
6. **Smart Suggestions**: When you reconnect, it asks if you want to use it

## 🔧 **API Endpoints**

For detailed API documentation, see:
- [API_ENDPOINTS.md](API_ENDPOINTS.md) - Complete API reference
- [DRIVE_MANAGER.md](DRIVE_MANAGER.md) - Drive management APIs
- [DESTINATION_MEMORY_MANAGER.md](DESTINATION_MEMORY_MANAGER.md) - Destination management APIs

## 📊 **Benefits**

### **For Users**
- **No More Clutter**: No memory files scattered in folders
- **Smart Organization**: System learns your preferences
- **USB Drive Memory**: Remembers your drives and their purposes
- **Better Performance**: Faster operations with centralized database
- **Data Safety**: All memory is backed up with the database

### **For Developers**
- **Scalable Architecture**: Can handle thousands of operations
- **Module Isolation**: Each module has its own database
- **User Isolation**: Complete data separation between users
- **Easy Maintenance**: All data in one place
- **Audit Trail**: Complete logging of all operations

## 🧪 **Testing**

### **Run the Tests**
```bash
# Test centralized memory system
python backend/test_centralized_memory.py

# Test USB drive memory with real paths
python backend/test_usb_drive_memory.py
```

### **Test Results**
- ✅ **Centralized memory system working correctly**
- ✅ **No memory files created in folders**
- ✅ **USB drive memory system functional**
- ✅ **Destination suggestions working**
- ✅ **Memory persistence implemented**

## 🔄 **Migration from Old System**

The old system that created `.homie_memory.json` files in folders has been completely replaced. The new system:

1. **Stores all data** in the centralized SQLite database
2. **No longer creates** memory files in folders
3. **Maintains backward compatibility** for existing functionality
4. **Provides better performance** and scalability

## 🎯 **Future Enhancements**

### **Planned Features**
- **Cloud Sync**: Synchronize USB drive memory across devices
- **Drive Labels**: Automatic drive labeling and recognition
- **Smart Categorization**: AI-powered drive purpose detection
- **Multi-User Support**: Share drive memory between family members
- **Mobile App**: USB drive management from mobile app

### **Advanced Features**
- **Drive Health Monitoring**: Track drive health and performance
- **Automatic Backup**: Suggest backup drives for important data
- **Network Drive Support**: Extend memory system to network drives
- **Drive Pooling**: Manage multiple drives as a single storage pool

## 📝 **Configuration**

### **Environment Variables**
```bash
# Required for AI features
GEMINI_API_KEY=your_api_key_here

# Database location (optional, defaults to backend/data)
HOMIE_DATA_DIR=backend/data
```

### **Database Location**
The centralized memory system stores data in:
- **Users**: `backend/data/homie_users.db`
- **File Organizer**: `backend/data/modules/homie_file_organizer.db`
- **Financial Manager**: `backend/data/modules/homie_financial_manager.db`
- **Media Manager**: `backend/data/modules/homie_media_manager.db`
- **Document Manager**: `backend/data/modules/homie_document_manager.db`

## 🎉 **Summary**

The new centralized memory system solves the major problem of cluttered memory files while adding powerful USB drive memory features. The system now:

- ✅ **Keeps your file system clean** - No more memory files in folders
- ✅ **Remembers your USB drives** - Knows what each drive is for
- ✅ **Suggests smart destinations** - Based on file types and drive purposes
- ✅ **Persists across sessions** - Memory survives app restarts
- ✅ **Scales efficiently** - Handles thousands of operations
- ✅ **Isolates user data** - Complete separation between users

This creates a much better user experience while providing powerful organization capabilities! 