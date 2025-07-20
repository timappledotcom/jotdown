#!/bin/bash
# jotDown Portable Launcher
# This script runs jotDown from any location

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Run the application
./jotdown "$@"
