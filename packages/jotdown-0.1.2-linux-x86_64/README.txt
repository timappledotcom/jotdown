# jotDown v0.1.2 - Standalone Package

## Quick Start

1. **Desktop App**: Run `./jotdown` to start the desktop application
2. **CLI Setup**: Run `./bin/setup-jd.sh` to install the `jd` command globally

## Usage

### Desktop Application
- Double-click `jotdown` executable
- Or run `./jotdown` from terminal

### Command Line Interface
After running `./bin/setup-jd.sh`:
- `jd list` - List all notes
- `jd new "Note Title"` - Create new note
- `jd edit <id>` - Edit existing note
- `jd search "query"` - Search notes

## Files
- `jotdown` - Main desktop application
- `bin/jd` - CLI wrapper script
- `bin/jotdown-cli` - Compiled CLI executable
- `bin/setup-jd.sh` - CLI setup script
- `lib/` - Required libraries
- `data/` - Application assets

## Requirements
- Linux x86_64
- GTK3 libraries (usually pre-installed)

## Support
Visit: https://github.com/timappledotcom/jotdown
