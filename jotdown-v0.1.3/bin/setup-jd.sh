#!/bin/bash

# jotDown CLI Setup Script
# Run this after installing jotDown to set up the 'jd' command globally

echo "🔧 Setting up jotDown CLI command..."

# Function to find jotDown installation
find_jotdown() {
    # Common installation paths
    local paths=(
        "/opt/jotdown"
        "/usr/local/jotdown" 
        "/usr/share/jotdown"
        "$HOME/.local/share/jotdown"
        "$HOME/Applications/jotdown"
    )
    
    for path in "${paths[@]}"; do
        if [ -d "$path" ] && [ -f "$path/bin/jd" ]; then
            echo "$path"
            return 0
        fi
    done
    
    return 1
}

# Try to find jotDown installation
JOTDOWN_DIR=$(find_jotdown)

if [ -z "$JOTDOWN_DIR" ]; then
    echo "❌ Could not find jotDown installation"
    echo ""
    echo "Please make sure jotDown is installed. If you installed from a package,"
    echo "the installation directory should contain a 'bin/jd' script."
    echo ""
    echo "If you know where jotDown is installed, you can create the symlink manually:"
    echo "sudo ln -s /path/to/jotdown/bin/jd /usr/local/bin/jd"
    exit 1
fi

echo "✓ Found jotDown at: $JOTDOWN_DIR"

JD_SCRIPT="$JOTDOWN_DIR/bin/jd"
JD_TARGET="/usr/local/bin/jd"

# Make sure the jd script is executable
chmod +x "$JD_SCRIPT"

# Check if we can write to /usr/local/bin
if [ -w "/usr/local/bin" ]; then
    # Remove existing symlink if it exists
    if [ -L "$JD_TARGET" ]; then
        rm "$JD_TARGET"
    fi
    
    # Create symlink
    ln -s "$JD_SCRIPT" "$JD_TARGET"
    
    if [ $? -eq 0 ]; then
        echo "✅ Successfully set up 'jd' command!"
        echo ""
        echo "You can now use jotDown CLI with short commands:"
        echo "  jd list                    # List all notes"
        echo "  jd add -t 'Title' -c 'Text' # Add a new note"
        echo "  jd view --id 123456789     # View a note"
        echo "  jd search -q 'keyword'     # Search notes"
        echo ""
        echo "Try it now: jd --help"
    else
        echo "❌ Failed to create symlink"
        exit 1
    fi
else
    echo "⚠️  Need administrator privileges to set up global command"
    echo ""
    echo "Please run with sudo:"
    echo "sudo $0"
    echo ""
    echo "Or create the symlink manually:"
    echo "sudo ln -s $JD_SCRIPT $JD_TARGET"
    exit 1
fi

echo ""
echo "🎉 Setup complete! jotDown CLI is ready to use."
