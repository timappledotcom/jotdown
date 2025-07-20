# JotDown v0.1.4 Release Notes

## 🆕 New Features

### 📖 Comprehensive Help System
- **Help Button**: Added help (❓) icon to the app bar for easy access
- **Interactive Help Dialog**: Detailed, organized help covering all features:
  - Creating and editing notes with Markdown
  - Using hashtag tags (#tagname) with examples  
  - Searching and filtering capabilities
  - Command-line interface integration
  - Settings and encryption features
- **Visual Enhancement**: Icons, proper spacing, and professional styling
- **Pro Tips**: Highlighted callout boxes with helpful hints

### 🛠️ Installation & GUI Improvements
- **Fixed GUI Launch**: Desktop file now uses full executable path
- **Enhanced Installation**: Improved postinst script creates proper symlinks
- **Clean Uninstallation**: Added prerm script for complete cleanup
- **Better Desktop Integration**: Improved icon and application menu setup

## 🔧 Technical Improvements

### Desktop Integration
- Fixed desktop file execution path for reliable GUI launching
- Enhanced postinst script automatically creates `/usr/local/bin/jotdown` symlink
- Added proper icon symlinks for system pixmaps
- Improved desktop database updates during installation

### User Experience
- Help dialog is fully scrollable and responsive
- Theme-aware colors work in both light and dark modes
- Organized help sections with clear visual hierarchy
- Beginner-friendly language and actionable instructions

### Code Quality
- Better separation of help content into reusable components
- Improved error handling in package installation scripts
- Enhanced maintainability with modular help dialog structure

## 📦 Package Updates

All three package formats have been updated:

- **DEB Package** (`jotdown-v0.1.4-amd64.deb`): 21 MB
- **TAR.XZ Archive** (`jotdown-v0.1.4-linux-x64.tar.xz`): 19 MB  
- **AppImage** (`jotdown-v0.1.4-linux-x86_64.AppImage`): 26 MB

## 🚀 Installation

### New Installation (v0.1.4)

**DEB Package (Ubuntu/Debian)**
```bash
wget https://github.com/timappledotcom/jotdown/releases/download/v0.1.4/jotdown-v0.1.4-amd64.deb
sudo dpkg -i jotdown-v0.1.4-amd64.deb
sudo apt-get install -f  # Fix any dependencies
```

**TAR.XZ Archive (Universal Linux)**
```bash
wget https://github.com/timappledotcom/jotdown/releases/download/v0.1.4/jotdown-v0.1.4-linux-x64.tar.xz
tar -xJf jotdown-v0.1.4-linux-x64.tar.xz
cd jotdown-v0.1.4
./install.sh
```

**AppImage (Portable)**
```bash
wget https://github.com/timappledotcom/jotdown/releases/download/v0.1.4/jotdown-v0.1.4-linux-x86_64.AppImage
chmod +x jotdown-v0.1.4-linux-x86_64.AppImage
./jotdown-v0.1.4-linux-x86_64.AppImage
```

### Upgrading from v0.1.3

If you installed v0.1.3 via DEB package:
```bash
wget https://github.com/timappledotcom/jotdown/releases/download/v0.1.4/jotdown-v0.1.4-amd64.deb
sudo dpkg -i jotdown-v0.1.4-amd64.deb
```

Your notes and settings will be preserved during the upgrade.

## 🐛 Bug Fixes

- **GUI Launch Issues**: Fixed desktop file execution path
- **Installation Problems**: Resolved symlink creation during package installation
- **Desktop Integration**: Fixed application menu icon display
- **Uninstallation**: Added proper cleanup of system files

## 💡 How to Use the New Help Feature

1. **Access Help**: Click the ❓ button in the app bar
2. **Browse Sections**: Scroll through organized help topics
3. **Learn Tags**: See examples of #hashtag usage
4. **CLI Integration**: Understand how GUI and CLI work together
5. **Settings Guide**: Learn about all available options

## 🔄 What's Preserved

- All your existing notes and tags
- Current settings and preferences  
- Storage location configuration
- Encryption passwords (if used)

## 📋 Version Consistency

All components now use version 0.1.4:
- Flutter GUI application: v0.1.4
- Dart CLI tool: v0.1.4  
- Package metadata: v0.1.4
- Installation scripts: v0.1.4

---

**Full Changelog**: https://github.com/timappledotcom/jotdown/compare/v0.1.3...v0.1.4

This patch release focuses on improving user experience and fixing installation issues. The comprehensive help system makes jotDown much more accessible to new users! 📚✨
