#!/bin/bash

# Post-installation script for jotDown
# This script sets up the jd CLI command globally

# Define installation paths
INSTALL_DIR="/opt/jotdown"
BIN_DIR="/usr/local/bin"
JD_SCRIPT="$INSTALL_DIR/bin/jd"
JD_SYMLINK="$BIN_DIR/jd"

echo "Setting up jotDown CLI..."

# Check if the installation directory exists
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Warning: jotDown installation directory not found at $INSTALL_DIR"
    echo "Looking for alternative installation paths..."

    # Check common AppImage paths
    if [ -f "$HOME/.local/bin/jotdown.AppImage" ]; then
        echo "Found AppImage installation"
        exit 0
    fi

    exit 1
fi

# Check if jd script exists
if [ ! -f "$JD_SCRIPT" ]; then
    echo "Warning: jd script not found at $JD_SCRIPT"
    exit 1
fi

# Make sure jd script is executable
chmod +x "$JD_SCRIPT"

# Create symlink in /usr/local/bin
if [ -w "$BIN_DIR" ]; then
    # Remove existing symlink if it exists
    if [ -L "$JD_SYMLINK" ]; then
        rm "$JD_SYMLINK"
    fi

    # Create new symlink
    ln -s "$JD_SCRIPT" "$JD_SYMLINK"

    if [ $? -eq 0 ]; then
        echo "✓ jd command installed successfully"
        echo "You can now use 'jd' from anywhere in the terminal"
        echo ""
        echo "Try: jd list"
        echo "     jd add -t 'Test Note' -c 'Hello from CLI!'"
    else
        echo "Failed to create symlink"
        exit 1
    fi
else
    echo "Cannot write to $BIN_DIR. You may need to run with sudo or create the symlink manually:"
    echo "sudo ln -s $JD_SCRIPT $JD_SYMLINK"
fi

echo "jotDown installation complete!"
