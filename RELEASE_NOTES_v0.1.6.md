# JotDown v0.1.6 Release Notes

## 🔧 Desktop Integration & Sync Fixes

### ✅ Desktop Integration Fixed
- **Fixed: App icon now properly appears in dock/taskbar**
- **Fixed: App can now be pinned to dock/favorites**
- **Enhanced: Proper desktop integration with StartupWMClass**
- **Improved: Multi-resolution icon installation (48x48, 64x64, 128x128, 256x256)**
- **Fixed: Application menu categorization and search discoverability**

### 🔄 Manual Refresh Sync Fixed
- **Fixed: Refresh button now properly syncs CLI-added notes**
- **Enhanced: `_forceRefresh()` method for reliable manual sync**
- **Improved: User feedback with "Notes refreshed" confirmation**
- **Fixed: No more need to restart app to see CLI changes**

### 🛠️ Post-Install Improvements
- **Enhanced: Desktop database updates for proper integration**
- **Added: Icon cache refresh for immediate icon display**
- **Improved: MIME database integration**
- **Fixed: Proper cleanup on package removal**

## 📦 Fresh Package Build

Complete rebuild with all latest fixes:

- **DEB Package** (`jotdown-v0.1.6-amd64.deb`): For Ubuntu/Debian systems
- **TAR.XZ Archive** (`jotdown-v0.1.6-linux-x64.tar.xz`): Universal Linux distribution

## 🚀 Installation

### New Installation

**DEB Package (Ubuntu/Debian):**
```bash
wget https://github.com/timappledotcom/jotdown/releases/download/v0.1.6/jotdown-v0.1.6-amd64.deb
sudo dpkg -i jotdown-v0.1.6-amd64.deb
```

**TAR.XZ Archive (Universal Linux):**
```bash
wget https://github.com/timappledotcom/jotdown/releases/download/v0.1.6/jotdown-v0.1.6-linux-x64.tar.xz
tar -xJf jotdown-v0.1.6-linux-x64.tar.xz
cd jotdown-v0.1.6-linux-x64
./install.sh
```

### Upgrading from Previous Versions

If you have any previous version installed:

```bash
# Download and install new version
wget https://github.com/timappledotcom/jotdown/releases/download/v0.1.6/jotdown-v0.1.6-amd64.deb
sudo dpkg -i jotdown-v0.1.6-amd64.deb
```

Your notes, settings, and data will be preserved.

## ✨ What's Working Now

### 🖥️ Desktop Integration
- **App Icon**: Properly appears in dock and can be pinned
- **Application Menu**: Easy to find in office/utility categories
- **Desktop File**: Correct paths and window class for proper recognition
- **Multi-DE Support**: Works across GNOME, KDE, XFCE, and other environments

### 🔄 Real-time Sync
- **Manual Refresh**: Refresh button immediately shows CLI-added notes
- **Auto-refresh**: 1-second intervals with dual detection
- **User Feedback**: Clear confirmation when refresh completes
- **Error Handling**: Proper error messages and recovery

### 🏷️ Tag Features
- Use `#tagname` anywhere in note content
- Tags appear as colored badges
- Filter notes using dropdown menu
- Search by tag: `jd search --tag tagname`

## 🐛 Issues Resolved

- ✅ App icon not appearing in dock/taskbar
- ✅ Unable to pin app to dock/favorites  
- ✅ Manual refresh button not syncing CLI changes
- ✅ Desktop integration missing proper window class
- ✅ Icon cache not updating after installation
- ✅ Package inconsistencies between versions

## 📋 Version Consistency

All components now consistently use v0.1.6:
- Flutter GUI application
- Dart CLI tool  
- Package metadata
- Installation scripts
- Desktop integration files

## 🔄 Migration Notes

- Existing notes and settings are fully preserved
- No data migration required
- Desktop integration updates automatically
- Settings and preferences maintained

---

**Full Changelog:** https://github.com/timappledotcom/jotdown/compare/v0.1.5...v0.1.6

This point release ensures proper desktop integration and reliable sync functionality! 🎯✨
