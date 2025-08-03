# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.1] - 2025-08-02

### Added
- **Latest Yaru Theme**: Upgraded to Yaru 8.1.0 for authentic Ubuntu appearance
- **Enhanced Flat File Storage**: Individual .md files for maximum compatibility
- **External Tool Integration**: Open notes in VS Code, Vim, or any Markdown editor
- **Improved File System Integration**: Browse notes directly in file manager

### Changed
- **Flutter Upgrade**: Updated to Flutter 3.32.8 with Dart 3.8.1
- **Performance Improvements**: Faster app startup and note loading
- **Better Ubuntu Integration**: Enhanced system theme detection and native appearance
- **Dependency Updates**: All dependencies updated to latest compatible versions

### Fixed
- **Critical Null Safety**: Fixed null safety issues in encryption services
- **Type Safety**: Improved type casting for DateTime operations
- **Theme Switching**: Resolved edge cases in light/dark mode transitions
- **CLI Argument Parsing**: Enhanced command-line interface reliability

### Technical
- **Build System**: Improved Linux build support with proper GTK integration
- **Code Quality**: Better error handling and crash prevention
- **Architecture**: Cleaner separation between GUI and CLI components
- **Documentation**: Comprehensive migration guides and technical documentation

## [0.1.2] - 2025-07-19

### Fixed
- **Critical Password Bug**: Fixed salt mismatch issue that caused "Incorrect password" errors even with correct passwords
- Password verification now uses the correct salt consistently between setup and verification
- Added proper password salt storage separate from encryption salt
- **CLI Setup Issue**: Fixed `jd` command not being available after installation

### Added
- Setup scripts for configuring the `jd` CLI command globally
- Included `setup-jd.sh` script in installation packages
- Improved installation instructions for CLI access
- Improved salt handling for both SharedPreferences and file storage modes

### Technical Details
- Fixed `_enableEncryption()` and `_changePassword()` methods in settings screen
- Updated `_getSalt()` method to prioritize password salt over encryption salt
- Added migration logic to handle existing installations

## [0.1.1] - 2025-07-19

### Fixed
- **GitHub Actions Compatibility**: Fixed CI build failure by adjusting Dart SDK requirement from ^3.8.1 to ^3.5.0
- **Automated Packaging**: Ensured DEB, RPM, and AppImage packages can be built successfully in CI environment
- **Flutter Version**: Updated workflow to use stable Flutter 3.24.0 for reliable builds

### Technical
- Maintained full backward compatibility with all existing features
- No functional changes - purely technical fixes for CI/CD pipeline

## [0.1.0] - 2025-07-19

### Added
- 📝 **Core Notes Management**
  - Create, edit, and delete notes with Markdown support
  - Real-time search across note titles and content
  - Live Markdown preview toggle
  - Auto-save functionality

- 🎨 **Beautiful Interface**
  - Material Design 3 UI
  - Adaptive themes (System Auto, Light, Dark)
  - Responsive layout for various screen sizes
  - Clean, intuitive navigation

- 🔐 **Security Features**
  - AES-256 encryption for sensitive notes
  - Password protection with secure key derivation (PBKDF2)
  - Session-based authentication
  - Local-only data storage

- 📂 **Flexible Storage Options**
  - App Data (Shared Preferences) - default
  - Documents folder (`~/Documents/jotDown/`)
  - Home directory (`~/jotDown/`)
  - Custom directory selection
  - Automatic note migration between locations

- 💾 **Backup & Export**
  - Export all notes to ZIP archives
  - Individual Markdown file export
  - Full backup with metadata preservation
  - Import from previously exported archives

- 🚀 **Dual Interface**
  - Full-featured desktop GUI application
  - Powerful command-line interface (CLI)
  - Shared data between both interfaces
  - `jd` wrapper script for convenient CLI access

- 🖥️ **Linux Integration**
  - Native GTK application
  - System tray integration
  - .desktop file for application menu
  - Multiple package formats (DEB, RPM, AppImage)

- ⌨️ **CLI Features**
  - List, add, edit, delete notes from terminal
  - Search functionality
  - Settings management
  - Editor integration (respects $EDITOR)
  - Pipe and redirection support
  - Shell script integration

### Technical Details
- Built with Flutter 3.24+ for native Linux performance
- Dart-based CLI for consistency and performance
- Encrypted storage using industry-standard algorithms
- Cross-platform file handling with proper error management
- Comprehensive test coverage

### Package Formats
- **DEB**: For Ubuntu, Debian, and derivatives
- **RPM**: For Fedora, RHEL, openSUSE, and derivatives
- **AppImage**: Universal Linux package (portable)

---

*For installation instructions and usage details, see [README.md](README.md)*
