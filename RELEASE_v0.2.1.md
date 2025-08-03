# 🚀 jotDown v0.2.1 Release

## Major Improvements

### 🎨 Latest Yaru Theme Integration
- **Yaru 8.1.0**: Upgraded to the latest Ubuntu theme for authentic native appearance
- **Flutter 3.32.8**: Updated to the latest stable Flutter with Dart 3.8.1
- **Enhanced Theming**: Improved Ubuntu orange branding and Material Design 3 integration
- **Better Performance**: Faster rendering and improved system integration

### 📁 Enhanced Flat File Storage
- **Individual .md Files**: Each note stored as a separate Markdown file for maximum compatibility
- **External Tool Support**: Open notes in VS Code, Vim, or any Markdown editor
- **Better Backup**: Easy version control with git and standard backup tools
- **File System Integration**: Browse notes directly in file manager

### 🔧 Technical Improvements
- **Null Safety**: Fixed critical null safety issues in encryption services
- **Type Safety**: Improved type casting and error handling
- **Dependency Updates**: All dependencies updated to latest compatible versions
- **Build System**: Enhanced Linux build support with proper GTK integration

## What's New

### 🎯 User Experience
- **Native Ubuntu Look**: True Ubuntu appearance with Yaru theme integration
- **Seamless CLI/GUI**: Perfect data synchronization between desktop and command-line
- **Improved Stability**: Better error handling and crash prevention
- **Enhanced Performance**: Faster app startup and note loading

### 🛠️ Developer Experience
- **Modern Flutter**: Latest Flutter 3.32.8 with newest features
- **Better Debugging**: Improved error messages and development tools
- **Future-Proof**: Compatible with upcoming Flutter releases
- **Clean Architecture**: Improved code organization and maintainability

## Package Downloads

| Package Type | Size | Description |
|--------------|------|-------------|
| **DEB** | ~18MB | For Debian/Ubuntu systems |
| **RPM** | ~15MB | For Red Hat/Fedora/SUSE systems |
| **TAR.XZ** | ~16MB | Portable archive for any Linux |
| **AppImage** | ~22MB | Universal Linux package (portable) |

## Installation

### DEB Package (Debian/Ubuntu)
```bash
wget https://github.com/timappledotcom/jotdown/releases/download/v0.2.1/jotdown-v0.2.1-amd64.deb
sudo dpkg -i jotdown-v0.2.1-amd64.deb
```

### RPM Package (Red Hat/Fedora/SUSE)
```bash
wget https://github.com/timappledotcom/jotdown/releases/download/v0.2.1/jotdown-v0.2.1-x86_64.rpm
sudo rpm -i jotdown-v0.2.1-x86_64.rpm
```

### AppImage (Universal)
```bash
wget https://github.com/timappledotcom/jotdown/releases/download/v0.2.1/JotDown-v0.2.1-x86_64.AppImage
chmod +x JotDown-v0.2.1-x86_64.AppImage
./JotDown-v0.2.1-x86_64.AppImage
```

### Portable Archive
```bash
wget https://github.com/timappledotcom/jotdown/releases/download/v0.2.1/jotdown-v0.2.1-linux-x64.tar.xz
tar -xf jotdown-v0.2.1-linux-x64.tar.xz
cd jotdown-v0.2.1-linux-x64
sudo ./install.sh
```

## CLI Setup

After installation, set up the convenient `jd` command:

```bash
# Quick setup (recommended)
cd /opt/jotdown  # or your installation directory
sudo ./bin/setup-jd.sh

# Or create symlink manually
sudo ln -s /opt/jotdown/bin/jd /usr/local/bin/jd
jd --help
```

## Key Features

### 📝 Flat File Storage
- **Individual Files**: Each note is a separate `.md` file
- **Tool Compatibility**: Use with any Markdown editor or processor
- **Easy Backup**: Standard file operations and version control
- **File Manager**: Browse notes directly in your file manager

### 🎨 Ubuntu Integration
- **Yaru 8.1.0**: Latest official Ubuntu theme
- **Native Appearance**: Matches system theme preferences
- **Ubuntu Colors**: Signature orange (#E95420) and purple (#77216F)
- **System Integration**: Proper desktop and taskbar integration

### 🖥️ Dual Interface
- **Desktop GUI**: Full-featured graphical application
- **Command Line**: Powerful CLI for automation and quick access
- **Data Sync**: Seamless sharing between GUI and CLI
- **Consistent Experience**: Same features in both interfaces

## File Structure

When using file-based storage:

```
~/Documents/jotdown/           # or your chosen location
├── index.json                 # Metadata index
├── 1754163227093.md          # Individual note files
├── 1754163228094.md
├── 1754163229095.md
└── encryption.salt           # If encryption enabled
```

## Migration from Previous Versions

### Automatic Migration
- Existing notes are preserved during upgrade
- Settings and preferences maintained
- Optional migration to flat file storage
- No data loss during transition

### Manual Migration
1. Open jotDown Settings
2. Change Storage Location to "Documents Folder"
3. Accept migration prompt
4. Notes converted to individual `.md` files

## System Requirements

### Minimum Requirements
- **OS**: Linux (any modern distribution)
- **Flutter**: 3.24.0 or higher
- **Dart**: 3.5.0 or higher
- **Memory**: 512MB RAM
- **Storage**: 50MB free space

### Recommended
- **OS**: Ubuntu 22.04+ (for best Yaru integration)
- **Flutter**: 3.32.8 (latest stable)
- **Memory**: 1GB RAM
- **Storage**: 100MB free space

## Breaking Changes

**None** - This is a fully backward-compatible release.

## Bug Fixes

- Fixed null safety issues in encryption services
- Resolved type casting errors in DateTime operations
- Improved error handling in file operations
- Fixed theme switching edge cases
- Enhanced CLI argument parsing

## Performance Improvements

- Faster app startup with optimized theme loading
- Improved note loading performance with flat files
- Better memory usage with lazy loading
- Enhanced search performance with indexed metadata

## Developer Notes

### Dependencies Updated
- `yaru: ^8.1.0` (was 6.0.0)
- `flutter: ">=3.24.0"` (was 3.18.0)
- All other dependencies updated to latest compatible versions

### Build Requirements
- Flutter 3.32.8 or higher
- Linux development tools (clang, cmake, ninja-build, pkg-config)
- GTK 3.0+ development libraries

## Testing

This release has been tested on:
- Ubuntu 25.04 (Plucky Puffin)
- Ubuntu 24.04 LTS (Noble Numbat)
- Fedora 40
- openSUSE Tumbleweed
- Arch Linux

## Known Issues

- Minor X Window System warnings on some configurations (non-critical)
- Some deprecated color methods (will be addressed in future Flutter versions)

## Roadmap

### Next Release (v0.2.2)
- Address remaining deprecation warnings
- Enhanced folder organization for notes
- Improved search with full-text indexing
- Additional export formats

### Future Features
- Android companion app
- P2P synchronization
- Enhanced security features
- Plugin system for extensions

## Support

- **Issues**: [GitHub Issues](https://github.com/timappledotcom/jotdown/issues)
- **Discussions**: [GitHub Discussions](https://github.com/timappledotcom/jotdown/discussions)
- **Documentation**: [Project Wiki](https://github.com/timappledotcom/jotdown/wiki)

---

**Full Changelog**: https://github.com/timappledotcom/jotdown/compare/v0.2.0...v0.2.1

**Download**: [GitHub Releases](https://github.com/timappledotcom/jotdown/releases/tag/v0.2.1)

---

<div align="center">
  Made with ❤️ for the Linux community
</div>