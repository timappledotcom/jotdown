# 📝 jotDown

<div align="center">
  <img src="assets/icons/jotdown.svg" alt="jotDown Logo" width="128" height="128">
  
  **Simple and elegant notes application for Linux**
  
  [![Release](https://img.shields.io/github/v/release/timappledotcom/jotdown)](https://github.com/timappledotcom/jotdown/releases)
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
  [![Flutter](https://img.shields.io/badge/Flutter-3.24+-blue.svg)](https://flutter.dev/)
  [![Platform](https://img.shields.io/badge/Platform-Linux-orange.svg)](https://www.linux.org/)
</div>

jotDown is a beautiful, feature-rich notes application for Linux that combines the power of Markdown with the convenience of both a desktop GUI and command-line interface. Whether you prefer clicking or typing, jotDown adapts to your workflow.

## ✨ Features

### 🎨 Beautiful Interface
- **Modern Design**: Clean, intuitive interface following Material Design 3
- **Adaptive Themes**: System auto, light, and dark themes
- **Live Preview**: Toggle between Markdown editing and rendered preview
- **Responsive Layout**: Optimized for various screen sizes

### 🔐 Security & Privacy
- **AES-256 Encryption**: Secure your sensitive notes with strong encryption
- **Password Protection**: Optional password-based access control
- **Local Storage**: Your data stays on your machine - no cloud required

### 📂 Flexible Storage
- **Multiple Locations**: Choose where your notes are stored
  - App Data (default, no file system access needed)
  - Documents folder (`~/Documents/jotDown/`)
  - Home directory (`~/jotDown/`)
  - Custom location of your choice
- **Easy Migration**: Automatically migrate notes when changing locations
- **Backup & Export**: Create zip archives with individual Markdown files

### 🚀 Dual Interface
- **Desktop GUI**: Full-featured graphical application
- **Command Line**: Powerful CLI for automation and quick access
- **Shared Data**: Both interfaces work with the same notes seamlessly

### 📝 Markdown Support
- Headers, lists, and formatting
- Code blocks with syntax highlighting
- Links, images, and tables
- Blockquotes and more
- Live preview while editing

## 📦 Installation

### Download Pre-built Packages

Choose your preferred package format from our [releases page](https://github.com/timappledotcom/jotdown/releases):

#### DEB Package (Ubuntu/Debian)
```bash
wget https://github.com/timappledotcom/jotdown/releases/download/v0.1.0/jotdown-0.1.0-linux-amd64.deb
sudo dpkg -i jotdown-0.1.0-linux-amd64.deb
sudo apt-get install -f  # Fix dependencies if needed
```

#### RPM Package (Fedora/RHEL/openSUSE)
```bash
wget https://github.com/timappledotcom/jotdown/releases/download/v0.1.0/jotdown-0.1.0-linux-amd64.rpm
sudo rpm -i jotdown-0.1.0-linux-amd64.rpm
```

#### AppImage (Universal)
```bash
wget https://github.com/timappledotcom/jotdown/releases/download/v0.1.0/jotdown-0.1.0-linux-x86_64.AppImage
chmod +x jotdown-0.1.0-linux-x86_64.AppImage
./jotdown-0.1.0-linux-x86_64.AppImage
```

### Build from Source

#### Prerequisites
- Flutter SDK 3.24+
- Linux development tools
- GTK 3.0+ development libraries

```bash
# Install dependencies (Ubuntu/Debian)
sudo apt-get install libgtk-3-dev libx11-dev pkg-config cmake ninja-build libblkid-dev libsecret-1-dev

# Clone the repository
git clone https://github.com/timappledotcom/jotdown.git
cd jotdown

# Get Flutter dependencies
flutter pub get

# Enable Linux desktop support
flutter config --enable-linux-desktop

# Build the application
flutter build linux --release

# The built application will be in build/linux/x64/release/bundle/
```

## 🖥️ Usage

### Desktop Application

Launch jotDown from your application menu or run `jotdown` in the terminal.

#### Creating Notes
1. Click the "+" floating action button
2. Enter a title and start writing in Markdown
3. Use the preview toggle to see rendered output
4. Save with Ctrl+S or click the save button

#### Managing Storage
1. Click the settings gear icon
2. Choose your preferred storage location
3. Test the location and save
4. Optionally migrate existing notes

### Command Line Interface

jotDown includes a powerful CLI for terminal enthusiasts and automation.

#### Quick Start
```bash
# List all notes
jd list

# Add a new note
jd add -t "My Note" -c "Note content here"

# View a note
jd view --id 123456789

# Search notes
jd search -q "important"

# Use with your favorite editor
export EDITOR=vim
jd add -t "Meeting Notes" --editor
```

#### Convenient Wrapper
The `jd` command is a convenient wrapper around the full Dart CLI:

```bash
# Make it globally available
sudo ln -s /path/to/jotdown/bin/jd /usr/local/bin/jd
```

For detailed CLI documentation, see [CLI_README.md](CLI_README.md).

## 🔧 Development

### Project Structure
```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
├── services/                    # Business logic
├── screens/                     # UI screens
└── widgets/                     # Reusable components

bin/
├── jotdown.dart                 # CLI implementation
└── jd                          # CLI wrapper script

assets/
├── icons/                      # Application icons
└── jotdown.desktop            # Linux desktop integration
```

### Contributing

We welcome contributions! Please feel free to:
- Report bugs and issues
- Suggest new features
- Submit pull requests
- Improve documentation

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Flutter](https://flutter.dev/) for native Linux performance
- Icons created with love using SVG
- Inspired by the need for a simple, powerful notes application

## 📮 Support

- **Issues**: [GitHub Issues](https://github.com/timappledotcom/jotdown/issues)
- **Discussions**: [GitHub Discussions](https://github.com/timappledotcom/jotdown/discussions)

---

<div align="center">
  Made with ❤️ for the Linux community
</div>
