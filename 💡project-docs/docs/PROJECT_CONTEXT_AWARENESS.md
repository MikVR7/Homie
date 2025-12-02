# Project Context Awareness

## Problem

User has a project folder and downloads related files separately. AI should recognize the relationship and organize files near their projects.

## Use Case

### Scenario 1: Project + Related Files

**Existing structure:**
```
/Projects/V2K/
  ├── index.html
  ├── app.js
  └── styles.css
```

**User downloads:**
- `V2K_test_image.jpg`
- `V2K_logo.png`
- `V2K_documentation.pdf`

**AI should recognize:**
- Files have "V2K" prefix
- "V2K" project exists in known destinations
- These files belong to the V2K project

**AI should suggest:**
```
V2K_test_image.jpg → /Projects/V2K/assets/V2K_test_image.jpg
V2K_logo.png → /Projects/V2K/assets/V2K_logo.png
V2K_documentation.pdf → /Projects/V2K/docs/V2K_documentation.pdf
```

### Scenario 2: Project Archive

**User downloads:** `V2K.zip` containing:
- `index.html`
- `app.js`
- `styles.css`
- `logo.png`
- `README.md`

**AI should:**
1. Recognize it's a web project (has index.html, app.js)
2. Extract to `/Projects/V2K/`
3. **Keep all files together** - don't split into different folders
4. Organize within project structure:
   ```
   /Projects/V2K/
     ├── index.html
     ├── app.js
     ├── styles.css
     ├── assets/logo.png
     └── README.md
   ```

### Scenario 3: Movie Archive

**User downloads:** `Movie.rar` containing:
- `Movie.mkv` (5GB)
- `Movie.nfo` (metadata)
- `Movie.srt` (subtitles)

**AI should:**
1. Recognize it's a movie (has .mkv)
2. Extract to `/Videos/Movies/Movie/`
3. Keep related files together:
   ```
   /Videos/Movies/Movie/
     ├── Movie.mkv
     ├── Movie.nfo
     └── Movie.srt
   ```
4. **No `type` field** - not a development project

## Implementation

### AI Prompt Enhancement

```
PROJECT CONTEXT AWARENESS:
1. Check known destinations for project names
2. Match files to projects by name patterns:
   - "ProjectName_file.ext" → ProjectName project
   - "projectname-asset.png" → projectname project
   - Case-insensitive matching
3. Suggest organizing related files near their projects
4. Add to appropriate subfolder:
   - Images/assets → assets/ or images/
   - Documentation → docs/
   - Config files → config/
   - Keep project structure intact

ARCHIVE HANDLING:
- Development projects: Keep files together, organize within project structure
- Media archives: Keep related files together (movie + subtitles + metadata)
- Mixed archives: Organize by file type, but keep related files grouped
```

### Example AI Response

**Input:**
```json
{
  "root": "/Downloads",
  "files": {
    ".": [
      {"file": "V2K_logo.png", "size": 0.5},
      {"file": "V2K_test.jpg", "size": 1.2}
    ]
  }
}
```

**Known destinations include:**
```
/Projects/V2K/ (used 15 times)
```

**AI Response:**
```json
{
  "results": {
    "/Downloads/V2K_logo.png": {
      "action": "move",
      "suggested_folder": "/Projects/V2K/assets",
      "reason": "Matches V2K project - logo asset"
    },
    "/Downloads/V2K_test.jpg": {
      "action": "move",
      "suggested_folder": "/Projects/V2K/assets",
      "reason": "Matches V2K project - test image"
    }
  }
}
```

## Pattern Matching Rules

### Strong Match (High Confidence)
- Exact prefix: `ProjectName_file.ext`
- Exact prefix with dash: `ProjectName-file.ext`
- Exact match in filename: `file_ProjectName_v2.ext`

### Weak Match (Lower Confidence)
- Partial match: `Proj_file.ext` (if "Project" exists)
- Case variations: `projectname_file.ext` (if "ProjectName" exists)

### No Match
- Common words: `test_file.ext` (too generic)
- Single letter: `V_file.ext` (too short)

## Edge Cases

### Multiple Projects Match
If `V2K_logo.png` could match both "V2K" and "V2K_Old":
- Prefer exact match: "V2K"
- Prefer more recently used project
- Prefer shorter name (less specific)

### Project Doesn't Exist Yet
If `NewProject_file.png` but no "NewProject" folder:
- Create new project folder: `/Projects/NewProject/`
- Organize file there: `/Projects/NewProject/assets/NewProject_file.png`

### Ambiguous Files
If `logo.png` (no project prefix):
- Can't match to specific project
- Organize by file type: `/Images/logo.png`
- Or ask user (future feature)

## Benefits

1. **Automatic project organization** - Files find their projects
2. **Maintains project structure** - Doesn't mess up existing organization
3. **Reduces manual work** - User doesn't need to manually move files
4. **Smart grouping** - Related files stay together

## Testing

### Test Case 1: Project Match
```
Known: /Projects/MyApp/
File: MyApp_screenshot.png
Expected: /Projects/MyApp/assets/MyApp_screenshot.png
```

### Test Case 2: No Match
```
Known: /Projects/MyApp/
File: random_image.png
Expected: /Images/random_image.png
```

### Test Case 3: Project Archive
```
File: MyApp.zip (contains: index.html, app.js, logo.png)
Expected: 
  - Extract to /Projects/MyApp/
  - Keep files together
  - Organize: logo.png → /Projects/MyApp/assets/logo.png
```

### Test Case 4: Movie Archive
```
File: Movie.rar (contains: Movie.mkv, Movie.srt)
Expected:
  - Extract to /Videos/Movies/Movie/
  - Keep files together
  - No splitting by type
```

---

**Status**: Implemented in AI prompt  
**Testing**: Ready for user testing  
**Priority**: High (common use case)
