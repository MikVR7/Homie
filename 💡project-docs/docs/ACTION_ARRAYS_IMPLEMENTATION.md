# Action Arrays Implementation

## Overview
The AI now returns an **array of actions** for each file instead of a single action. This allows for complex multi-step operations like:
- Rename a file, then move it
- Unpack an archive, then delete the original
- Extract files, organize them into different folders, then clean up

## Backend Response Format

### New Format (with actions array)
```json
{
  "success": true,
  "results": {
    "/path/to/file.pdf": {
      "actions": [
        {"type": "rename", "new_name": "cleaned.pdf"},
        {"type": "move", "destination": "/dest/Documents"}
      ],
      "suggested_folder": "/dest/Documents",  // Backward compatibility
      "new_name": "cleaned.pdf",              // Backward compatibility
      "action": "rename"                      // Backward compatibility (first action)
    }
  }
}
```

### Action Types

#### 1. Move Action
```json
{"type": "move", "destination": "/full/path/to/destination"}
```
Moves the file to the specified destination folder.

#### 2. Rename Action
```json
{"type": "rename", "new_name": "newfilename.ext"}
```
Renames the file. Usually followed by a move action.

#### 3. Unpack Action
```json
{"type": "unpack", "destination": "/full/path/to/extract/location"}
```
Extracts an archive to the specified location.

#### 4. Delete Action
```json
{"type": "delete"}
```
Deletes the file. Usually after unpacking an archive.

## Common Action Patterns

### Simple Move
```json
{
  "file": "photo.jpg",
  "source": 0,
  "actions": [
    {"type": "move", "destination": "/dest/Images"}
  ]
}
```

### Rename + Move
```json
{
  "file": "LSJF8089_report.pdf",
  "source": 0,
  "actions": [
    {"type": "rename", "new_name": "report.pdf"},
    {"type": "move", "destination": "/dest/Documents"}
  ]
}
```

### Unpack + Delete Archive
```json
{
  "file": "project.rar",
  "source": 0,
  "actions": [
    {"type": "unpack", "destination": "/dest/Projects/MyProject"},
    {"type": "delete"}
  ]
}
```

### Just Delete
```json
{
  "file": "garbage.tmp",
  "source": 0,
  "actions": [
    {"type": "delete"}
  ]
}
```

## AI Prompt Format

The AI receives files and returns actions in this format:

**AI Response (Fully Indexed):**
```json
{
  "results": [
    {
      "file": 0,
      "actions": [
        {"type": 0, "dest": 1}
      ]
    },
    {
      "file": 5,
      "actions": [
        {"type": 1, "new_name": "report.pdf"},
        {"type": 0, "dest": 1, "subfolder": "Documents"}
      ]
    },
    {
      "file": 8,
      "actions": [
        {"type": 2, "dest": 1, "subfolder": "Projects/MyProject"},
        {"type": 3}
      ]
    }
  ]
}
```

**Index Mappings:**
- `file`: Index from FILES list (0, 1, 2, ...)
- `type`: Index from ACTION TYPES list (0=move, 1=rename, 2=unpack, 3=delete)
- `dest`: Index from DESTINATION FOLDERS list (0, 1, 2, ...)

This fully indexed format minimizes token usage by avoiding repeated strings.

## Backend Processing

The backend:
1. Receives indexed actions from AI
2. Converts destination indices to full paths
3. Builds processed actions array with full paths
4. Maintains backward compatibility fields for legacy frontend code

## Frontend Implementation

### Parsing Actions

```csharp
public class FileOperation
{
    [JsonPropertyName("actions")]
    public List<FileAction> Actions { get; set; } = new();
    
    // Backward compatibility
    [JsonPropertyName("suggested_folder")]
    public string? SuggestedFolder { get; set; }
    
    [JsonPropertyName("new_name")]
    public string? NewName { get; set; }
    
    [JsonPropertyName("action")]
    public string? PrimaryAction { get; set; }
}

public class FileAction
{
    [JsonPropertyName("type")]
    public string Type { get; set; } = "";
    
    [JsonPropertyName("destination")]
    public string? Destination { get; set; }
    
    [JsonPropertyName("new_name")]
    public string? NewName { get; set; }
}
```

