# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
