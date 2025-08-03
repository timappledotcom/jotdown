# Flat File Storage Implementation

## Overview

jotDown now stores notes as individual Markdown files instead of a single JSON file. This makes notes accessible to other applications and provides better file system integration.

## File Structure

When using file-based storage (documents, home, or custom locations), notes are stored as:

```
~/Documents/jotdown/           # or your chosen location
├── index.json                 # Metadata index with titles, dates, etc.
├── 1707123456789.md          # Individual note files
├── 1707123457890.md          # Named with note ID + .md extension
├── 1707123458901.md
└── encryption.salt           # Salt file (if encryption enabled)
```

## Benefits

### 🔧 **Tool Compatibility**
- Open notes in any text editor (VS Code, Vim, Nano, etc.)
- Use with other Markdown tools and processors
- Compatible with static site generators
- Works with Markdown preview tools

### 💾 **Better Backup & Sync**
- Easy to backup individual files
- Git version control support
- Dropbox/Google Drive friendly
- Selective sync capabilities

### 🔍 **Enhanced Search**
- Use system search tools (grep, ripgrep, etc.)
- Full-text search with external tools
- Better indexing by file systems
- Faster search for large note collections

### 📁 **File System Integration**
- Browse notes in file manager
- Organize with folders (future feature)
- Standard file operations (copy, move, etc.)
- Better integration with system workflows

## Implementation Details

### Storage Modes

1. **SharedPreferences** (default): Still uses JSON format for compatibility
2. **File-based storage**: Uses individual .md files with index.json

### Index File Format

The `index.json` file contains metadata for quick loading:

```json
[
  {
    "id": "1707123456789",
    "title": "My Note Title",
    "filename": "1707123456789.md",
    "createdAt": "2025-02-08T10:30:00.000Z",
    "updatedAt": "2025-02-08T15:45:00.000Z"
  }
]
```

### Note File Format

Individual `.md` files contain pure Markdown content:

```markdown
# My Note Title

This is the note content in **Markdown** format.

## Features
- Bullet points work
- *Italic* and **bold** text
- `Code snippets`
- Links and images

#tags #work #project
```

### Encryption Support

When encryption is enabled:
- Index file is encrypted
- Individual note files are encrypted
- Salt stored in `encryption.salt` file
- Files appear as encrypted text, not readable Markdown

## Migration

### Automatic Migration
- Existing JSON-based notes are preserved
- New notes use flat file format
- No data loss during transition

### Manual Migration
Users can change storage location in Settings to migrate all notes to flat file format.

## CLI Integration

The CLI (`jd` command) fully supports flat file storage:

```bash
# All CLI commands work with flat files
jd list                    # Lists notes from index
jd add -t "Title" -c "Content"  # Creates new .md file
jd view --id 123456789     # Reads from .md file
jd edit --id 123456789 --editor  # Edits .md file directly
```

## Development Notes

### Services Updated
- `NotesService`: Main service updated for flat file support
- `CLINotesService`: CLI service updated for consistency
- `FlatFileService`: Existing service integrated into main flow

### Backward Compatibility
- SharedPreferences storage still uses JSON format
- Existing installations continue to work
- Migration is optional and user-controlled

### Performance
- Faster loading for large note collections
- Better memory usage (load notes on demand)
- Improved search performance with external tools

## Usage Examples

### Creating Notes
```dart
final note = Note(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  title: 'My Note',
  content: '# Hello World\n\nThis is **markdown** content!',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await notesService.saveNote(note, existingNotes, settings);
// Creates: ~/Documents/jotdown/1707123456789.md
```

### External Tool Integration
```bash
# Search notes with grep
grep -r "project" ~/Documents/jotdown/*.md

# Edit with your favorite editor
code ~/Documents/jotdown/1707123456789.md

# Convert to HTML with pandoc
pandoc ~/Documents/jotdown/1707123456789.md -o note.html

# Count words in all notes
wc -w ~/Documents/jotdown/*.md
```

## Testing

Run the demo script to see flat file storage in action:

```bash
dart example_flat_files.dart
```

This creates sample notes and shows the file structure.

## Future Enhancements

- **Folder Organization**: Organize notes in subdirectories
- **Metadata Headers**: YAML frontmatter support
- **Asset Management**: Handle images and attachments
- **Export Formats**: Direct export to various formats
- **Git Integration**: Built-in version control features

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure write access to chosen directory
2. **Encryption Issues**: Verify password and salt files exist
3. **Index Corruption**: Delete index.json to rebuild from .md files
4. **File Conflicts**: Avoid editing files while app is running

### Recovery

If the index becomes corrupted, jotDown can rebuild it from existing .md files by scanning the directory and reading file metadata.