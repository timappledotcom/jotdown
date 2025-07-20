# JotDown v0.1.5 Release Notes

## 🔧 **Bug Fixes & Improvements**

### ✅ **Help Dialog Fixed**
- **Fixed**: Help button (❓) now properly displays in all installation methods
- **Enhanced**: Interactive help dialog with comprehensive feature documentation
- **Improved**: Visual organization with emojis, sections, and pro tips
- **Complete**: Coverage of all features including tags, CLI, searching, and settings

### 🔄 **Real-time Sync Enhancements**
- **Faster Sync**: Reduced check interval from 3s to 1s for immediate responsiveness
- **Dual Detection**: File modification timestamps + note count changes for reliability
- **Better Lifecycle**: Enhanced app focus/unfocus sync behavior
- **Robust Error Handling**: Improved exception management and debug logging
- **Seamless Integration**: CLI and GUI now sync in real-time without restart

### 🛠️ **Installation Improvements**
- **Fixed GUI Launch**: Desktop file uses correct executable path
- **Enhanced postinst**: Automatic symlink creation for both GUI and CLI
- **Clean Uninstall**: Added prerm script for complete cleanup
- **Better Icons**: Proper system integration with pixmaps

## 📦 **Fresh Package Build**

This is a complete rebuild to ensure all recent improvements are properly packaged:

- **DEB Package** (`jotdown-v0.1.5-amd64.deb`): For Ubuntu/Debian systems
- **TAR.XZ Archive** (`jotdown-v0.1.5-linux-x64.tar.xz`): Universal Linux archive
- **AppImage** (`jotdown-v0.1.5-linux-x86_64.AppImage`): Portable Linux application

## 🚀 **Installation**

### New Installation

**DEB Package (Ubuntu/Debian)**
```bash
wget https://github.com/timappledotcom/jotdown/releases/download/v0.1.5/jotdown-v0.1.5-amd64.deb
sudo dpkg -i jotdown-v0.1.5-amd64.deb
```

**TAR.XZ Archive (Universal Linux)**
```bash
wget https://github.com/timappledotcom/jotdown/releases/download/v0.1.5/jotdown-v0.1.5-linux-x64.tar.xz
tar -xJf jotdown-v0.1.5-linux-x64.tar.xz
cd jotdown-v0.1.5
./install.sh
```

**AppImage (Portable)**
```bash
wget https://github.com/timappledotcom/jotdown/releases/download/v0.1.5/jotdown-v0.1.5-linux-x86_64.AppImage
chmod +x jotdown-v0.1.5-linux-x86_64.AppImage
./jotdown-v0.1.5-linux-x86_64.AppImage
```

### Upgrading from Previous Versions

**If you have v0.1.4 or earlier installed via DEB:**
```bash
# Download and install new version
wget https://github.com/timappledotcom/jotdown/releases/download/v0.1.5/jotdown-v0.1.5-amd64.deb
sudo dpkg -i jotdown-v0.1.5-amd64.deb
```

Your notes, settings, and data will be preserved.

## ✨ **What's Working Now**

### 📖 **Help System**
- Click the ❓ button in the app bar (top-right corner)
- Comprehensive help covering all features
- Examples for tag usage and CLI commands
- Beginner-friendly explanations

### 🔄 **Real-time Sync**
- Add notes from CLI: `jd add -t "Test" -c "Content with #tags"`
- See them appear in open GUI within 1-2 seconds
- No need to restart or manually refresh
- Works bidirectionally (GUI changes sync to CLI)

### 🏷️ **Tag Features**
- Use `#tagname` anywhere in note content
- Tags appear as colored badges
- Filter notes using dropdown menu
- Search by tag: `jd search --tag tagname`

## 🐛 **Issues Resolved**

- ✅ Help button not appearing in installed packages
- ✅ Notes added from CLI not syncing to open GUI
- ✅ GUI not launching from desktop file/menu
- ✅ Installation symlinks not created properly
- ✅ Package version inconsistencies

## 📋 **Version Consistency**

All components now consistently use v0.1.5:
- Flutter GUI application
- Dart CLI tool
- Package metadata
- Installation scripts
- Desktop integration files

## 🔄 **Migration Notes**

- Existing notes and settings are fully preserved
- No data migration required
- Tag extraction works on existing notes automatically
- Settings and preferences maintained

---

**Full Changelog**: https://github.com/timappledotcom/jotdown/compare/v0.1.4...v0.1.5

This point release ensures a clean, working installation with all advertised features! 🎯✨
