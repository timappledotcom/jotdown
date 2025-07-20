# jotDown v0.1.3 Release Notes

## 🎉 New Features

### 📋 Tag Support
- **Hash-based tags**: Add tags to notes using `#tagname` syntax in note content
- **Tag display**: Tags are visually displayed in both CLI and GUI with styled badges
- **Tag search**: Search notes by specific tags using `jd search --tag tagname`
- **Tag listing**: List all available tags with usage counts using `jd tags`

### 🔧 Enhanced CLI
- **Improved help system**: Comprehensive help with examples and feature descriptions
- **Better command documentation**: Clear usage examples and feature explanations
- **Enhanced search**: Support for both content search and tag-based filtering
- **Tag management**: New `tags` command to list all available tags

### 🎨 Visual Improvements
- **New pen icon**: Updated app icon from pencil to modern fountain pen design
- **Tag badges**: Attractive tag display in GUI note cards with theme-appropriate colors
- **Better visual hierarchy**: Improved note display with tag information

### 🔄 Real-time Updates
- **Auto-refresh GUI**: Desktop app automatically detects and displays changes made via CLI
- **File monitoring**: Background file system monitoring for seamless sync
- **Manual refresh**: Optional refresh button for immediate updates

## 🛠 Technical Improvements

### Data Model Enhancements
- Added computed `tags` property to Note model for automatic tag extraction
- Added `hasTag()` method for efficient tag-based filtering
- Preserved backward compatibility with existing note format

### CLI Enhancements
- Updated help system with comprehensive examples
- Added tag-based search functionality
- Enhanced list and view commands to display tags
- Version bump to 0.1.3

### GUI Enhancements
- Added tag display in note cards with visual badges
- Implemented auto-refresh functionality with Timer-based monitoring
- Added app lifecycle management for focus-based updates
- Enhanced note preview with tag information

### Icon System
- Redesigned SVG icon with modern fountain pen theme
- Generated all PNG sizes (16, 32, 48, 64, 128, 256px)
- Maintained consistent branding across all platforms

## 🚀 Usage Examples

### Tag Management
```bash
# Add a note with tags
jd add -t "Project Meeting" -c "Discussed #planning and #development tasks"

# List all tags
jd tags

# Search by tag
jd search --tag planning

# View notes with tag display
jd list  # Shows tags in note previews
```

### Real-time Sync
- Add notes via CLI and see them immediately appear in open GUI
- GUI auto-refreshes every 3 seconds when app is in focus
- Manual refresh button available in GUI toolbar

## 🔧 Developer Notes

### Dependencies
- No new external dependencies added
- Used existing Flutter/Dart ecosystem
- Maintained compatibility with SharedPreferences format

### Performance
- Efficient tag extraction using regex patterns
- Minimal overhead for tag processing
- Optimized file monitoring for battery efficiency

## 📦 Installation

Same installation methods as previous versions:
- AppImage for universal Linux compatibility
- DEB package for Debian/Ubuntu systems
- TAR.XZ archive for manual installation
- CLI setup script for command-line access

## 🐛 Bug Fixes
- Improved error handling in tag processing
- Enhanced file monitoring robustness
- Better handling of edge cases in tag extraction

## 🔄 Migration Notes
- Existing notes are fully compatible
- Tags are automatically extracted from existing note content
- No data migration required

---

**Full Changelog**: [v0.1.2...v0.1.3](https://github.com/timappledotcom/jotdown/compare/v0.1.2...v0.1.3)

**Download**: [Release v0.1.3](https://github.com/timappledotcom/jotdown/releases/tag/v0.1.3)
