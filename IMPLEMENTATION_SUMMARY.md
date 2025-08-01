# Documents Folder Storage Implementation Summary

## What I've Implemented

I've successfully added support for storing JotDown notes in a dedicated `jotdown` folder within your Documents directory. Here's what was implemented:

### 1. Updated AppSettings Model
- Added `storageLocation` field with options: 'shared_preferences', 'documents', 'home', 'custom'
- Added `useCustomLocation` and `customPath` fields for custom storage
- Added `encryptionEnabled` and `passwordHash` fields for security
- Updated the model to support all storage location features

### 2. Enhanced SettingsService
- Added `getAvailableStorageLocations()` method to detect available storage options
- Added `getStorageLocationDisplayName()` for user-friendly names
- Added `getStoragePath()` to get the actual file path for each storage type
- Full cross-platform support (Linux, macOS, Windows)

### 3. Updated FlatFileService
- Modified to accept `AppSettings` parameter for location-aware storage
- Added `_getDataDirectory()` method that respects storage location settings
- Updated all methods (`loadNotes`, `saveNote`, `deleteNote`) to work with different locations
- Added `getStoragePathForSettings()` for path display

### 4. Fixed NotesService Integration
- Corrected folder naming consistency (using "jotdown" lowercase)
- Ensured proper integration with the settings system
- Maintained encryption support across all storage locations

## Storage Locations Available

1. **App Data** (default): `~/.local/share/jotdown/`
2. **Documents Folder**: `~/Documents/jotdown/` ← **NEW FEATURE**
3. **Home Directory**: `~/jotdown/`
4. **Custom Location**: User-specified path + `/jotdown/`

## How to Use

### For Users:
1. Open JotDown app
2. Go to Settings (gear icon)
3. Under "Storage Location", select "Documents Folder"
4. Click "Save"
5. The app will offer to migrate existing notes to the new location

### For Developers:
The implementation is backward compatible. Existing code will continue to work, and the new storage options are available through the settings system.

## File Structure in Documents Folder

When using Documents folder storage, files are organized as:

```
~/Documents/jotdown/
├── notes.json          # Main notes database (NotesService)
├── notes.json.salt     # Encryption salt (if encryption enabled)
├── password.salt       # Password salt (if encryption enabled)
├── index.json          # Note index (FlatFileService)
├── note-id-1.md        # Individual note files (FlatFileService)
├── note-id-2.md
└── ...
```

## Benefits

1. **Easy Access**: Users can browse notes directly from file manager
2. **Backup Integration**: Notes are included in Documents folder backups
3. **Portability**: Easy to copy notes between devices
4. **Transparency**: Users can see exactly where notes are stored
5. **Tool Integration**: Can be used with other markdown editors if needed

## Testing

To test the implementation:

1. **Manual Testing**:
   - Run the JotDown app
   - Go to Settings → Storage Location
   - Select "Documents Folder"
   - Create/edit some notes
   - Check `~/Documents/jotdown/` folder for files

2. **Migration Testing**:
   - Create notes with default storage
   - Change to Documents folder storage
   - Verify migration dialog appears
   - Confirm notes are moved correctly

## Technical Details

- **Thread Safety**: All file operations are async and properly handled
- **Error Handling**: Graceful fallbacks if Documents folder is not accessible
- **Permissions**: Uses standard user document folder permissions
- **Encryption**: Full encryption support maintained for Documents storage
- **Cross-Platform**: Works on Linux, macOS, and Windows

## Files Modified

1. `lib/models/app_settings.dart` - Added storage location fields
2. `lib/services/settings_service.dart` - Added location management methods
3. `lib/services/flat_file_service.dart` - Added settings-aware storage
4. `lib/services/notes_service.dart` - Fixed folder naming consistency

## Backward Compatibility

- Existing installations continue to work without changes
- Default storage location remains unchanged
- Migration is optional and user-controlled
- All existing features work with new storage locations

The implementation is complete and ready for use! Users can now easily store their JotDown notes in their Documents folder for better accessibility and backup integration.