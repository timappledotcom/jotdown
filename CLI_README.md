# jotDown CLI

A command-line interface for jotDown that shares the same data with the desktop application.

## Installation

The CLI is included with your jotDown installation. After installing jotDown, set up the `jd` command for convenient CLI access:

### Quick Setup (Recommended)
```bash
# Navigate to jotDown installation and run the setup script
cd /opt/jotdown  # or wherever jotDown is installed
sudo ./bin/setup-jd.sh
```

### Alternative Setup Methods

#### Download Setup Script
```bash
wget https://github.com/timappledotcom/jotdown/releases/download/v0.1.2/setup-cli.sh
chmod +x setup-cli.sh
sudo ./setup-cli.sh
```

#### Manual Setup
```bash
# Create symlink manually
sudo ln -s /opt/jotdown/bin/jd /usr/local/bin/jd
jd --help
```

### Using Without Global Setup
If you prefer not to set up the global command, you can use the CLI directly:
```bash
# Navigate to jotDown installation directory
cd /opt/jotdown
./bin/jd --help

# Or use the full Dart command from anywhere
dart /opt/jotdown/bin/jotdown.dart --help
```

## Usage

### Basic Commands

#### List all notes
```bash
jd list
```

#### Add a new note
```bash
# Add note with title and content
jd add -t "My Note Title" -c "Note content here"

# Add note using your default editor
jd add -t "My Note Title" --editor

# Add note with content from stdin
echo "Note content" | jd add -t "My Note Title" -c -
```

#### View a note
```bash
# View note with markdown formatting
jd view --id NOTE_ID

# View raw markdown
jd view --id NOTE_ID --raw
```

#### Edit a note
```bash
# Edit note content inline
jd edit --id NOTE_ID -c "New content"

# Edit note title
jd edit --id NOTE_ID -t "New Title"

# Edit note using your default editor
jd edit --id NOTE_ID --editor
```

#### Delete a note
```bash
# Delete with confirmation
jd delete --id NOTE_ID

# Force delete without confirmation
jd delete --id NOTE_ID --force
```

#### Search notes
```bash
jd search -q "search term"
```

### Settings Management

#### View current settings
```bash
jd settings --show
```

#### Change storage location
```bash
# Use documents folder
jd settings --storage documents

# Use home directory
jd settings --storage home

# Use custom path
jd settings --storage custom --custom-path /path/to/notes

# Use shared preferences (CLI will use config directory)
jd settings --storage shared_preferences
```

#### Change theme (affects desktop app)
```bash
jd settings --theme system   # Follow system theme
jd settings --theme light    # Always light theme
jd settings --theme dark     # Always dark theme
```

## Data Sharing

The CLI and desktop application share the same data files and settings. Notes created in one interface are immediately available in the other. Settings changes also sync between both interfaces in real-time.

### Storage Locations

- **shared_preferences**: Both CLI and desktop use `~/.local/share/com.example.jotdown/` (SharedPreferences format)
- **documents**: `~/Documents/jotDown/`
- **home**: `~/jotDown/`
- **custom**: User-specified directory

The CLI automatically detects and uses the same storage location configured in the desktop application.

## Editor Integration

The CLI respects the `EDITOR` environment variable. Set it to your preferred editor:

```bash
export EDITOR=vim
export EDITOR=nano
export EDITOR=code  # VS Code
export EDITOR=gedit
```

## Convenient Wrapper

Use the `jd` wrapper script for shorter commands:

```bash
# Make the wrapper available globally (optional)
sudo ln -s /path/to/jotDown/bin/jd /usr/local/bin/jd

# Then use short commands
jd list
jd add -t "Quick Note" -c "Content"
jd view --id 123456789
```

## Examples

### Creating a quick note
```bash
jd add -t "Shopping List" -c "- Milk\\n- Bread\\n- Eggs"
```

### Creating a note with your editor
```bash
export EDITOR=nano
jd add -t "Meeting Notes" --editor
```

### Searching for notes
```bash
jd search -q "meeting"
jd search -q "TODO"
```

### Backing up notes to a custom location
```bash
jd settings --storage custom --custom-path ~/Dropbox/Notes
```

### Viewing notes with markdown formatting
- **Bold text** appears bold in terminal
- *Italic text* appears italic
- `Code` appears with background highlighting
- # Headers appear bold and underlined
- ## Subheaders appear bold

## Tips

1. **Pipe content**: Use pipes and redirection with the CLI
   ```bash
   echo "Meeting agenda" | jd add -t "Meeting" -c -
   ```

2. **Script integration**: Use in shell scripts for automation
   ```bash
   #!/bin/bash
   DATE=$(date +%Y-%m-%d)
   jd add -t "Daily Log $DATE" --editor
   ```

3. **Quick view**: List notes and pipe to grep for quick filtering
   ```bash
   jd list | grep -i "todo"
   ```

4. **Backup**: Export all notes to individual files
   ```bash
   # This functionality could be added as a future enhancement
   ```

The CLI provides full access to your jotDown data from the command line, perfect for automation, quick note-taking, and integration with other command-line tools.
