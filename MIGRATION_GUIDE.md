# Migration Guide: JSON to Flat File Storage

## Overview

jotDown now supports storing notes as individual Markdown files instead of a single JSON file. This guide explains how to migrate your existing notes and the benefits of the new storage format.

## Quick Migration Steps

### 1. Open jotDown Settings
- Launch jotDown desktop app
- Click the gear icon (⚙️) in the top-right corner

### 2. Change Storage Location
- In the Settings screen, find "Storage Location"
- Select one of the file-based options:
  - **Documents Folder**: `~/Documents/jotdown/`
  - **Home Directory**: `~/jotdown/`
  - **Custom Location**: Choose your own path

### 3. Migrate Your Notes
- Click "Save" to apply the new storage location
- jotDown will offer to migrate your existing notes
- Click "Yes" to move all notes to the new location
- Your notes will be converted to individual `.md` files

### 4. Verify Migration
- Check the new storage folder
- You should see:
  - `index.json` (metadata file)
  - Individual `.md` files for each note
  - `encryption.salt` (if encryption was enabled)

## What Changes

### Before (JSON Storage)
```
~/.local/share/jotdown/
└── notes.json          # All notes in one file
```

### After (Flat File Storage)
```
~/Documents/jotdown/    # or your chosen location
├── index.json          # Metadata index
├── 1707123456789.md    # Individual note files
├── 1707123457890.md
├── 1707123458901.md
└── encryption.salt     # If encryption enabled
```

## Benefits of Migration

### 🔧 **Better Tool Integration**
```bash
# Edit notes with your favorite editor
code ~/Documents/jotdown/1707123456789.md
vim ~/Documents/jotdown/1707123456789.md

# Search across all notes
grep -r "important" ~/Documents/jotdown/*.md

# Convert notes to other formats
pandoc ~/Documents/jotdown/1707123456789.md -o note.html
```

### 💾 **Improved Backup**
- Backup individual files or entire folder
- Use with version control systems (git)
- Sync with cloud storage services
- Selective backup of specific notes

### 🔍 **Enhanced Search**
- Use system search tools
- Full-text search with external applications
- Better performance for large note collections

## CLI Usage After Migration

The CLI automatically detects your storage location:

```bash
# All commands work the same way
jd list                           # Shows notes from flat files
jd add -t "New Note" -c "Content" # Creates new .md file
jd view --id 1707123456789        # Reads from .md file
jd search -q "keyword"            # Searches across .md files
```

## Rollback (If Needed)

If you want to return to JSON storage:

1. **Change Storage Back**:
   - Go to Settings → Storage Location
   - Select "App Data" (SharedPreferences)
   - Save settings

2. **Migrate Notes Back**:
   - jotDown will offer to migrate notes back to JSON format
   - Your flat files will remain as backup

## Troubleshooting

### Migration Issues

**Problem**: Migration fails with permission error
**Solution**: Ensure you have write permissions to the target directory

**Problem**: Some notes are missing after migration
**Solution**: Check the original location - notes are copied, not moved

**Problem**: Encrypted notes won't decrypt
**Solution**: Verify your password and ensure salt files are present

### File Access Issues

**Problem**: Can't find note files
**Solution**: Check Settings → Storage Location for the current path

**Problem**: Files appear corrupted
**Solution**: If encryption is enabled, files will look encrypted - this is normal

### Performance Issues

**Problem**: App is slower after migration
**Solution**: Large note collections may take time to index - this improves over time

## Advanced Usage

### Manual File Management

You can manually manage note files:

```bash
# Create a new note file
echo "# My New Note\n\nContent here" > ~/Documents/jotdown/mynote.md

# Copy notes between locations
cp ~/Documents/jotdown/*.md ~/Backup/notes/

# Organize notes (future feature)
mkdir ~/Documents/jotdown/projects
mv ~/Documents/jotdown/project*.md ~/Documents/jotdown/projects/
```

### Integration with Other Tools

```bash
# Static site generation
hugo new site my-notes
cp ~/Documents/jotdown/*.md my-notes/content/

# Documentation systems
mkdocs new my-docs
cp ~/Documents/jotdown/*.md my-docs/docs/

# Note-taking workflows
ln -s ~/Documents/jotdown ~/Obsidian/jotdown-notes
```

## Best Practices

### File Organization
- Keep the `index.json` file intact
- Don't rename `.md` files manually (use jotDown interface)
- Backup the entire folder, not individual files

### External Editing
- Close jotDown before editing files externally
- Restart jotDown after external changes
- Use UTF-8 encoding for compatibility

### Backup Strategy
```bash
# Daily backup script
#!/bin/bash
DATE=$(date +%Y%m%d)
tar -czf "jotdown-backup-$DATE.tar.gz" ~/Documents/jotdown/
```

## Support

If you encounter issues during migration:

1. **Check the logs**: Look for error messages in the terminal
2. **Verify permissions**: Ensure write access to target directory
3. **Test with new notes**: Create a test note to verify functionality
4. **Report issues**: Use GitHub issues for bug reports

For more information, see [FLAT_FILE_STORAGE.md](FLAT_FILE_STORAGE.md) for technical details.