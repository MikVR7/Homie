# General Development Rules

This document contains general rules and guidelines that apply across all projects and should be followed by AI assistants and developers.

## Git Workflow

## 💬 Git Workflow

### Commit and Push Process
**Always complete the full git workflow:**
1. `git add -A` (stage all changes)
2. `git commit -m "TopicOfJob: Description"`
3. `git push` (push to remote repository)

### Required Commit Message Format
```
TopicOfJob: Detailed description of what we have done in one sentence
```

**CRITICAL RULES FOR AI ASSISTANTS**: 
- **TopicOfJob**: Use PascalCase (e.g., BackendConnectivity, FileOrganizer, DatabaseMigration)
- **Start with capital letter**: Always capitalize the first letter
- **NO PREFIXES**: ABSOLUTELY NO conventional commit prefixes like "feat:", "fix:", "docs:", etc.
- **ONE SENTENCE ONLY**: Description must be a single sentence, NO multi-paragraph commit messages
- **NO BULLET POINTS**: Do not include lists or detailed breakdowns in commit messages
- **Be descriptive**: Explain what was accomplished in clear terms

### Examples
```bash
# Good Examples:
git commit -m "ModuleLaunchScripts: Created standalone startup scripts for File Organizer and Financial Manager with conditional back button removal"
git commit -m "Documentation: Updated all docs with correct dates and added AI assistant guidelines"
git commit -m "BugFix: Resolved Flutter Linux rendering issues by implementing web-based development workflow"
git commit -m "DatabaseMigration: Migrated user accounts from JSON to SQLite with backward compatibility"
git commit -m "Phase5Integration: Connected frontend to backend content analysis with AdvancedAIService implementation"

# Bad Examples (NEVER do these):
git commit -m "Fixed stuff"
git commit -m "Updates"
git commit -m "WIP"
git commit -m "Module scripts"
git commit -m "feat: implement backend connectivity"  # NO conventional commit prefixes
git commit -m "fix: resolve error handling"          # NO conventional commit prefixes
git commit -m "feat(Phase 5): Add data models\n\nNew Models:\n- DuplicateDetection\n- ContentMetadata"  # NO multi-paragraph messages
```

### Topic Guidelines
- **Use PascalCase**: ModuleLaunchScripts, DatabaseMigration, BugFix
- **Be Specific**: Describe the main area of work
- **Keep Topic Short**: 1-3 words maximum
- **Common Topics**: Documentation, BugFix, Feature, Refactor, Setup, Migration, Testing, UI, API

## Rule 0: No Architectural Shortcuts


### Rule 0: No Architectural Shortcuts
The most important principle is to maintain the project's decoupled, event-driven architecture.
- **THINK FIRST:** Before writing any code, think through the full flow of information.
- **Identify Responsibilities:** Who is responsible for firing an event? Who is responsible for listening? Who is responsible for updating the UI? These are almost always different classes.
- **No Shortcuts:** Never put business logic in view components. Never make a component listen for the response to an event it fired. Adhere strictly to the single responsibility principle. Violating this is a critical failure.


## 📅 Date Management

### For AI Assistants
**ALWAYS ASK FOR CURRENT DATE**: Before assuming any date in documentation updates, always ask the user what the current date is. Do not assume dates based on training data or previous context.

### Date Format
- Use ISO format: YYYY-MM-DD (e.g., 2025-07-22)
- Always include dates for significant updates and completions
- Update historical records with correct dates

## 💬 Git Workflow

### Commit and Push Process
**Always complete the full git workflow:**
1. `git add -A` (stage all changes)
2. `git commit -m "TopicOfJob: Description"`
3. `git push` (push to remote repository)

### Required Commit Message Format
```
TopicOfJob: Detailed description of what we have done in one sentence
```

**IMPORTANT**: 
- **TopicOfJob**: Use PascalCase (e.g., BackendConnectivity, FileOrganizer, DatabaseMigration)
- **Start with capital letter**: Always capitalize the first letter
- **No prefixes**: Do NOT use conventional commit prefixes like "feat:", "fix:", etc.
- **Be descriptive**: Explain what was accomplished in clear terms

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
git commit -m "feat: implement backend connectivity"  # NO conventional commit prefixes
git commit -m "fix: resolve error handling"          # NO conventional commit prefixes
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
- Always complete full git workflow: add → commit → push

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

<!-- Last updated: 2025-10-12 22:19 - Reason: User feedback: AI was writing verbose multi-paragraph commit messages instead of following the one-sentence format with NO conventional commit prefixes -->
