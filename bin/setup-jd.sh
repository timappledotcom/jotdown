#!/bin/bash

# jotDown CLI Quick Setup
# This script helps set up the 'jd' command after installing jotDown

echo "🔧 Setting up jotDown CLI command..."

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if jd is already set up
if command_exists jd; then
    echo "✅ 'jd' command is already set up!"
    echo "Current version: $(jd --version 2>/dev/null || echo 'Unknown')"
    echo ""
    echo "Test it: jd --help"
    exit 0
fi

# Common jotDown installation paths
COMMON_PATHS=(
    "/opt/jotdown/bin/jd"
    "/usr/local/jotdown/bin/jd"
    "/usr/share/jotdown/bin/jd"
    "$HOME/.local/share/jotdown/bin/jd"
    "$HOME/Applications/jotdown/bin/jd"
    "$(pwd)/bin/jd"  # Current directory
    "$(dirname "$0")/jd"  # Same directory as this script
)

JD_SCRIPT=""

# Find jd script
for path in "${COMMON_PATHS[@]}"; do
    if [ -f "$path" ]; then
        JD_SCRIPT="$path"
        break
    fi
done

if [ -z "$JD_SCRIPT" ]; then
    echo "❌ Could not find jotDown installation"
    echo ""
    echo "Please make sure jotDown is installed. Looking for 'bin/jd' script in:"
    for path in "${COMMON_PATHS[@]}"; do
        echo "  - $path"
    done
    echo ""
    echo "If jotDown is installed elsewhere, create the symlink manually:"
    echo "  sudo ln -s /path/to/jotdown/bin/jd /usr/local/bin/jd"
    exit 1
fi

echo "✓ Found jotDown at: $(dirname "$(dirname "$JD_SCRIPT")")"

# Make sure the script is executable
chmod +x "$JD_SCRIPT"

# Try to create symlink in /usr/local/bin
TARGET="/usr/local/bin/jd"

if [ -w "/usr/local/bin" ]; then
    # Remove existing symlink if it exists
    [ -L "$TARGET" ] && rm "$TARGET"

    # Create symlink
    if ln -s "$JD_SCRIPT" "$TARGET" 2>/dev/null; then
        echo "✅ Successfully set up 'jd' command!"

        # Verify the symlink works
        if [ -L "$TARGET" ] && [ -f "$TARGET" ]; then
            echo "✓ Symlink created and verified: $TARGET -> $JD_SCRIPT"
        else
            echo "⚠️  Symlink created but verification failed"
            echo "   Target: $TARGET"
            echo "   Source: $JD_SCRIPT"
        fi
    else
        echo "❌ Failed to create symlink"
        echo "   From: $JD_SCRIPT"
        echo "   To: $TARGET"
        echo "   Try running with sudo or check permissions"
        exit 1
    fi
else
    echo "⚠️  Need administrator privileges"
    echo ""
    echo "Run with sudo to set up global command:"
    echo "  sudo $0"
    echo ""
    echo "Or create symlink manually:"
    echo "  sudo ln -s $JD_SCRIPT $TARGET"
    exit 1
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Try these commands:"
echo "  jd --help               # Show help"
echo "  jd list                 # List notes"
echo "  jd add -t 'Test' -c 'Hello!'  # Add a note"

# Test the command
if command_exists jd; then
    echo ""
    echo "✓ Command test successful: $(jd --version 2>/dev/null || echo 'jd command is working')"
fi
