#!/bin/bash

# jotDown v0.2.0 Installation Script
# This script installs jotDown system-wide

set -e

INSTALL_DIR="/opt/jotdown"
BIN_DIR="/usr/local/bin"
DESKTOP_DIR="/usr/share/applications"

echo "Installing jotDown v0.2.0..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root (use sudo)"
    exit 1
fi

# Create installation directory
echo "Creating installation directory..."
mkdir -p "$INSTALL_DIR"

# Copy application files
echo "Copying application files..."
cp -r * "$INSTALL_DIR/"

# Make executable
chmod +x "$INSTALL_DIR/jotdown"

# Create CLI symlink
echo "Creating CLI command..."
ln -sf "$INSTALL_DIR/bin/jd" "$BIN_DIR/jd"

# Create desktop entry
echo "Creating desktop entry..."
cat > "$DESKTOP_DIR/jotdown.desktop" << EOF
[Desktop Entry]
Name=jotDown
Comment=Simple and elegant notes application
Exec=$INSTALL_DIR/jotdown
Icon=$INSTALL_DIR/data/flutter_assets/assets/icons/jotdown.svg
Terminal=false
Type=Application
Categories=Office;TextEditor;Utility;
Keywords=notes;markdown;text;editor;cli;
StartupNotify=true
StartupWMClass=jotdown
EOF

# Update desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$DESKTOP_DIR"
fi

echo ""
echo "✓ jotDown v0.2.0 installed successfully!"
echo ""
echo "You can now:"
echo "  • Launch jotDown from your application menu"
echo "  • Run 'jotdown' from the terminal"
echo "  • Use 'jd' for CLI commands"
echo ""
echo "Storage locations available:"
echo "  • Documents folder: ~/Documents/jotdown/"
echo "  • Home directory: ~/jotdown/"
echo "  • Custom location of your choice"
echo ""
echo "For help: jd --help"
echo "Documentation: https://github.com/timappledotcom/jotdown"