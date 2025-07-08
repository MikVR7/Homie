#!/usr/bin/env python3
"""
Smart File Organizer - AI-powered file analysis and organization suggestions
Uses Google Gemini to intelligently categorize and suggest file placements
"""

import os
import json
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import google.generativeai as genai
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class SmartOrganizer:
    def __init__(self, api_key: str):
        """Initialize the smart organizer with Gemini API key"""
        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel('gemini-1.5-flash')
        
    def analyze_downloads_folder(self, downloads_path: str, sorted_path: str) -> Dict:
        """
        Analyze downloads folder and suggest organization into sorted folder
        
        Args:
            downloads_path: Path to the downloads folder
            sorted_path: Path to the sorted folder
            
        Returns:
            Dictionary with organization suggestions
        """
        
        # Get current file inventory
        downloads_files = self._get_file_inventory(downloads_path)
        sorted_structure = self._get_sorted_structure(sorted_path)
        
        # Prepare context for AI
        context = self._prepare_context(downloads_files, sorted_structure)
        
        # Get AI suggestions
        suggestions = self._get_ai_suggestions(context)
        
        return {
            'downloads_inventory': downloads_files,
            'sorted_structure': sorted_structure,
            'ai_suggestions': suggestions,
            'total_files_to_organize': len(downloads_files)
        }
    
    def _get_file_inventory(self, folder_path: str) -> List[Dict]:
        """Get detailed inventory of files in downloads folder"""
        files = []
        
        for root, dirs, filenames in os.walk(folder_path):
            for filename in filenames:
                file_path = os.path.join(root, filename)
                file_info = self._analyze_file(file_path)
                files.append(file_info)
                
        return files
    
    def _analyze_file(self, file_path: str) -> Dict:
        """Analyze individual file and extract metadata"""
        stat = os.stat(file_path)
        file_info = {
            'name': os.path.basename(file_path),
            'path': file_path,
            'extension': Path(file_path).suffix.lower(),
            'size_mb': round(stat.st_size / (1024*1024), 2),
            'size_category': self._categorize_size(stat.st_size),
            'type_category': self._categorize_by_extension(Path(file_path).suffix.lower())
        }
        
        # Add content hints for better AI analysis
        if file_info['extension'] in ['.txt', '.md', '.json', '.js', '.py', '.html', '.css']:
            file_info['content_hint'] = self._get_text_file_hint(file_path)
            
        return file_info
    
    def _categorize_size(self, size_bytes: int) -> str:
        """Categorize file by size"""
        mb = size_bytes / (1024*1024)
        if mb < 1:
            return "small"
        elif mb < 10:
            return "medium"
        elif mb < 100:
            return "large"
        else:
            return "very_large"
    
    def _categorize_by_extension(self, ext: str) -> str:
        """Basic categorization by file extension"""
        categories = {
            'images': ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.webp', '.ico'],
            'videos': ['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm'],
            'documents': ['.pdf', '.doc', '.docx', '.txt', '.rtf', '.odt', '.cls'],
            'archives': ['.zip', '.rar', '.7z', '.tar', '.gz', '.bz2', '.tgz'],
            'audio': ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.wma'],
            'code': ['.js', '.py', '.html', '.css', '.json', '.xml', '.sql'],
            'software': ['.deb', '.rpm', '.exe', '.msi', '.dmg', '.pkg'],
            'data': ['.csv', '.xlsx', '.json', '.xml', '.db', '.sql'],
            'other': ['.dlc', '.iso']
        }
        
        for category, extensions in categories.items():
            if ext in extensions:
                return category
        return 'unknown'
    
    def _get_text_file_hint(self, file_path: str) -> str:
        """Get content hint from text files"""
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read(200)  # First 200 chars
                return content.strip()[:100] + "..." if len(content) > 100 else content.strip()
        except:
            return "Could not read file content"
    
    def _get_sorted_structure(self, sorted_path: str) -> Dict:
        """Get current structure of sorted folder"""
        structure = {}
        
        if not os.path.exists(sorted_path):
            return structure
            
        for item in os.listdir(sorted_path):
            item_path = os.path.join(sorted_path, item)
            if os.path.isdir(item_path):
                file_count = sum(1 for _ in os.walk(item_path) for f in _[2])
                structure[item] = {
                    'type': 'folder',
                    'file_count': file_count,
                    'subfolders': [d for d in os.listdir(item_path) 
                                 if os.path.isdir(os.path.join(item_path, d))]
                }
        
        return structure
    
    def _prepare_context(self, downloads_files: List[Dict], sorted_structure: Dict) -> str:
        """Prepare context string for AI analysis"""
        context = f"""
I need to organize {len(downloads_files)} files from my Downloads folder into my sorted folder structure.

CURRENT SORTED FOLDER STRUCTURE:
{json.dumps(sorted_structure, indent=2)}

FILES TO ORGANIZE:
"""
        
        for file_info in downloads_files[:20]:  # Limit to first 20 files for context
            context += f"- {file_info['name']} ({file_info['type_category']}, {file_info['size_category']}, {file_info['size_mb']}MB)"
            if 'content_hint' in file_info:
                context += f" - Content: {file_info['content_hint'][:50]}..."
            context += "\n"
            
        if len(downloads_files) > 20:
            context += f"... and {len(downloads_files) - 20} more files\n"
            
        return context
    
    def _get_ai_suggestions(self, context: str) -> Dict:
        """Get AI suggestions for file organization"""
        
        prompt = f"""
{context}

Please analyze these files and suggest how to organize them into the existing sorted folder structure. For each file, suggest:

1. DESTINATION: Which existing folder OR suggest a new folder name
2. REASONING: Why this file belongs there
3. ACTION: 'move_to_existing', 'create_new_folder', or 'skip_for_now'

Respond in this JSON format:
{{
  "general_strategy": "Brief description of your overall organization approach",
  "new_folders_suggested": ["folder1", "folder2"],
  "file_suggestions": [
    {{
      "filename": "example.pdf",
      "destination": "Documents",
      "action": "move_to_existing",
      "reasoning": "PDF document should go to Documents folder",
      "confidence": 0.9
    }}
  ],
  "summary": "X files to organize, Y new folders suggested"
}}

Focus on logical grouping and maintaining a clean, intuitive folder structure.
"""

        try:
            response = self.model.generate_content(prompt)
            # Parse AI response as JSON
            response_text = response.text.strip()
            
            # Clean up the response to extract JSON
            if "```json" in response_text:
                response_text = response_text.split("```json")[1].split("```")[0]
            elif "```" in response_text:
                response_text = response_text.split("```")[1].split("```")[0]
                
            return json.loads(response_text)
            
        except Exception as e:
            # Fallback to rule-based suggestions if AI fails
            return self._fallback_suggestions(context)
    
    def _fallback_suggestions(self, context: str) -> Dict:
        """Fallback rule-based suggestions if AI fails"""
        return {
            "general_strategy": "Rule-based organization by file type",
            "new_folders_suggested": ["Documents", "Images", "Software", "Archives"],
            "file_suggestions": [],
            "summary": "AI analysis failed, using rule-based fallback",
            "error": "Could not connect to AI service"
        }

