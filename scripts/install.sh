#!/bin/bash

# jotDown v0.1.3 Installation Script
# This script extracts and installs jotDown with automatic CLI setup

set -e

echo "Installing jotDown v0.1.5..."

# Check if we're in the extracted directory
if [ ! -f "jotdown" ] || [ ! -d "bin" ]; then
    echo "❌ Please run this script from the extracted jotDown directory"
    echo "   containing 'jotdown' executable and 'bin' directory"
    exit 1
fi

# Default installation directory
INSTALL_DIR="/opt/jotdown"

# Check if user wants custom installation directory
while getopts "d:" opt; do
    case $opt in
        d)
            INSTALL_DIR="$OPTARG"
            ;;
        \?)
            echo "Usage: $0 [-d installation_directory]"
            echo "Default installation directory: $INSTALL_DIR"
            exit 1
            ;;
    esac
done

echo "📂 Installing to: $INSTALL_DIR"

# Check if running as root for system installation
if [ "$INSTALL_DIR" = "/opt/jotdown" ] && [ "$EUID" -ne 0 ]; then
    echo "⚠️  System installation requires root privileges"
    echo "   Run with: sudo ./install.sh"
    echo "   Or specify user directory: ./install.sh -d \$HOME/jotdown"
    exit 1
fi

# Create installation directory
echo "📁 Creating installation directory..."
mkdir -p "$INSTALL_DIR"

# Copy files
echo "📋 Copying application files..."
cp -r * "$INSTALL_DIR/"

# Make executables executable
echo "🔧 Setting permissions..."
chmod +x "$INSTALL_DIR/jotdown"
chmod +x "$INSTALL_DIR/bin/jd"
chmod +x "$INSTALL_DIR/bin/setup-jd.sh"

# Set up CLI command
echo "⚡ Setting up CLI command..."
if [ "$INSTALL_DIR" = "/opt/jotdown" ]; then
    # System installation - set up global command
    if [ -w "/usr/local/bin" ]; then
        ln -sf "$INSTALL_DIR/bin/jd" "/usr/local/bin/jd"
        echo "✅ Global 'jd' command set up successfully"
    else
        echo "⚠️  Could not set up global 'jd' command automatically"
        echo "   Run manually: sudo ln -sf $INSTALL_DIR/bin/jd /usr/local/bin/jd"
    fi
else
    # User installation - add to user's local bin
    mkdir -p "$HOME/.local/bin"
    ln -sf "$INSTALL_DIR/bin/jd" "$HOME/.local/bin/jd"

    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo "⚠️  Add ~/.local/bin to your PATH to use 'jd' command globally"
        echo "   Add this to your ~/.bashrc or ~/.zshrc:"
        echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
    echo "✅ User 'jd' command set up successfully"
fi

# Create desktop entry for system installation
if [ "$INSTALL_DIR" = "/opt/jotdown" ] && [ -d "/usr/share/applications" ]; then
    echo "🖥️  Creating desktop entry..."
    cat > /usr/share/applications/jotdown.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=jotDown
Comment=Simple, secure note-taking application
Exec=$INSTALL_DIR/jotdown
Icon=accessories-text-editor
Terminal=false
Categories=Office;TextEditor;Utility;
EOF
    echo "✅ Desktop entry created"
fi

echo ""
echo "🎉 jotDown v0.1.3 installed successfully!"
echo ""
echo "📖 Getting Started:"
echo "   Desktop App: Launch 'jotDown' from applications menu"
echo "   CLI: jd --help"
echo ""
echo "📋 Quick CLI Commands:"
echo "   jd list                     # List all notes"
echo "   jd add -t 'Title' -c 'Text' # Add a new note"
echo "   jd view --id 123456789      # View a note"
echo "   jd search -q 'keyword'      # Search notes"
echo ""
echo "📚 Documentation:"
echo "   README.md      - Main documentation"
echo "   CLI_README.md  - CLI usage guide"
echo "   INSTALL.md     - Installation troubleshooting"
echo "   CHANGELOG.md   - Version history"
echo ""
echo "🎉 New Features in v0.1.3:"
echo "   ✨ Tag support with #hashtag syntax"
echo "   🔍 Enhanced search with tag filtering"
echo "   🎨 New fountain pen icon design"
echo "   🔄 Auto-refresh GUI when CLI makes changes"
echo "   📋 Tag management and listing"
echo "   ✓ Critical password verification bug"
echo "   ✓ CLI 'jd' command setup"
echo ""
echo "Happy note-taking! 📝"
