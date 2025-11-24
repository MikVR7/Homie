# UI AI Suggestion

> Created: 2025-10-07  
> Category: guide  
> Reason: To store the UI suggestion provided by the external AI for future reference, as requested by the user.

## 'Disagree' Button API

When a user clicks the 'Disagree' button for a specific file suggestion, the frontend must make a POST request to the `/api/file-organizer/suggest-alternatives` endpoint to fetch alternative suggestions.

### Request Format

The backend expects a JSON payload with the `analysis_id` and a nested `rejected_operation` object.

**Example Request Body:**
```json
{
  "analysis_id": "unique-analysis-session-id-string",
  "rejected_operation": {
    "source": "/full/path/to/source/file.ext",
    "destination": "/full/path/to/destination/folder/file.ext",
    "type": "move"
  }
}
```

### Success Response

A successful response will return a list of alternative `FileOperation` objects.

**Example Success Body:**
```json
{
  "success": true,
  "alternatives": [
    {
      "source": "/path/to/file",
      "destination": "/alternative/path/file",
      "reason": "Explanation for this alternative",
      "type": "move"
    }
  ]
}
```

## User Interaction and Workflow

The AI Suggestions View is the primary interface for user interaction with the file organization proposals. It is composed of `CategoryCard` components, each representing a proposed destination folder.

## Key Features

### Per-File Actions
Each file "pill" within a category card has three action buttons:
- **Apply (✓):** Executes the suggested operation for that single file.
- **Why (?):** Opens a dialog displaying the AI's reasoning for the suggestion, fetched on-demand from the `/api/file-organizer/explain-operation` endpoint.
- **Disagree (X):** Fetches alternative suggestions from the `/api/file-organizer/suggest-alternatives` endpoint and displays them in a context menu. Selecting an alternative updates the file's destination and moves it to the new category.

### Dynamic Granularity
- **User Action:** The user clicks the "Add Granularity" button on a category card (e.g., "Documents").
- **Backend Call:** The frontend sends a request to `/api/file-organizer/add-granularity`. This endpoint supports two modes:
    1.  **Proposed Folder:** If the files for the "Documents" category have *not* yet been moved, the request **must** include the `file_paths` array containing the source paths of all files destined for that category. The `folder_path` will be the proposed destination (e.g., `.../Destination/Documents`).
    2.  **Existing Folder:** If the files have already been moved, the request only needs the `folder_path`. The backend will read the contents from disk.
- **UI Update:**
    - The backend responds with more specific sub-folder suggestions.
    - The UI creates new `CategoryCard` instances that are visually nested *inside* the parent card.
    - Files are moved from the parent card into the appropriate new sub-category card, creating a clear visual hierarchy. This can be done recursively.

## File Analysis and AI Sorting Screens

## File Analysis and AI Sorting Screens (User-Provided Mockups)

### Screen 1: File Browser (Initial Analysis)
**Shows after user selects source folder**

