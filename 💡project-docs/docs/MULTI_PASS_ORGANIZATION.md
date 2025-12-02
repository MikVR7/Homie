# Multi-Pass File Organization

## Problem

Current system is **single-pass**:
1. AI analyzes files (including archives)
2. AI suggests: unpack, move, or delete
3. Operations executed
4. **Done** - extracted files not analyzed

**Missing**: AI can't organize files INSIDE archives intelligently.

## Use Case Example

User has: `project.zip` containing:
- `LSJFEIJ8089MyDiary.pdf` (needs rename)
- `document.pdf`
- `temp.tmp` (garbage)
- `.DS_Store` (garbage)
- `important.xlsx`

**Desired workflow**:
1. Extract `project.zip` → 5 files
2. Rename `LSJFEIJ8089MyDiary.pdf` → `MyDiary.pdf`
3. Delete `temp.tmp` and `.DS_Store`
4. Move `MyDiary.pdf` → `Documents/Personal/`
5. Move `document.pdf` → `Documents/`
6. Move `important.xlsx` → `Documents/Spreadsheets/`
7. Delete `project.zip` (now empty/redundant)

**Current system**: Can only do step 1, then stops.

## Solution: Multi-Pass Organization

### Pass 1: Initial Analysis
- Analyze all files (including archives)
- AI sees archive metadata (contents list from frontend)
- AI decides: unpack, move, or delete

### Pass 2: Post-Extraction Analysis (NEW)
- After unpacking, analyze extracted files
- AI sees actual files with metadata
- AI suggests: rename, move, delete
- Execute operations

### Pass 3+: Recursive (Optional)
- If extracted files contain more archives, repeat

## Implementation Design

### Option A: Automatic Multi-Pass (Recommended)

```python
def organize_with_multi_pass(files, source, dest):
    """
    Automatically handle multi-pass organization.
    """
    all_operations = []
    pass_number = 1
    files_to_analyze = files
    
    while files_to_analyze and pass_number <= 3:  # Max 3 passes
        logger.info(f"Pass {pass_number}: Analyzing {len(files_to_analyze)} files")
        
        # Analyze current batch
        results = ai_analyze(files_to_analyze)
        
        # Build operations
        operations = build_operations(results)
        all_operations.extend(operations)
        
        # Execute operations
        executed = execute_operations(operations)
        
        # Find newly extracted files for next pass
        extracted_files = []
        for op in executed:
            if op['type'] == 'unpack':
                # Get list of extracted files
                extracted = list_files_in_directory(op['target_path'])
                extracted_files.extend(extracted)
        
        # Next pass analyzes extracted files
        files_to_analyze = extracted_files
        pass_number += 1
    
    return all_operations
```

### Option B: User-Controlled Multi-Pass

```python
# Pass 1: User organizes archives
response1 = organize(files=['project.zip'])
# Returns: [{'type': 'unpack', 'target': '/dest/project/'}]

# User executes
execute(response1['operations'])

# Pass 2: User organizes extracted files
extracted_files = list_files('/dest/project/')
response2 = organize(files=extracted_files)
# Returns: [
#   {'type': 'rename', 'source': 'LSJF...MyDiary.pdf', 'target': 'MyDiary.pdf'},
#   {'type': 'delete', 'source': 'temp.tmp'},
#   {'type': 'move', 'source': 'MyDiary.pdf', 'target': '/dest/Documents/Personal/'}
# ]
```

## Enhanced AI Capabilities Needed

### 1. Filename Cleaning

AI should detect and clean garbage prefixes/suffixes:

```
LSJFEIJ8089MyDiary.pdf → MyDiary.pdf
IMG_20250115_143022.jpg → (keep as-is, or use EXIF date)
Copy of Copy of document.pdf → document.pdf
document (1).pdf → document.pdf
```