### Executing Actions

```csharp
public async Task ExecuteActionsAsync(string filePath, List<FileAction> actions)
{
    string currentPath = filePath;
    
    foreach (var action in actions)
    {
        switch (action.Type)
        {
            case "rename":
                var newPath = Path.Combine(
                    Path.GetDirectoryName(currentPath)!,
                    action.NewName!
                );
                File.Move(currentPath, newPath);
                currentPath = newPath;
                break;
                
            case "move":
                var destPath = Path.Combine(
                    action.Destination!,
                    Path.GetFileName(currentPath)
                );
                Directory.CreateDirectory(action.Destination!);
                File.Move(currentPath, destPath);
                currentPath = destPath;
                break;
                
            case "unpack":
                await UnpackArchiveAsync(currentPath, action.Destination!);
                break;
                
            case "delete":
                File.Delete(currentPath);
                break;
        }
    }
}
```

### UI Display

Show actions as a sequence in the UI:

```
photo.jpg
  → Move to Images/

LSJF8089_report.pdf
  1. Rename to report.pdf
  2. Move to Documents/

project.rar
  1. Extract to Projects/MyProject/
  2. Delete archive

garbage.tmp
  → Delete
```

## Benefits

1. **Flexibility**: Can express complex multi-step operations
2. **Clarity**: Each action is explicit and ordered
3. **Archive Handling**: Can unpack, organize contents, and delete archive in one plan
4. **Filename Cleaning**: Can rename before moving
5. **Backward Compatible**: Legacy fields still present for old frontend code

## Migration Notes

### For Frontend Developers

**Old Code:**
```csharp
if (operation.Action == "move")
{
    MoveFile(filePath, operation.SuggestedFolder);
}
```

**New Code (Recommended):**
```csharp
if (operation.Actions != null && operation.Actions.Any())
{
    await ExecuteActionsAsync(filePath, operation.Actions);
}
else
{
    // Fallback to legacy single action
    if (operation.Action == "move")
    {
        MoveFile(filePath, operation.SuggestedFolder);
    }
}
```

### Backward Compatibility

The backend still provides legacy fields:
- `action` - First action type
- `suggested_folder` - Destination from first move/unpack action
- `new_name` - New name from first rename action

This ensures old frontend code continues to work while you migrate to the new actions array.

## Testing

Test these scenarios:

1. **Simple move**: File with single move action
2. **Rename + move**: File that needs cleaning and organizing
3. **Unpack + delete**: Archive that should be extracted and removed
4. **Multiple files from archive**: Archive with files going to different destinations
5. **Just delete**: Garbage files that should be removed
6. **Complex workflow**: Archive → extract → rename files → move to different folders → delete archive

## Example Test Case

**Input:**
```
project_backup.rar containing:
  - LSJF8089_document.pdf
  - IMG_20250115_photo.jpg
  - .DS_Store
  - README.txt
```

**Expected Actions:**
```json
{
  "file": "project_backup.rar",
  "actions": [
    {"type": "unpack", "destination": "/temp/extract"},
    {"type": "delete"}
  ]
}
```

**Then for extracted files:**
```json
{
  "file": "LSJF8089_document.pdf",
  "actions": [
    {"type": "rename", "new_name": "document.pdf"},
    {"type": "move", "destination": "/dest/Documents"}
  ]
},
{
  "file": "IMG_20250115_photo.jpg",
  "actions": [
    {"type": "move", "destination": "/dest/Images"}
  ]
},
{
  "file": ".DS_Store",
  "actions": [
    {"type": "delete"}
  ]
},
{
  "file": "README.txt",
  "actions": [
    {"type": "move", "destination": "/dest/Projects/MyProject"}
  ]
}
```