def demo_organization_analysis(downloads_path: str, sorted_path: str, api_key: str):
    """Demo function to show what the organizer would suggest"""
    
    print("🤖 Analyzing files with AI-powered organization logic...")
    print("=" * 60)
    
    organizer = SmartOrganizer(api_key)
    analysis = organizer.analyze_downloads_folder(downloads_path, sorted_path)
    
    print(f"📁 Found {analysis['total_files_to_organize']} files to organize")
    print(f"📂 Current sorted structure: {list(analysis['sorted_structure'].keys())}")
    print()
    
    suggestions = analysis['ai_suggestions']
    
    print("🧠 AI SUGGESTIONS:")
    print("-" * 40)
    print(f"Strategy: {suggestions.get('general_strategy', 'No strategy provided')}")
    print()
    
    if 'new_folders_suggested' in suggestions:
        print(f"🆕 New folders to create: {suggestions['new_folders_suggested']}")
        print()
    
    print("📋 FILE ORGANIZATION PLAN:")
    print("-" * 40)
    
    for suggestion in suggestions.get('file_suggestions', [])[:10]:  # Show first 10
        action_emoji = {"move_to_existing": "➡️", "create_new_folder": "🆕", "skip_for_now": "⏭️"}
        emoji = action_emoji.get(suggestion.get('action', 'skip_for_now'), "❓")
        
        print(f"{emoji} {suggestion.get('filename', 'Unknown file')}")
        print(f"   → Destination: {suggestion.get('destination', 'Unknown')}")
        print(f"   → Reason: {suggestion.get('reasoning', 'No reason provided')}")
        print(f"   → Confidence: {suggestion.get('confidence', 0.5)*100:.0f}%")
        print()
    
    if len(suggestions.get('file_suggestions', [])) > 10:
        remaining = len(suggestions['file_suggestions']) - 10
        print(f"... and {remaining} more file suggestions")
    
    print("\n" + "=" * 60)
    print("⚠️  NOTE: This is a PREVIEW only - no files were moved!")
    
    return analysis

if __name__ == "__main__":
    # This would be called from the API with actual paths and API key
    print("Smart Organizer module loaded. Use via API endpoint.")
