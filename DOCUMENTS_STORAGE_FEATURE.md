# Documents Folder Storage Feature

## Overview

JotDown now supports storing your notes in a dedicated `jotdown` folder within your Documents directory. This provides easy access to your notes from the file system while maintaining the app's functionality.

## How to Enable

1. **Open JotDown app**
2. **Go to Settings** (gear icon or menu)
3. **Select Storage Location**
4. **Choose "Documents Folder"**
5. **Save settings**

## Storage Locations

The app now supports multiple storage locations:

- **App Data** (default): Stored securely in app data, no file access needed
- **Documents Folder**: `~/Documents/jotdown/` - Easy access from file manager
- **Home Directory**: `~/jotdown/` - Stored in your home folder
- **Custom Location**: Choose any folder you prefer

## File Structure

When using Documents folder storage, your notes are stored as:

```
~/Documents/jotdown/
├── notes.json          # Main notes database
├── notes.json.salt     # Encryption salt (if encryption enabled)
└── password.salt       # Password salt (if encryption enabled)
```

## Features

### ✅ What Works
- **Full note management**: Create, edit, delete notes
- **Encryption support**: Notes can be encrypted even in Documents folder
- **Migration**: Seamlessly move notes between storage locations
- **Backup/Export**: All backup features work with Documents storage
- **Cross-platform**: Works on Linux, macOS, and Windows

### 🔄 Migration
When you change storage locations, the app will offer to migrate your existing notes to the new location automatically.

### 🔒 Security
- Encryption works the same way in Documents folder
- Salt files are stored alongside notes for security
- File permissions are handled by the operating system

## Benefits of Documents Folder Storage

1. **Easy Access**: Browse your notes directly from file manager
2. **Backup Integration**: Include in your regular Documents backup
3. **Portability**: Easy to copy notes to other devices
4. **Transparency**: See exactly where your notes are stored
5. **Integration**: Use with other markdown tools if needed

## Testing

You can test the Documents folder feature by running:

```bash
dart test_documents_storage.dart
```

This will:
- Create a test note in Documents/jotdown/
- Verify the storage works correctly
- Show you the exact file path

## Technical Details

- **File Format**: JSON for structured data
- **Folder Name**: `jotdown` (lowercase)
- **Permissions**: Uses standard user document permissions
- **Encryption**: AES encryption with salt files when enabled
- **Indexing**: Maintains compatibility with existing note indexing

## Troubleshooting

### Permission Issues
If you get permission errors:
1. Check that you have write access to Documents folder
2. Try selecting a custom location you control
3. Restart the app after changing permissions

### Migration Issues
If migration fails:
1. Notes remain in the old location as backup
2. You can manually copy the files if needed
3. Check the app logs for specific error messages

### File Access
The notes are stored in standard JSON format, so you can:
- View them in any text editor
- Back them up manually
- Process them with scripts if needed

**Note**: Direct file editing is not recommended as it may cause sync issues with the app.