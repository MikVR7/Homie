# Project Overview

Welcome to the Homie project! Homie is your intelligent home file organizer, evolving into a complete OneDrive-like home server. This document provides a quick overview to get you started.

## Infrastructure Overview

Homie is designed to run as a self-hosted OneDrive-like server at your home, providing:
- Personal cloud storage with web interface
- File synchronization across devices
- Media streaming capabilities
- Remote access and sharing

### AWS Integration

While Homie runs primarily on your home server, AWS services may be utilized for:
- **Connection brokering**: AWS services to facilitate secure external connections
- **TURN/STUN services**: For WebRTC connections when direct P2P isn't possible
- **DNS management**: Route53 for dynamic DNS updates
- **CDN services**: CloudFront for optimized content delivery when needed
- **Backup services**: S3 for optional cloud backup integration

**Note**: AWS CLI is available and configured for any service integrations that may enhance the home server experience.

## ✨ AI-Powered File Organization

Homie now features intelligent file organization powered by Google Gemini AI! 

### What Makes It Smart?
- **Content-aware analysis**: Understands file content, not just extensions
- **Existing structure awareness**: Respects your current folder organization
- **Intelligent suggestions**: Proposes new folders when needed
- **Safe preview mode**: Shows what it WOULD do without moving files
- **Confidence scoring**: AI provides reasoning and confidence for each suggestion

### Key Features
🤖 **AI Analysis**: Uses Google Gemini to intelligently categorize files
📊 **Smart Metadata**: Extracts file size, type, and content hints
🎯 **Context Aware**: Understands your existing folder structure
💡 **New Folder Suggestions**: Proposes logical new categories
⚠️ **Preview Only**: Never moves files without explicit user confirmation
🔒 **Privacy Focused**: Only sends metadata to AI, never actual file content

## Quick Start

### For Developers
1. Clone the repository
2. Follow setup instructions in DEVELOPMENT.md
3. Get your Google Gemini API key from https://makersuite.google.com/app/apikey
4. Test the AI organization system:
   ```bash
   cd backend
   python setup_env.py
   # Edit .env file with your API key
   python test_smart_organizer.py
   ```

### For Users
- Web interface coming soon! The backend AI system is ready.
- Currently available as a test script for preview

For more detailed information, check the other documentation files.
