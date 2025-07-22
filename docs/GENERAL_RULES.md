# General Development Rules

This document contains general rules and guidelines that apply across all projects and should be followed by AI assistants and developers.

## 📅 Date Management

### For AI Assistants
**ALWAYS ASK FOR CURRENT DATE**: Before assuming any date in documentation updates, always ask the user what the current date is. Do not assume dates based on training data or previous context.

### Date Format
- Use ISO format: YYYY-MM-DD (e.g., 2025-07-22)
- Always include dates for significant updates and completions
- Update historical records with correct dates

## 💬 Git Commit Message Format

### Required Format
```
TopicOfJob: Detailed description of what we have done in one sentence
```

### Examples
```bash
# Good Examples:
git commit -m "ModuleLaunchScripts: Created standalone startup scripts for File Organizer and Financial Manager with conditional back button removal"
git commit -m "Documentation: Updated all docs with correct dates and added AI assistant guidelines"
git commit -m "BugFix: Resolved Flutter Linux rendering issues by implementing web-based development workflow"
git commit -m "DatabaseMigration: Migrated user accounts from JSON to SQLite with backward compatibility"

# Bad Examples (avoid these):
git commit -m "Fixed stuff"
git commit -m "Updates"
git commit -m "WIP"
git commit -m "Module scripts"
```

### Topic Guidelines
- **Use PascalCase**: ModuleLaunchScripts, DatabaseMigration, BugFix
- **Be Specific**: Describe the main area of work
- **Keep Topic Short**: 1-3 words maximum
- **Common Topics**: Documentation, BugFix, Feature, Refactor, Setup, Migration, Testing, UI, API

## 📝 Documentation Guidelines

### Structure
- Always include clear section headers
- Use consistent formatting across all documentation
- Keep examples concise but complete
- Update related documentation when making changes

### AI Assistant Notes
- Include specific guidelines for AI assistants in relevant documents
- Avoid duplicate information across multiple files
- Reference other documents when appropriate instead of duplicating content

## 🔧 Development Practices

### Code Changes
- Test changes before committing
- Update documentation alongside code changes
- Follow established project architecture patterns
- Clean up temporary files and unused code

### File Organization
- Use descriptive file names
- Group related files in appropriate directories
- Keep project root clean with only essential files
- Document any new file structures

## 🚀 Project-Specific Applications

### For Flutter Projects
- Prefer web development on Linux due to desktop rendering issues
- Use descriptive script names (e.g., `start_module_web.sh`)
- Include usage examples in documentation

### For Backend APIs
- Include clear API endpoint documentation
- Maintain consistent error handling patterns
- Document configuration requirements

### For Database Changes
- Always include migration scripts
- Maintain backward compatibility when possible
- Document schema changes clearly

---

**Note**: This document should be referenced in project-specific documentation but content should not be duplicated. Link to this document when referencing general rules. 