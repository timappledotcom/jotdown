# 🎉 jotDown v0.2.0 Release

## Major Features

### 🏷️ Hierarchical Tag Sidebar
- **Advanced Filtering**: Progressive tag refinement system
- **Visual Counts**: See how many notes match each tag
- **Breadcrumb Navigation**: Easy back/clear navigation
- **Toggle Visibility**: Show/hide sidebar for focused writing

### 🎨 Ubuntu Native Design
- **Yaru Theme Integration**: Full Ubuntu theming support
- **Ubuntu Orange**: Signature #E95420 color scheme
- **Native Patterns**: Ubuntu design guidelines compliance
- **Enhanced Accessibility**: Better contrast and spacing

### 📁 Documents Folder Storage
- **Easy Access**: Store notes in ~/Documents/jotdown/
- **Migration Support**: Seamless location switching
- **File System Integration**: Better backup workflows
- **Cross-platform**: Works on Linux, macOS, Windows

## Package Downloads

| Package Type | Size | Description |
|--------------|------|-------------|
| **DEB** | 16MB | For Debian/Ubuntu systems |
| **RPM** | 12MB | For Red Hat/Fedora/SUSE systems |
| **TAR.XZ** | 14MB | Portable archive for any Linux |

## Installation

### DEB Package (Debian/Ubuntu)
```bash
wget https://github.com/timappledotcom/jotdown/releases/download/v0.2.0/jotdown-v0.2.0-amd64.deb
sudo dpkg -i jotdown-v0.2.0-amd64.deb
```

### RPM Package (Red Hat/Fedora/SUSE)
```bash
wget https://github.com/timappledotcom/jotdown/releases/download/v0.2.0/jotdown-v0.2.0-x86_64.rpm
sudo rpm -i jotdown-v0.2.0-x86_64.rpm
```

### Portable Archive (Universal)
```bash
wget https://github.com/timappledotcom/jotdown/releases/download/v0.2.0/jotdown-v0.2.0-linux-x64.tar.xz
tar -xf jotdown-v0.2.0-linux-x64.tar.xz
cd jotdown-v0.2.0-linux-x64
sudo ./install.sh
```

## What's New

### Enhanced Tag Management
- Click tags in the sidebar to progressively filter notes
- See tag counts to understand your note organization
- Use "Back" to remove the last selected tag
- "Clear All" to reset all filters
- Combine with text search for precise results

### Improved User Experience
- Better empty state messages with clear actions
- Enhanced help documentation with new features
- Responsive sidebar that adapts to your workflow
- Smoother animations and transitions

### Ubuntu Integration
- Native Ubuntu look and feel
- Proper desktop integration
- System theme compatibility
- Accessibility improvements

## Technical Improvements
- Refactored tag filtering logic for better performance
- Enhanced state management for complex UI interactions
- Improved file system integration
- Better error handling and user feedback

## Upgrade Notes
- Settings and notes are automatically preserved
- New storage options available in Settings
- Tag sidebar is enabled by default (can be toggled)
- All existing CLI commands continue to work

---

**Full Changelog**: https://github.com/timappledotcom/jotdown/compare/v0.1.6...v0.2.0