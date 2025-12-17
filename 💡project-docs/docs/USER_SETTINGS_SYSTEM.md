# User Settings System

**Status**: ✅ Implemented and Tested  
**Version**: 1.0  
**Date**: 2025-12-17

## Overview

The User Settings System allows users to customize how files are renamed during organization. It supports both predefined naming conventions and custom templates with variables.

## Features

### 1. Predefined Naming Conventions

Users can choose from several naming conventions for each file type:

- **KeepOriginal**: Keep the original filename
- **CamelCase**: firstWordLowercase
- **PascalCase**: FirstWordUppercase
- **SnakeCase**: words_separated_by_underscores
- **KebabCase**: words-separated-by-hyphens
- **ContentBased**: AI generates descriptive names based on content
- **DateBased**: Use date-based naming (YYYY-MM-DD format)
- **FunctionBased**: Name based on primary function or purpose

### 2. Custom Templates

Users can create custom naming templates with variables:

#### Universal Variables
- `{date:format}` - Current date with custom format
- `{folder}` - Parent folder name
- `{ai_description}` - AI-generated description
- `{original_name}` - Original filename without extension

#### Image Variables
- `{exif_date:format}` - Photo date from EXIF
- `{dimensions}` - Image dimensions (e.g., "1920x1080")
- `{camera_model}` - Camera model from EXIF
- `{width}` - Image width in pixels
- `{height}` - Image height in pixels

#### Media Variables
- `{artist}` - Artist/performer name
- `{title}` - Song/video title
- `{album}` - Album name
- `{year}` - Release year
- `{genre}` - Genre/category
- `{duration}` - Duration in seconds

#### Code Variables
- `{main_function}` - Primary function name
- `{language}` - Programming language
- `{framework}` - Framework/library used

#### Document Variables
- `{author}` - Document author
- `{page_count}` - Number of pages

### 3. Date Format Patterns

Custom date formats use these patterns:
- `yyyy` - 4-digit year (2025)
- `yy` - 2-digit year (25)
- `MM` - Month with leading zero (01-12)
- `dd` - Day with leading zero (01-31)
- `HH` - Hour with leading zero (00-23)
- `mm` - Minute with leading zero (00-59)
- `ss` - Second with leading zero (00-59)

**Examples**:
- `{date:yyyy-MM-dd}` → 2025-12-17
- `{exif_date:yyyy-MM-dd_HH-mm}` → 2024-12-17_14-30

## Database Schema

### Migration 004: User File Naming Settings

```sql
CREATE TABLE user_file_naming_settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    enable_ai_renaming BOOLEAN DEFAULT TRUE,
    document_naming TEXT DEFAULT 'KeepOriginal',
    image_naming TEXT DEFAULT 'KeepOriginal',
    media_naming TEXT DEFAULT 'KeepOriginal',
    code_naming TEXT DEFAULT 'KeepOriginal',
    remove_special_chars BOOLEAN DEFAULT TRUE,
    remove_spaces BOOLEAN DEFAULT FALSE,
    lowercase_extensions BOOLEAN DEFAULT TRUE,
    max_filename_length INTEGER DEFAULT 100,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);
```

### Migration 005: Custom Templates

```sql
ALTER TABLE user_file_naming_settings ADD COLUMN document_custom_template TEXT DEFAULT '';
ALTER TABLE user_file_naming_settings ADD COLUMN image_custom_template TEXT DEFAULT '';
ALTER TABLE user_file_naming_settings ADD COLUMN media_custom_template TEXT DEFAULT '';
ALTER TABLE user_file_naming_settings ADD COLUMN code_custom_template TEXT DEFAULT '';
```

## API Endpoints

### GET /api/settings/file-naming

Get user's file naming settings.

**Query Parameters**:
- `user_id` (optional): User identifier (default: "dev_user")

**Response**:
```json
{
  "success": true,
  "settings": {
    "enableAIRenaming": true,
    "documentNaming": "ContentBased",
    "imageNaming": "CUSTOM_TEMPLATE",
    "mediaNaming": "ArtistDashTitle",
    "codeNaming": "SnakeCase",
    "documentCustomTemplate": "",
    "imageCustomTemplate": "{exif_date:yyyy-MM-dd} - {camera_model}",
    "mediaCustomTemplate": "",
    "codeCustomTemplate": "",
    "removeSpecialChars": true,
    "removeSpaces": false,
    "lowercaseExtensions": true,
    "maxFilenameLength": 100
  }
}
```

### POST /api/settings/file-naming

Save user's file naming settings.

