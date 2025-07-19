# jotDown CLI

A command-line interface for jotDown that shares the same data with the desktop application.

## Installation

The CLI is included with your jotDown installation. No additional setup is required.

## Usage

### Basic Commands

#### List all notes
```bash
dart bin/jotdown.dart list
```

#### Add a new note
```bash
# Add note with title and content
dart bin/jotdown.dart add -t "My Note Title" -c "Note content here"

# Add note using your default editor
dart bin/jotdown.dart add -t "My Note Title" --editor

# Add note with content from stdin
echo "Note content" | dart bin/jotdown.dart add -t "My Note Title" -c -
```

#### View a note
```bash
# View note with markdown formatting
dart bin/jotdown.dart view --id NOTE_ID

# View raw markdown
dart bin/jotdown.dart view --id NOTE_ID --raw
```

#### Edit a note
```bash
# Edit note content inline
dart bin/jotdown.dart edit --id NOTE_ID -c "New content"

# Edit note title
dart bin/jotdown.dart edit --id NOTE_ID -t "New Title"

# Edit note using your default editor
dart bin/jotdown.dart edit --id NOTE_ID --editor
```

#### Delete a note
```bash
# Delete with confirmation
dart bin/jotdown.dart delete --id NOTE_ID

# Force delete without confirmation
dart bin/jotdown.dart delete --id NOTE_ID --force
```

#### Search notes
```bash
dart bin/jotdown.dart search -q "search term"
```

### Settings Management

#### View current settings
```bash
dart bin/jotdown.dart settings --show
```

#### Change storage location
```bash
# Use documents folder
dart bin/jotdown.dart settings --storage documents

# Use home directory
dart bin/jotdown.dart settings --storage home

# Use custom path
dart bin/jotdown.dart settings --storage custom --custom-path /path/to/notes

# Use shared preferences (CLI will use config directory)
dart bin/jotdown.dart settings --storage shared_preferences
```

#### Change theme (affects desktop app)
```bash
dart bin/jotdown.dart settings --theme system   # Follow system theme
dart bin/jotdown.dart settings --theme light    # Always light theme
dart bin/jotdown.dart settings --theme dark     # Always dark theme
```

## Data Sharing

The CLI and desktop application share the same data files. Notes created in one interface are immediately available in the other. Settings changes also sync between both interfaces.

### Storage Locations

- **shared_preferences**: CLI uses `~/.config/jotdown/` (Desktop uses system preference store)
- **documents**: `~/Documents/jotDown/`
- **home**: `~/jotDown/`
- **custom**: User-specified directory

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
dart bin/jotdown.dart add -t "Shopping List" -c "- Milk\\n- Bread\\n- Eggs"
```

### Creating a note with your editor
```bash
export EDITOR=nano
dart bin/jotdown.dart add -t "Meeting Notes" --editor
```

### Searching for notes
```bash
dart bin/jotdown.dart search -q "meeting"
dart bin/jotdown.dart search -q "TODO"
```

### Backing up notes to a custom location
```bash
dart bin/jotdown.dart settings --storage custom --custom-path ~/Dropbox/Notes
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
   echo "Meeting agenda" | dart bin/jotdown.dart add -t "Meeting" -c -
   ```

2. **Script integration**: Use in shell scripts for automation
   ```bash
   #!/bin/bash
   DATE=$(date +%Y-%m-%d)
   dart bin/jotdown.dart add -t "Daily Log $DATE" --editor
   ```

3. **Quick view**: List notes and pipe to grep for quick filtering
   ```bash
   dart bin/jotdown.dart list | grep -i "todo"
   ```

4. **Backup**: Export all notes to individual files
   ```bash
   # This functionality could be added as a future enhancement
   ```

The CLI provides full access to your jotDown data from the command line, perfect for automation, quick note-taking, and integration with other command-line tools.
