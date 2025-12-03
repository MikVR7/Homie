# Destination Colors Feature

## Overview

The destination colors feature provides unique colors for each destination folder for visual identification across the application. **The backend is the source of truth for color assignment** - it automatically assigns colors from a predefined palette when destinations are created. Colors are persisted in the backend database and remain consistent across sessions and devices.

## Implementation Date

December 2, 2025

## Database Schema

### Migration 003: Destination Colors

Added `color` column to the `destinations` table:

```sql
ALTER TABLE destinations ADD COLUMN color TEXT;
```

**Properties:**
- Stores hex color codes (e.g., `#667eea`, `#f093fb`)
- Nullable (existing destinations won't have colors initially)
- Auto-assigned from predefined palette if not provided
- Validated and normalized on input

## Color Palette

The system uses a predefined palette of 20 distinct, accessible colors:

```python
COLOR_PALETTE = [
    "#667eea",  # Purple
    "#f093fb",  # Pink
    "#4facfe",  # Blue
    "#00f2fe",  # Cyan
    "#43e97b",  # Green
    "#fa709a",  # Rose
    "#fee140",  # Yellow
    "#30cfd0",  # Teal
    "#a8edea",  # Aqua
    "#fed6e3",  # Light Pink
    "#ff9a9e",  # Coral
    "#fecfef",  # Lavender
    "#fad0c4",  # Peach
    "#ffd1ff",  # Light Purple
    "#a1c4fd",  # Light Blue
    "#ffecd2",  # Cream
    "#fcb69f",  # Orange
    "#ff8a80",  # Red
    "#b2fefa",  # Mint
    "#81f5ff",  # Sky Blue
]
```

## Complete Workflow

### 1. Organize Files (Get Suggestions)

**POST /api/file-organizer/organize**

Backend analyzes files and returns suggested operations with color-coded destinations:

```json
{
  "success": true,
  "analysis_id": "analysis_123",
  "operations": [
    {
      "type": "move",
      "source": "/Downloads/file.pdf",
      "destination": "/Organized/Documents/file.pdf"
    }
  ],
  "suggested_destinations": {
    "Documents": {
      "path": "/Organized/Documents",
      "category": "Documents",
      "color": "#667eea",
      "is_existing": false
    }
  }
}
```

**Key Points:**
- Backend suggests colors for each destination folder
- `is_existing: true` means destination already exists (reuses existing color)
- `is_existing: false` means new destination (suggests new color from palette)

### 2. User Reviews and Accepts

Frontend displays suggestions to user. User can accept/reject individual operations.

### 3. Create Accepted Destinations

**POST /api/file-organizer/destinations**

Frontend creates destinations using suggested colors:

```json
{
  "path": "/Organized/Documents",
  "category": "Documents",
  "color": "#667eea",  // From suggested_destinations
  "user_id": "user123",
  "client_id": "laptop1"
}
```

**Response:**

```json
{
  "success": true,
  "destination": {
    "id": "dest_123",
    "path": "/Organized/Documents",
    "category": "Documents",
    "color": "#667eea",  // Backend confirms color
    "created_at": "2025-01-15T10:30:00Z",
    "usage_count": 0,
    "is_active": true
  }
}
```

## API Changes

### GET /api/file-organizer/destinations

**Response includes color field:**

```json
{
  "success": true,
  "destinations": [
    {
      "id": "dest_123",
      "path": "/home/user/Documents/Projects",
      "category": "Projects",
      "color": "#667eea",
      "drive_id": "drive_456",
      "created_at": "2025-01-15T10:30:00Z",
      "last_used_at": "2025-01-20T14:22:00Z",
      "usage_count": 5,
      "is_active": true
    }
  ]
}
```

### POST /api/file-organizer/destinations

**Request accepts optional color:**

```json
{
  "path": "/home/user/Documents/Projects",
  "category": "Projects",
  "color": "#667eea"
}
```

**Behavior (Backend is Source of Truth):**
- If `color` is provided and valid, it's used (frontend can suggest colors)
- If `color` is invalid, it's auto-assigned from palette
- If `color` is not provided, it's auto-assigned from palette
- **Auto-assignment strategy:**
  - First 20 destinations: Assign unused colors sequentially from palette
  - After 20 destinations: Cycle through palette sequentially (21st gets color[0], 22nd gets color[1], etc.)
  - This ensures consistent color assignment across sessions
- **Color repetition after 20 destinations is intentional and expected**

**Response:**

```json
{
  "success": true,
  "destination": {
    "id": "dest_123",
    "path": "/home/user/Documents/Projects",
    "category": "Projects",
    "color": "#667eea",
    "drive_id": "drive_456",
    "created_at": "2025-01-15T10:30:00Z",
    "usage_count": 0,
    "is_active": true
  }
}
```

### PUT /api/file-organizer/destinations/{destination_id}

**Update destination properties including color:**

```json
{
  "color": "#f093fb"
}
```

**Response:**

```json
{
  "success": true,
  "destination": {
    "id": "dest_123",
    "path": "/home/user/Documents/Projects",
    "category": "Projects",
    "color": "#f093fb",
    ...
  }
}
```

## Backend Implementation

### Color Palette Module

**File:** `backend/file_organizer/color_palette.py`

**Functions:**
- `is_valid_hex_color(color: str) -> bool` - Validate hex color format
- `normalize_hex_color(color: str) -> Optional[str]` - Normalize to lowercase #RRGGBB
- `assign_color_from_palette(existing_colors: List[str]) -> str` - Get next available color
- `get_next_available_color(existing_colors, preferred_color) -> str` - Prefer specific color if available

### DestinationMemoryManager Updates

**File:** `backend/file_organizer/destination_memory_manager.py`

**Updated Methods:**

1. **`add_destination()`** - Now accepts optional `color` parameter
   - Validates and normalizes color if provided
   - Auto-assigns color from palette if not provided
   - Ensures color uniqueness by checking existing colors

2. **`update_destination()`** - New method for updating destinations
   - Allows updating path, category, and/or color
   - Validates color format before updating

3. **`get_destinations()`** - Now includes color in results
4. **`get_destinations_for_client()`** - Now includes color in results
5. **`get_destinations_by_category()`** - Now includes color in results

**New Helper Method:**
- `_get_existing_colors(user_id, conn)` - Get all colors currently in use

### Model Updates

**File:** `backend/file_organizer/models.py`

Updated `Destination` dataclass to include `color` field:

```python
@dataclass
class Destination:
    id: str
    user_id: str
    path: str
    category: str
    color: Optional[str]  # NEW FIELD
    drive_id: Optional[str]
    created_at: datetime
    last_used_at: Optional[datetime]
    usage_count: int
    is_active: bool
```

## Color Assignment Logic

### Auto-Assignment Algorithm (Backend is Source of Truth)

**Strategy:** Backend assigns colors consistently and predictably

1. Get all existing colors for the user
2. Find first unused color from palette (for first 20 destinations)
3. After 20 destinations, cycle through palette sequentially
4. This ensures the 21st destination always gets color[0], 22nd gets color[1], etc.

```python
def assign_color_from_palette(existing_colors: List[str]) -> str:
    """
    Assign color from palette - BACKEND IS SOURCE OF TRUTH
    
    Strategy:
    - First 20 destinations: Assign unused colors sequentially
    - After 20: Cycle through palette (21st gets color[0], etc.)
    - This ensures consistent assignment across sessions
    """
    # Normalize existing colors
    normalized_existing = {normalize_hex_color(c) for c in existing_colors if c}
    
    # Find first available color (for first 20 destinations)
    for color in COLOR_PALETTE:
        if color not in normalized_existing:
            return color
    
    # All colors used: cycle through palette sequentially
    # This ensures consistent assignment (not random)
    used_count = len(existing_colors)
    return COLOR_PALETTE[used_count % len(COLOR_PALETTE)]
```

**Important Notes:**
- Colors **WILL repeat** after 20 destinations (this is intentional)
- Cycling is **sequential** (not random) for consistency
- Backend color assignment is **deterministic** and **reproducible**

### Color Validation

Colors are validated using regex pattern:

```python
pattern = r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$'
```

Supports:
- 6-digit hex: `#667eea`
- 3-digit hex: `#fff` (expanded to `#ffffff`)
- Case-insensitive (normalized to lowercase)

## Migration Strategy

### Existing Destinations

- Existing destinations have `color = NULL`
- Colors are auto-assigned when:
  - Frontend requests destinations (can assign on first load)
  - Destination is updated via PUT request
  - New files are organized to that destination

### New Destinations

- Frontend can assign colors before creating destinations
- Backend accepts and validates the provided color
- If no color provided, backend auto-assigns from palette

### Color Assignment Philosophy

**Backend is the Source of Truth:**
- Backend automatically assigns colors when destinations are created
- Backend validates colors are valid hex codes
- Backend uses sequential cycling for consistency
- Frontend may suggest colors, but backend makes final decision
- Frontend should use backend-assigned colors (not override them)
- Color repetition after 20 destinations is expected and intentional

## Testing

### Test Script

**File:** `backend/file_organizer/test_destination_colors.py`

**Tests:**
1. Color validation (hex format)
2. Color assignment from palette
3. Auto-assignment without color
4. Custom color assignment
5. Color updates
6. Color retrieval in GET requests

**Run tests:**
```bash
python3 backend/file_organizer/test_destination_colors.py
```

**Expected output:**
```
✅ TEST 1: Color Validation - PASSED
✅ TEST 2: Color Assignment - PASSED
✅ TEST 3: Destination Colors - PASSED
✅ ALL TESTS PASSED
```

## Frontend Integration

### Complete Workflow Example

```javascript
// Step 1: Organize files
const organizeResponse = await fetch('/api/file-organizer/organize', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    source_path: '/home/user/Downloads',
    destination_path: '/home/user/Organized',
    user_id: 'user123',
    client_id: 'laptop1'
  })
});

const { operations, suggested_destinations } = await organizeResponse.json();

// Step 2: Display suggestions to user with colors
operations.forEach(op => {
  const destFolder = getDestinationFolder(op.destination);
  const suggestedDest = suggested_destinations[destFolder];
  displayOperation(op, suggestedDest.color);  // Show with color
});

// Step 3: User accepts some operations
const acceptedOps = await getUserAcceptedOperations();

// Step 4: Create destinations with suggested colors
const uniqueDests = getUniqueDestinations(acceptedOps);
for (const destFolder of uniqueDests) {
  const suggestedDest = suggested_destinations[destFolder];
  
  await fetch('/api/file-organizer/destinations', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      path: suggestedDest.path,
      category: suggestedDest.category,
      color: suggestedDest.color,  // Use suggested color
      user_id: 'user123',
      client_id: 'laptop1'
    })
  });
}
```

### Updating Destination Color

```javascript
const response = await fetch(`/api/file-organizer/destinations/${destinationId}`, {
  method: 'PUT',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    color: '#f093fb',
    user_id: 'user123'
  })
});

const { destination } = await response.json();
console.log(`Updated color to: ${destination.color}`);
```

### Getting Destinations with Colors

```javascript
const response = await fetch('/api/file-organizer/destinations?user_id=user123&client_id=laptop1');
const { destinations } = await response.json();

destinations.forEach(dest => {
  console.log(`${dest.path}: ${dest.color}`);
  // Use dest.color for visual identification in UI
});
```

## Benefits

1. **Visual Identification**: Users can quickly identify destinations by color
2. **Consistency**: Colors persist across sessions and devices
3. **Automatic Assignment**: Backend assigns colors automatically - no manual selection needed
4. **Deterministic**: Same destination order always gets same colors (reproducible)
5. **Backend as Source of Truth**: Ensures consistency across all clients
6. **Validation**: Invalid colors are rejected or auto-corrected
7. **Scalability**: Supports unlimited destinations with sequential color cycling

## Files Modified

1. `backend/file_organizer/migrations/migration_003_destination_colors.py` - Database migration
2. `backend/file_organizer/models.py` - Added color field to Destination model
3. `backend/file_organizer/color_palette.py` - Color palette and validation utilities
4. `backend/file_organizer/destination_memory_manager.py` - Color handling in CRUD operations
5. `backend/core/routes/destination_routes.py` - API endpoints updated for color support
6. `backend/file_organizer/test_destination_colors.py` - Comprehensive test suite

## See Also

- [DESTINATION_MEMORY_MANAGER.md](DESTINATION_MEMORY_MANAGER.md) - Destination management API
- [API_ENDPOINTS.md](API_ENDPOINTS.md) - Complete API reference
- [FRONTEND_INTEGRATION_GUIDE.md](FRONTEND_INTEGRATION_GUIDE.md) - Frontend integration guide