**Implementation**:
```python
# Add to AI prompt
"""
FILENAME CLEANING:
- Remove random prefixes (e.g., "LSJF8089_")
- Remove "Copy of" prefixes
- Remove "(1)", "(2)" suffixes
- Keep meaningful names

If filename needs cleaning, add a 'rename' step BEFORE move.
"""
```

### 2. Garbage File Detection

AI should identify and suggest deletion of:
- Temp files: `.tmp`, `.temp`, `~*`
- System files: `.DS_Store`, `Thumbs.db`, `desktop.ini`
- Cache files: `*.cache`, `*.bak`
- Empty files: 0 bytes

**Implementation**:
```python
# Add to AI prompt
"""
GARBAGE DETECTION:
Delete these automatically:
- .DS_Store, Thumbs.db, desktop.ini
- *.tmp, *.temp, ~*
- *.cache, *.bak
- Empty files (0 bytes)

Return action: "delete" for garbage files.
"""
```

### 3. Multi-Step Plans

Enhance file plans to support multiple steps per file:

```json
{
  "source": "LSJF8089MyDiary.pdf",
  "steps": [
    {
      "order": 1,
      "type": "rename",
      "target_path": "/temp/MyDiary.pdf",
      "reason": "Remove garbage prefix"
    },
    {
      "order": 2,
      "type": "move",
      "target_path": "/dest/Documents/Personal/MyDiary.pdf",
      "reason": "Personal document"
    }
  ]
}
```

## API Changes

### New Endpoint: POST /api/file-organizer/organize-recursive

```json
{
  "files": ["project.zip"],
  "source_path": "/source",
  "destination_path": "/dest",
  "recursive": true,
  "max_passes": 3,
  "auto_clean_filenames": true,
  "auto_delete_garbage": true
}
```

**Response**:
```json
{
  "success": true,
  "passes": [
    {
      "pass": 1,
      "files_analyzed": 1,
      "operations": [
        {"type": "unpack", "source": "project.zip", "extracted": 5}
      ]
    },
    {
      "pass": 2,
      "files_analyzed": 5,
      "operations": [
        {"type": "rename", "source": "LSJF...MyDiary.pdf", "target": "MyDiary.pdf"},
        {"type": "delete", "source": "temp.tmp"},
        {"type": "delete", "source": ".DS_Store"},
        {"type": "move", "source": "MyDiary.pdf", "target": "/dest/Documents/Personal/"},
        {"type": "move", "source": "document.pdf", "target": "/dest/Documents/"}
      ]
    }
  ],
  "total_operations": 7
}
```

## Implementation Priority

### Phase 1: Filename Cleaning (Easy)
- Add filename cleaning rules to AI prompt
- AI suggests rename operations
- **Benefit**: Cleaner file names immediately

### Phase 2: Garbage Detection (Easy)
- Add garbage detection rules to AI prompt
- AI suggests delete operations
- **Benefit**: Automatic cleanup

### Phase 3: Multi-Pass (Medium)
- Implement automatic re-analysis after extraction
- **Benefit**: Full archive organization

### Phase 4: Recursive (Hard)
- Handle nested archives
- Prevent infinite loops
- **Benefit**: Complete automation

## Current Workaround

**Until multi-pass is implemented**, users can:

1. First pass: Organize archives
   ```
   POST /organize → unpack project.zip
   ```

2. Execute unpacking
   ```
   POST /execute → extracts 5 files
   ```

3. Second pass: Organize extracted files
   ```
   POST /organize with extracted files → move/rename/delete
   ```

4. Execute operations
   ```
   POST /execute → organizes extracted files
   ```

**This works but requires 4 API calls instead of 1.**

## Recommendation

**Implement Phase 1 & 2 first** (filename cleaning + garbage detection):
- Easy to add to existing system
- Immediate value
- No architecture changes needed

**Then implement Phase 3** (multi-pass):
- Bigger change but huge UX improvement
- Fully automated archive organization

---

**Status**: Design phase  
**Priority**: High (common use case)  
**Complexity**: Medium  
**Expected timeline**: 2-3 days implementation