**Request Body**:
```json
{
  "user_id": "dev_user",
  "settings": {
    "enableAIRenaming": true,
    "documentNaming": "ContentBased",
    "imageNaming": "CUSTOM_TEMPLATE",
    "imageCustomTemplate": "{exif_date:yyyy-MM-dd} - {camera_model}",
    "removeSpecialChars": true,
    "maxFilenameLength": 100
  }
}
```

**Response**:
```json
{
  "success": true,
  "message": "File naming settings saved successfully"
}
```

### GET /api/settings/template-variables

Get available template variables for a specific file type.

**Query Parameters**:
- `file_type`: 'document', 'image', 'media', or 'code'

**Response**:
```json
{
  "success": true,
  "file_type": "image",
  "variables": {
    "date:format": "Current date with custom format",
    "exif_date:format": "Photo date from EXIF",
    "dimensions": "Image dimensions",
    "camera_model": "Camera model from EXIF",
    "width": "Image width in pixels",
    "height": "Image height in pixels"
  }
}
```

### POST /api/settings/test-template

Test a custom template with sample data.

**Request Body**:
```json
{
  "template": "{exif_date:yyyy-MM-dd} - {camera_model}",
  "file_type": "image",
  "sample_data": {
    "date_taken": "2024:12:17 14:30:00",
    "camera_model": "Canon EOS R5"
  }
}
```

**Response**:
```json
{
  "success": true,
  "template": "{exif_date:yyyy-MM-dd} - {camera_model}",
  "result": "2024-12-17 - Canon EOS R5",
  "file_info_used": {...}
}
```

## Implementation

### Core Components

1. **UserSettingsManager** (`backend/file_organizer/user_settings_manager.py`)
   - Manages CRUD operations for user settings
   - Generates AI prompts based on user preferences
   - Validates settings before saving

2. **TemplateProcessor** (`backend/file_organizer/template_processor.py`)
   - Processes custom templates with variable substitution
   - Handles date formatting and EXIF data
   - Cleans and validates output filenames

3. **Settings Routes** (`backend/core/routes/settings_routes.py`)
   - Provides REST API endpoints
   - Handles template testing and variable discovery

### AI Integration

User settings are automatically loaded and applied during file analysis:

1. When `/api/file-organizer/organize` is called, the `user_id` is passed through the system
2. `AIContentAnalyzer._build_prompt_for_batch()` loads user settings
3. Settings are converted to AI prompt instructions
4. AI applies user preferences when suggesting file renames

## Usage Examples

### Example 1: Basic Settings

```python
from file_organizer.user_settings_manager import UserSettingsManager

settings_manager = UserSettingsManager('path/to/db')

# Save settings
settings = {
    'enableAIRenaming': True,
    'documentNaming': 'ContentBased',
    'imageNaming': 'DateBased',
    'mediaNaming': 'ArtistDashTitle',
    'codeNaming': 'SnakeCase',
    'removeSpecialChars': True,
    'maxFilenameLength': 100
}

settings_manager.save_file_naming_settings('user123', settings)
```

### Example 2: Custom Templates

```python
# Save settings with custom templates
settings = {
    'enableAIRenaming': True,
    'imageNaming': 'CUSTOM_TEMPLATE',
    'imageCustomTemplate': '{exif_date:yyyy-MM-dd} - {camera_model} - {width}x{height}',
    'mediaNaming': 'CUSTOM_TEMPLATE',
    'mediaCustomTemplate': '{artist} - {title} ({year})',
    'removeSpecialChars': True,
    'maxFilenameLength': 100
}

settings_manager.save_file_naming_settings('user123', settings)
```

### Example 3: Template Processing

```python
from file_organizer.template_processor import process_template

# Process image template
file_info = {
    'date_taken': '2024:12:17 14:30:00',
    'camera_model': 'Canon EOS R5',
    'width': 3840,
    'height': 2160
}

result = process_template('{exif_date:yyyy-MM-dd} - {camera_model}', file_info)
# Result: "2024-12-17 - Canon EOS R5"
```

## Testing

Run the complete test suite:

```bash
python3 test_user_settings_complete.py
```

Tests cover:
- ✅ Basic file naming settings
- ✅ Custom template system
- ✅ Template processing with various scenarios
- ✅ AI integration
- ✅ API endpoint registration

## Future Enhancements

Potential improvements for future versions:

1. **Template Library**: Pre-built templates for common use cases
2. **Conditional Logic**: Support for if/else in templates
3. **Custom Functions**: User-defined template functions
4. **Batch Operations**: Apply settings to existing files
5. **Template Validation**: Real-time validation in frontend
6. **Template Sharing**: Share templates between users

## Related Documentation

- [AI Content Analyzer](./AI_CONTENT_ANALYZER.md)
- [File Organization Workflow](./FILE_ORGANIZATION_WORKFLOW.md)
- [API Documentation](./API_DOCUMENTATION.md)