**Layout:**
- Header: Folder name (e.g., "My Documents") with item count badge (e.g., "47 items")
- Top-right: "✨ AI Organize" button (prominent, gradient)
- Warning banner: "📋 Files are currently unsorted and mixed together" (red/burgundy background)
- Grid of file cards displaying:
  - File icon (type-specific: PDF, JPG, XLSX, MP3, MP4, TXT, DOCX, CSV, PNG)
  - File name below icon
  - Dark card background (#1a1f2e or similar)
  - Rounded corners
  - Grid layout (4 columns responsive)

**Purpose:** 
- Show user all files in selected folder (and subfolders)
- Display current "unsorted" state
- Allow user to trigger AI organization

**Action:**
- Click "AI Organize" → Trigger AI analysis → Show Screen 2

---

### Screen 2: AI Sorting Proposal
**Shows after AI has analyzed and categorized files**

**Layout:**
- Category cards with rounded corners, dark background
- Each category shows:
  - 📁 Folder icon + Category name (e.g., "Documents", "Media", "Spreadsheets", "Audio")
  - File count badge (e.g., "5 files", "4 files", "2 files")
  - List of files in that category:
    - File icon + filename on left
    - ✅ Green checkmark button (accept/confirm)
    - ❌ Red X button (reject/move to different category)
  - Vertical stacking with spacing

**Categories shown in mockup:**
1. **Documents** (5 files): Report_Q3.pdf, Contract.docx, Meeting_notes.txt, Invoice_May.pdf
2. **Media** (4 files): vacation.jpg, screenshot.png, presentation.mp4, family_pic.jpg
3. **Spreadsheets** (2 files): Budget2024.xlsx, Sales_data.csv
4. **Audio** (2 files): song.mp3, podcast.mp3

**Interaction:**
- ✅ button: Accept this file in this category
- ❌ button: Reject/remove from category (could open category selector)
- Bulk actions could be added (Accept All per category)

**Purpose:**
- Show AI's categorization proposal
- Allow user to review and approve/reject each file placement
- Clear visual grouping by category

**Next Action:**
- After user confirms selections → Execute file moves → Show completion/success screen

## Overview

**User Note:** The following is a raw suggestion from a UI-generating AI. It should NOT be implemented directly. It is stored here for inspiration and for incorporating specific parts if requested in the future.

```html
<!-- ========================================
     HomieA - AI File Organizer
     Complete UI Design Code
     ======================================== -->

<!-- COLOR PALETTE -->
<!--
Main Background: #0a0e1a
Secondary Background: #0f1419
Card/Panel Background: #1a1f2e
Border Color: #1a1f2e
Primary Text: #e2e8f0
Secondary Text: #a0aec0
Muted Text: #718096
Accent Gradient Start: #667eea
Accent Gradient End: #764ba2
Success: #48bb78
Warning: #ed8936
Error: #f56565
-->

<!-- ========================================
     SCREEN 1: WELCOME / MAIN SCREEN
     ======================================== -->

<div class="flex h-full" style="background: #0a0e1a;">
  
  <!-- LEFT SIDEBAR: Destination Explorer -->
  <div id="left-sidebar" style="width: 256px; border-right: 1px solid #1a1f2e; background: #0f1419; display: flex; flex-direction: column;">
    <div style="padding: 16px; border-bottom: 1px solid #1a1f2e;">
      <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px;">
        <h3 style="font-size: 14px; font-weight: 600; color: #a0aec0;">Destination Explorer</h3>
        <button id="toggle-sidebar" style="background: transparent; border: none; color: #a0aec0; cursor: pointer; padding: 4px 8px;">←</button>
      </div>
    </div>
    <div style="flex: 1; overflow: auto; padding: 12px;" id="folder-tree">
      <div style="font-size: 12px; opacity: 0.5; text-align: center; padding: 32px 0; color: #a0aec0;">No destination configured</div>
    </div>
  </div>

  <!-- CENTER CONTENT -->
  <div id="center-content" style="flex: 1; display: flex; flex-direction: column;">
    
    <!-- TOP HEADER BAR -->
    <div style="padding: 16px; border-bottom: 1px solid #1a1f2e; background: #0f1419; display: flex; align-items: center; justify-content: space-between;">
      <div style="display: flex; align-items: center; gap: 12px;">
        <div style="width: 40px; height: 40px; border-radius: 8px; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);">
          <span style="font-size: 20px;">🏠</span>
        </div>
        <div>
          <h1 style="font-size: 18px; font-weight: 700; color: #e2e8f0; margin: 0;">HomieA</h1>
          <p style="font-size: 12px; color: #718096; margin: 0;">AI-Powered File Organization</p>
        </div>
      </div>
      <button id="btn-lets-sort" style="padding: 8px 16px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border: none; color: white; border-radius: 6px; cursor: pointer; display: flex; align-items: center; gap: 8px; font-size: 14px; font-weight: 500;">
        <span>✨</span>
        <span>Let's Sort!</span>
      </button>
    </div>

    <!-- MAIN VIEW: Welcome Screen -->
    <div id="main-view" style="flex: 1; overflow: auto;">
      <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100%; padding: 32px;">
        <div style="max-width: 768px; text-align: center;">
          
          <!-- Hero Icon -->
          <div style="position: relative; display: inline-block; margin-bottom: 32px;">
            <div style="width: 128px; height: 128px; border-radius: 24px; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);">
              <span style="font-size: 72px;">📁</span>
            </div>
            <div style="position: absolute; bottom: -8px; right: -8px; width: 48px; height: 48px; border-radius: 50%; display: flex; align-items: center; justify-content: center; background: #0f1419; border: 3px solid #667eea;">
              <span style="font-size: 24px;">✨</span>
            </div>
          </div>
          
          <h2 style="font-size: 36px; font-weight: 700; color: #e2e8f0; margin-bottom: 16px;">Welcome to HomieA</h2>
          <p style="font-size: 18px; color: #a0aec0; margin-bottom: 32px; line-height: 1.6;">Your intelligent assistant for organizing messy folders. Let AI analyze your files and create a clean, logical structure automatically.</p>
          
          <!-- Feature Cards -->
          <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; margin-bottom: 32px;">
            <div style="padding: 16px; border-radius: 12px; background: #1a1f2e;">
              <div style="font-size: 32px; margin-bottom: 8px;">🔍</div>
              <div style="font-size: 14px; font-weight: 600; color: #e2e8f0; margin-bottom: 4px;">AI Analysis</div>
              <div style="font-size: 12px; color: #a0aec0;">Smart file categorization</div>
            </div>
            <div style="padding: 16px; border-radius: 12px; background: #1a1f2e;">
              <div style="font-size: 32px; margin-bottom: 8px;">📊</div>
              <div style="font-size: 14px; font-weight: 600; color: #e2e8f0; margin-bottom: 4px;">Visual Review</div>
              <div style="font-size: 12px; color: #a0aec0;">See before you organize</div>
            </div>
            <div style="padding: 16px; border-radius: 12px; background: #1a1f2e;">
              <div style="font-size: 32px; margin-bottom: 8px;">⚡</div>
              <div style="font-size: 14px; font-weight: 600; color: #e2e8f0; margin-bottom: 4px;">One Click</div>
              <div style="font-size: 12px; color: #a0aec0;">Instant organization</div>
            </div>
          </div>

          <button id="btn-setup-destination" style="padding: 12px 24px; background: transparent; border: 2px solid #667eea; color: #667eea; border-radius: 6px; cursor: pointer; display: inline-flex; align-items: center; gap: 8px; font-size: 14px; font-weight: 500;">
            <span>⚙️</span>
            <span>Configure Destination Folder</span>
          </button>
        </div>
      </div>
    </div>
  </div>

  <!-- RIGHT SIDEBAR (hidden by default) -->
  <div id="right-sidebar" style="width: 288px; border-left: 1px solid #1a1f2e; background: #0f1419; display: none; flex-direction: column;">
    <div style="padding: 16px; border-bottom: 1px solid #1a1f2e;">
      <h3 style="font-size: 14px; font-weight: 600; color: #a0aec0;">Details</h3>
    </div>
    <div style="flex: 1; overflow: auto; padding: 16px;">
      <div style="font-size: 12px; opacity: 0.5; text-align: center; padding: 32px 0; color: #a0aec0;">Select a file to view details</div>
    </div>
  </div>
</div>


<!-- ========================================
     SCREEN 2: SELECT SOURCE FOLDER
     ======================================== -->

<!-- Replace #main-view content with this: -->
<div id="main-view-source-selection" style="flex: 1; overflow: auto; padding: 32px;">
  <div style="max-width: 600px; margin: 0 auto;">
    <div style="text-align: center; margin-bottom: 32px;">
      <h2 style="font-size: 28px; font-weight: 700; color: #e2e8f0; margin-bottom: 8px;">Select Source Folder</h2>
      <p style="font-size: 14px; color: #a0aec0;">Choose the messy folder you want to organize</p>
    </div>

    <!-- Folder Selection Area -->
    <div style="padding: 48px; border: 2px dashed #667eea; border-radius: 16px; background: #1a1f2e; text-align: center; margin-bottom: 24px;">
      <div style="font-size: 64px; margin-bottom: 16px;">📂</div>
      <button id="btn-browse-folder" style="padding: 12px 32px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border: none; color: white; border-radius: 8px; cursor: pointer; font-size: 16px; font-weight: 600; margin-bottom: 12px;">
        Browse Folders
      </button>
      <p style="font-size: 12px; color: #718096; margin: 0;">or drag and drop a folder here</p>
    </div>

    <!-- Quick Access Folders -->
    <div>
      <h3 style="font-size: 14px; font-weight: 600; color: #a0aec0; margin-bottom: 12px;">Quick Access</h3>
      <div style="display: flex; flex-direction: column; gap: 8px;">
        <button style="padding: 12px 16px; background: #1a1f2e; border: 1px solid #1a1f2e; border-radius: 8px; cursor: pointer; display: flex; align-items: center; gap: 12px; color: #e2e8f0; text-align: left; transition: all 0.2s;">
          <span style="font-size: 24px;">⬇️</span>
          <div style="flex: 1;">
            <div style="font-size: 14px; font-weight: 500;">Downloads</div>
            <div style="font-size: 12px; color: #718096;">C:\Users\YourName\Downloads</div>
          </div>
        </button>
        <button style="padding: 12px 16px; background: #1a1f2e; border: 1px solid #1a1f2e; border-radius: 8px; cursor: pointer; display: flex; align-items: center; gap: 12px; color: #e2e8f0; text-align: left;">
          <span style="font-size: 24px;">🖼️</span>
          <div style="flex: 1;">
            <div style="font-size: 14px; font-weight: 500;">Pictures</div>
            <div style="font-size: 12px; color: #718096;">C:\Users\YourName\Pictures</div>
          </div>
        </button>
        <button style="padding: 12px 16px; background: #1a1f2e; border: 1px solid #1a1f2e; border-radius: 8px; cursor: pointer; display: flex; align-items: center; gap: 12px; color: #e2e8f0; text-align: left;">
          <span style="font-size: 24px;">📄</span>
          <div style="flex: 1;">
            <div style="font-size: 14px; font-weight: 500;">Documents</div>
            <div style="font-size: 12px; color: #718096;">C:\Users\YourName\Documents</div>
          </div>
        </button>
      </div>
    </div>
  </div>
</div>


<!-- ========================================
     SCREEN 3: AI ANALYZING (Loading State)
     ======================================== -->

<div id="main-view-analyzing" style="flex: 1; overflow: auto; display: flex; align-items: center; justify-content: center;">
  <div style="text-align: center; max-width: 480px; padding: 32px;">
    <!-- Animated Icon -->
    <div style="margin-bottom: 24px;">
      <div style="width: 96px; height: 96px; margin: 0 auto; border-radius: 50%; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); display: flex; align-items: center; justify-content: center; animation: pulse 2s infinite;">
        <span style="font-size: 48px;">🤖</span>
      </div>
    </div>
    
    <h2 style="font-size: 24px; font-weight: 700; color: #e2e8f0; margin-bottom: 12px;">AI is Analyzing...</h2>
    <p style="font-size: 14px; color: #a0aec0; margin-bottom: 24px;">Scanning 247 files and creating an intelligent organization structure</p>
    
    <!-- Progress Bar -->
    <div style="width: 100%; height: 8px; background: #1a1f2e; border-radius: 4px; overflow: hidden; margin-bottom: 16px;">
      <div style="width: 65%; height: 100%; background: linear-gradient(90deg, #667eea 0%, #764ba2 100%); transition: width 0.5s;"></div>
    </div>
    
    <div style="font-size: 12px; color: #718096;">Processing file types and content patterns...</div>
  </div>
</div>


<!-- ========================================
     SCREEN 4: AI SUGGESTIONS VIEW (Most Important)
     ======================================== -->

<div id="main-view-suggestions" style="flex: 1; overflow: auto; display: flex; flex-direction: column;">
  
  <!-- Summary Header -->
  <div style="padding: 24px; border-bottom: 1px solid #1a1f2e; background: #0f1419;">
    <div style="display: flex; items-align: center; justify-content: space-between; margin-bottom: 16px;">
      <div>
        <h2 style="font-size: 24px; font-weight: 700; color: #e2e8f0; margin-bottom: 4px;">AI Sorting Suggestions</h2>
        <p style="font-size: 14px; color: #a0aec0; margin: 0;">Review and approve the proposed file organization</p>
      </div>
      <div style="display: flex; gap: 12px;">
        <button id="btn-accept-all" style="padding: 10px 20px; background: #48bb78; border: none; color: white; border-radius: 6px; cursor: pointer; font-weight: 600;">
          ✓ Accept All
        </button>
        <button id="btn-decline-all" style="padding: 10px 20px; background: transparent; border: 1px solid #f56565; color: #f56565; border-radius: 6px; cursor: pointer; font-weight: 600;">
          ✗ Cancel
        </button>
      </div>
    </div>

    <!-- Stats -->
    <div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px;">
      <div style="padding: 12px; background: #1a1f2e; border-radius: 8px;">
        <div style="font-size: 12px; color: #a0aec0; margin-bottom: 4px;">Total Files</div>
        <div style="font-size: 24px; font-weight: 700; color: #e2e8f0;">247</div>
      </div>
      <div style="padding: 12px; background: #1a1f2e; border-radius: 8px;">
        <div style="font-size: 12px; color: #a0aec0; margin-bottom: 4px;">New Folders</div>
        <div style="font-size: 24px; font-weight: 700; color: #667eea;">8</div>
      </div>
      <div style="padding: 12px; background: #1a1f2e; border-radius: 8px;">
        <div style="font-size: 12px; color: #a0aec0; margin-bottom: 4px;">Categories</div>
        <div style="font-size: 24px; font-weight: 700; color: #764ba2;">5</div>
      </div>
      <div style="padding: 12px; background: #1a1f2e; border-radius: 8px;">
        <div style="font-size: 12px; color: #a0aec0; margin-bottom: 4px;">Space Saved</div>
        <div style="font-size: 24px; font-weight: 700; color: #48bb78;">2.4GB</div>
      </div>
    </div>
  </div>

  <!-- Suggestions List -->
  <div style="flex: 1; overflow: auto; padding: 16px;">
    
    <!-- Category Group: Documents -->
    <div style="margin-bottom: 24px;">
      <div style="display: flex; align-items: center; justify-content: space-between; padding: 12px; background: #1a1f2e; border-radius: 8px 8px 0 0; border-bottom: 2px solid #667eea;">
        <div style="display: flex; align-items: center; gap: 12px;">
          <input type="checkbox" checked style="width: 18px; height: 18px; cursor: pointer;" />
          <span style="font-size: 24px;">📄</span>
          <div>
            <h3 style="font-size: 16px; font-weight: 600; color: #e2e8f0; margin: 0;">Documents</h3>
            <p style="font-size: 12px; color: #a0aec0; margin: 0;">43 files → /Documents</p>
          </div>
        </div>
        <button style="padding: 6px 12px; background: transparent; border: 1px solid #667eea; color: #667eea; border-radius: 4px; font-size: 12px; cursor: pointer;">
          Edit
        </button>
      </div>
      
      <!-- Files in this category -->
      <div style="background: #0f1419; border-radius: 0 0 8px 8px; padding: 8px;">
        
        <!-- File Item 1 -->
        <div style="display: flex; align-items: center; gap: 12px; padding: 12px; background: #1a1f2e; border-radius: 6px; margin-bottom: 8px;">
          <input type="checkbox" checked style="width: 16px; height: 16px; cursor: pointer;" />
          <span style="font-size: 20px;">📝</span>
          <div style="flex: 1;">
            <div style="font-size: 14px; font-weight: 500; color: #e2e8f0; margin-bottom: 2px;">Invoice_2024_March.pdf</div>
            <div style="font-size: 12px; color: #718096;">247 KB • PDF Document</div>
          </div>
          <div style="text-align: right;">
            <div style="font-size: 12px; color: #a0aec0; margin-bottom: 2px;">→ /Documents/Invoices</div>
            <div style="font-size: 11px; color: #667eea;">New folder</div>
          </div>
        </div>

        <!-- File Item 2 -->
        <div style="display: flex; align-items: center; gap: 12px; padding: 12px; background: #1a1f2e; border-radius: 6px; margin-bottom: 8px;">
          <input type="checkbox" checked style="width: 16px; height: 16px; cursor: pointer;" />
          <span style="font-size: 20px;">📄</span>
          <div style="flex: 1;">
            <div style="font-size: 14px; font-weight: 500; color: #e2e8f0; margin-bottom: 2px;">Meeting_Notes.docx</div>
            <div style="font-size: 12px; color: #718096;">156 KB • Word Document</div>
          </div>
          <div style="text-align: right;">
            <div style="font-size: 12px; color: #a0aec0;">→ /Documents/Work</div>
          </div>
        </div>

        <!-- Show More Button -->
        <button style="width: 100%; padding: 8px; background: transparent; border: 1px dashed #1a1f2e; color: #a0aec0; border-radius: 6px; font-size: 12px; cursor: pointer;">
          + Show 41 more files
        </button>
      </div>
    </div>

    <!-- Category Group: Images -->
    <div style="margin-bottom: 24px;">
      <div style="display: flex; align-items: center; justify-content: space-between; padding: 12px; background: #1a1f2e; border-radius: 8px 8px 0 0; border-bottom: 2px solid #764ba2;">
        <div style="display: flex; align-items: center; gap: 12px;">
          <input type="checkbox" checked style="width: 18px; height: 18px; cursor: pointer;" />
          <span style="font-size: 24px;">🖼️</span>
          <div>
            <h3 style="font-size: 16px; font-weight: 600; color: #e2e8f0; margin: 0;">Images</h3>
            <p style="font-size: 12px; color: #a0aec0; margin: 0;">89 files → /Images</p>
          </div>
        </div>
        <button style="padding: 6px 12px; background: transparent; border: 1px solid #764ba2; color: #764ba2; border-radius: 4px; font-size: 12px; cursor: pointer;">
          Edit
        </button>
      </div>
      
      <div style="background: #0f1419; border-radius: 0 0 8px 8px; padding: 8px;">
        <button style="width: 100%; padding: 8px; background: transparent; border: 1px dashed #1a1f2e; color: #a0aec0; border-radius: 6px; font-size: 12px; cursor: pointer;">
          + Show 89 files
        </button>
      </div>
    </div>

    <!-- Category Group: Videos -->
    <div style="margin-bottom: 24px;">
      <div style="display: flex; align-items: center; justify-content: space-between; padding: 12px; background: #1a1f2e; border-radius: 8px;">
        <div style="display: flex; align-items: center; gap: 12px;">
          <input type="checkbox" checked style="width: 18px; height: 18px; cursor: pointer;" />
          <span style="font-size: 24px;">🎬</span>
          <div>
            <h3 style="font-size: 16px; font-weight: 600; color: #e2e8f0; margin: 0;">Videos</h3>
            <p style="font-size: 12px; color: #a0aec0; margin: 0;">32 files → /Videos</p>
          </div>
        </div>
        <button style="padding: 6px 12px; background: transparent; border: 1px solid #667eea; color: #667eea; border-radius: 4px; font-size: 12px; cursor: pointer;">
          Edit
        </button>
      </div>
    </div>

  </div>
</div>


<!-- ========================================
     SCREEN 5: FOLDER TREE WITH CONTENT
     (For Left Sidebar after destination is configured)
     ======================================== -->

<div id="folder-tree-populated" style="padding: 12px;">
  
  <!-- Root Folder -->
  <div style="margin-bottom: 8px;">
    <div style="display: flex; align-items: center; gap: 8px; padding: 8px; background: #1a1f2e; border-radius: 6px; cursor: pointer;">
      <span style="font-size: 12px;">📁</span>
      <span style="font-size: 13px; font-weight: 500; color: #e2e8f0;">My Organized Files</span>
    </div>
    
    <!-- Sub-folders -->
    <div style="margin-left: 16px; margin-top: 4px;">
      <div style="display: flex; align-items: center; gap: 8px; padding: 6px 8px; border-radius: 4px; cursor: pointer;">
        <span style="font-size: 11px;">📄</span>
        <span style="font-size: 12px; color: #a0aec0;">Documents</span>
        <span style="font-size: 10px; color: #718096;">(43)</span>
      </div>
      <div style="display: flex; align-items: center; gap: 8px; padding: 6px 8px; border-radius: 4px; cursor: pointer;">
        <span style="font-size: 11px;">🖼️</span>
        <span style="font-size: 12px; color: #a0aec0;">Images</span>
        <span style="font-size: 10px; color: #718096;">(89)</span>
      </div>
      <div style="display: flex; align-items: center; gap: 8px; padding: 6px 8px; border-radius: 4px; cursor: pointer;">
        <span style="font-size: 11px;">🎬</span>
        <span style="font-size: 12px; color: #a0aec0;">Videos</span>
        <span style="font-size: 10px; color: #718096;">(32)</span>
      </div>
      <div style="display: flex; align-items: center; gap: 8px; padding: 6px 8px; border-radius: 4px; cursor: pointer;">
        <span style="font-size: 11px;">🎵</span>
        <span style="font-size: 12px; color: #a0aec0;">Music</span>
        <span style="font-size: 10px; color: #718096;">(67)</span>
      </div>
      <div style="display: flex; align-items: center; gap: 8px; padding: 6px 8px; border-radius: 4px; cursor: pointer;">
        <span style="font-size: 11px;">📦</span>
        <span style="font-size: 12px; color: #a0aec0;">Archives</span>
        <span style="font-size: 10px; color: #718096;">(16)</span>
      </div>
    </div>
  </div>
  
</div>


<!-- ========================================
     ADDITIONAL STYLING NOTES
     ======================================== -->

<!-- 
BUTTON HOVER STATES (for Avalonia PointerOver):
- Primary buttons: Slightly lighter gradient or add shadow
- Outline buttons: Fill with border color
- Ghost buttons: Add subtle background (#1a1f2e)
- List items: Background changes to #1a1f2e

ANIMATIONS TO ADD:
- Pulse animation for loading state
- Smooth transitions on hover (0.2s)
- Fade-in for content changes
- Slide-in for sidebars

RESPONSIVE BREAKPOINTS:
- Collapse sidebars at < 1200px width
- Stack stats vertically at < 800px width
- Reduce padding on mobile

ACCESSIBILITY:
- All interactive elements have cursor: pointer
- Color contrast ratios meet WCAG AA standards
- Focus states should add visible outline

ICONS:
Using emoji for simplicity, but recommend replacing with:
- Fluent Icons (Microsoft)
- Material Design Icons
- Custom SVG icons matching gradient theme
-->

## Details

_To be expanded as the feature develops._

## Related Documentation

- [General Rules](GENERAL_RULES.md)
- [CSV Import Guide](CSV_IMPORT_GUIDE.md)


## Implementation Status

- [ ] Design documented
- [ ] Code implemented
- [ ] Tests written
- [ ] Integration complete

## Notes

_Additional notes and considerations will be added here._





<!-- Last updated: 2025-11-20 19:55 - Reason: Documented the newly implemented multi-step workflow support across suggestions, execution, and destination capturing so UI designers/devs know the expectations. -->

---

## AI UI Suggestion - Source Selection Screen

```html
<!-- ========================================
     SOURCE FOLDER SELECTION SCREEN
     Shown when user clicks "Let's Sort!" button
     ======================================== -->

<!-- This replaces the content of #main-view in the center panel -->

<div id="main-view" style="flex: 1; overflow: auto; padding: 32px;">
  <div style="max-width: 768px; margin: 0 auto;">
    
    <!-- Header -->
    <div style="text-align: center; margin-bottom: 32px;">
      <h2 style="font-size: 30px; font-weight: 700; color: #e2e8f0; margin-bottom: 8px;">Select Source Folder</h2>
      <p style="font-size: 14px; color: #a0aec0; margin: 0;">Choose the messy folder you want to organize</p>
    </div>

    <!-- Drop Zone / Browse Area -->
    <div style="padding: 48px; border: 2px dashed #667eea; border-radius: 16px; background: #1a1f2e; text-align: center; margin-bottom: 24px;">
      <div style="font-size: 64px; margin-bottom: 16px;">📂</div>
      <button id="btn-browse-folder" style="padding: 14px 32px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border: none; color: white; border-radius: 8px; cursor: pointer; font-size: 16px; font-weight: 600; margin-bottom: 12px;">
        Browse Folders
      </button>
      <p style="font-size: 12px; color: #a0aec0; margin: 0;">or drag and drop a folder here</p>
    </div>

    <!-- Quick Access Section -->
    <div>
      <h3 style="font-size: 14px; font-weight: 600; color: #a0aec0; margin-bottom: 12px;">Quick Access</h3>
      <div style="display: flex; flex-direction: column; gap: 8px;">
        
        <!-- Downloads Folder -->
        <button id="quick-downloads" style="display: flex; align-items: center; gap: 12px; padding: 12px; background: #1a1f2e; border: 1px solid #1a1f2e; border-radius: 8px; cursor: pointer; text-align: left; transition: all 0.2s;">
          <span style="font-size: 24px;">⬇️</span>
          <div style="flex: 1;">
            <div style="font-size: 14px; font-weight: 500; color: #e2e8f0;">Downloads</div>
            <div style="font-size: 12px; color: #a0aec0;">C:\Users\YourName\Downloads</div>
          </div>
        </button>

        <!-- Pictures Folder -->
        <button id="quick-pictures" style="display: flex; align-items: center; gap: 12px; padding: 12px; background: #1a1f2e; border: 1px solid #1a1f2e; border-radius: 8px; cursor: pointer; text-align: left; transition: all 0.2s;">
          <span style="font-size: 24px;">🖼️</span>
          <div style="flex: 1;">
            <div style="font-size: 14px; font-weight: 500; color: #e2e8f0;">Pictures</div>
            <div style="font-size: 12px; color: #a0aec0;">C:\Users\YourName\Pictures</div>
          </div>
        </button>

        <!-- Documents Folder -->
        <button id="quick-documents" style="display: flex; align-items: center; gap: 12px; padding: 12px; background: #1a1f2e; border: 1px solid #1a1f2e; border-radius: 8px; cursor: pointer; text-align: left; transition: all 0.2s;">
          <span style="font-size: 24px;">📄</span>
          <div style="flex: 1;">
            <div style="font-size: 14px; font-weight: 500; color: #e2e8f0;">Documents</div>
            <div style="font-size: 12px; color: #a0aec0;">C:\Users\YourName\Documents</div>
          </div>
        </button>

      </div>
    </div>

  </div>
</div>

<!-- ========================================
     INTERACTION BEHAVIOR
     ======================================== -->

<!--
When user clicks "Browse Folders" button:
1. Open native folder picker dialog
2. User selects a folder
3. Show loading/analyzing screen (see next section)

When user clicks a Quick Access button:
1. Auto-select that folder
2. Show loading/analyzing screen

Hover states for Quick Access buttons:
- Background changes to #667eea with 10% opacity
- Border changes to #667eea
- Add subtle scale transform (1.02)

-->

<!-- ========================================
     AVALONIA XAML NOTES
     ======================================== -->

<!--
Key Controls to Use:
- Grid or StackPanel for main layout
- TextBlock for headers and descriptions
- Button with custom template for browse button
- Button with ItemsControl for Quick Access list
- Border for the dashed drop zone
- Use Avalonia's drag-drop APIs for folder drop

Styling Tips:
- Use LinearGradientBrush for the accent gradient
- Create a custom ButtonStyle for the Quick Access items
- Add PointerOver state with color animations
- Use CornerRadius for rounded corners
- FontWeight="SemiBold" for medium weight text

Sample Avalonia Color Resources:
<Color x:Key="MainBackground">#0a0e1a</Color>
<Color x:Key="SecondaryBackground">#0f1419</Color>
<Color x:Key="CardBackground">#1a1f2e</Color>
<Color x:Key="PrimaryText">#e2e8f0</Color>
<Color x:Key="SecondaryText">#a0aec0</Color>
<Color x:Key="MutedText">#718096</Color>
<Color x:Key="AccentStart">#667eea</Color>
<Color x:Key="AccentEnd">#764ba2</Color>

Sample LinearGradientBrush for Accent:
<LinearGradientBrush x:Key="AccentGradient" StartPoint="0%,0%" EndPoint="100%,100%">
  <GradientStop Color="#667eea" Offset="0"/>
  <GradientStop Color="#764ba2" Offset="1"/>
</LinearGradientBrush>
-->

---

## AI UI Suggestion - AI Analyzing / Loading Screen

```html
<!-- ========================================
     AI ANALYZING / LOADING SCREEN
     Shown after folder selection while AI processes
     ======================================== -->

<!-- This replaces the content of #main-view in the center panel -->

<div id="main-view" style="flex: 1; overflow: auto; display: flex; align-items: center; justify-content: center;">
  <div style="text-align: center; max-width: 480px; padding: 32px;">
    
    <!-- Animated Robot Icon -->
    <div style="margin-bottom: 24px;">
      <div style="width: 96px; height: 96px; margin: 0 auto; border-radius: 50%; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); display: flex; align-items: center; justify-content: center;">
        <span style="font-size: 48px;">🤖</span>
      </div>
    </div>
    
    <!-- Status Text -->
    <h2 style="font-size: 24px; font-weight: 700; color: #e2e8f0; margin-bottom: 12px;">AI is Analyzing...</h2>
    <p style="font-size: 14px; color: #a0aec0; margin-bottom: 24px; line-height: 1.5;">Scanning 247 files and creating an intelligent organization structure</p>
    
    <!-- Progress Bar -->
    <div style="width: 100%; height: 8px; background: #1a1f2e; border-radius: 4px; overflow: hidden; margin-bottom: 16px;">
      <div id="progress-bar" style="width: 35%; height: 100%; background: linear-gradient(90deg, #667eea 0%, #764ba2 100%); transition: width 0.5s ease;"></div>
    </div>
    
    <!-- Sub-status Text -->
    <div style="font-size: 12px; color: #718096;">Processing file types and content patterns...</div>
    
  </div>
</div>

<!-- ========================================
     ANIMATION AND PROGRESS LOGIC
     ======================================== -->

<!--
Animation Requirements:

1. PULSING ICON:
   - The robot icon container should have a subtle pulse animation
   - Scale between 1.0 and 1.05
   - Duration: 2 seconds
   - Infinite loop
   - Easing: ease-in-out

2. PROGRESS BAR:
   - Starts at 0% width
   - Smoothly animates to show progress
   - Update width property as analysis progresses
   - Example stages:
     * 0-25%: "Scanning files..."
     * 25-50%: "Analyzing file types..."
     * 50-75%: "Processing content patterns..."
     * 75-100%: "Creating organization structure..."

3. STATUS TEXT UPDATES:
   - Change the sub-status text as progress advances
   - Use fade transitions between text changes

Progress Simulation (if no real backend):
- Start at 0%
- Increment by 10% every 500ms
- When reaches 100%, transition to Suggestions screen

-->

<!-- ========================================
     AVALONIA XAML IMPLEMENTATION NOTES
     ======================================== -->

<!--
Key Controls:
- Grid for main layout with vertical centering
- StackPanel for content arrangement
- Border with Ellipse for circular icon background
- TextBlock for all text elements
- Border for progress bar container
- Border for progress bar fill (animate Width)
- DispatcherTimer or Task for progress updates

Animation in Avalonia:

1. Pulse Animation (in XAML or code):
<Style Selector="Border.PulsingIcon">
  <Style.Animations>
    <Animation Duration="0:0:2" IterationCount="Infinite">
      <KeyFrame Cue="0%">
        <Setter Property="ScaleTransform.ScaleX" Value="1.0"/>
        <Setter Property="ScaleTransform.ScaleY" Value="1.0"/>
      </KeyFrame>
      <KeyFrame Cue="50%">
        <Setter Property="ScaleTransform.ScaleX" Value="1.05"/>
        <Setter Property="ScaleTransform.ScaleY" Value="1.05"/>
      </KeyFrame>
      <KeyFrame Cue="100%">
        <Setter Property="ScaleTransform.ScaleX" Value="1.0"/>
        <Setter Property="ScaleTransform.ScaleY" Value="1.0"/>
      </KeyFrame>
    </Animation>
  </Style.Animations>
</Style>

2. Progress Bar Animation (in code-behind):
// Animate progress bar width
var animation = new DoubleTransition
{
    Duration = TimeSpan.FromMilliseconds(500),
    Property = Border.WidthProperty,
    Easing = new QuadraticEaseInOut()
};

progressBar.Transitions = new Transitions { animation };
progressBar.Width = newProgressValue;

3. Backend Integration:
- Use async/await for actual file scanning
- Update UI on main thread using Dispatcher
- Bind progress to ViewModel property
- Use IProgress<T> for progress reporting

Sample Code-Behind Pattern:
private async Task AnalyzeFolder(string folderPath)
{
    var progress = new Progress<AnalysisProgress>(p => {
        ProgressBarWidth = p.Percentage;
        StatusText = p.Message;
    });
    
    await _aiService.AnalyzeFilesAsync(folderPath, progress);
    
    // Navigate to Suggestions view
    NavigateToSuggestions();
}

-->

<!-- ========================================
     STATUS MESSAGE EXAMPLES
     ======================================== -->

<!--
Progress Stages and Messages:

0-20%: "Scanning folder structure..."
20-35%: "Identifying file types..."
35-50%: "Analyzing file content..."
50-65%: "Detecting patterns and categories..."
65-80%: "Creating organization structure..."
80-95%: "Optimizing folder layout..."
95-100%: "Finalizing suggestions..."

File Count Updates:
"Scanning 247 files and creating an intelligent organization structure"
(Update the number based on actual file count)
-->
```

## ## Multi-Step Execution Plans
- Frontend now expects `file_plans` in the organize response and falls back to legacy `operations` only when the backend cannot supply plans.
- Each plan contains ordered `steps`; the UI hydrates `FileOperationStepViewModel` entries so users can review the sequence per file.
- `AISuggestionsView` surfaces step-aware confirmations (“run N steps”) and richer failure dialogs that list which step failed and why.
- `FileOperationExecutor` understands mkdir/delete/no-op plus step metadata (e.g., `overwrite`) so execution mirrors backend expectations.
- Destination Memory uses the final successful step of each plan to auto-capture destinations, keeping known roots in sync without polling.

