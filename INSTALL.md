# jotDown Installation Guide

## After Installing jotDown

### Setting up the CLI Command

To use the convenient `jd` command from anywhere in your terminal:

1. **Navigate to your installation directory** (usually `/opt/jotdown`):
   ```bash
   cd /opt/jotdown
   ```

2. **Run the setup script**:
   ```bash
   sudo ./bin/setup-jd.sh
   ```

3. **Test the setup**:
   ```bash
   jd --help
   jd list
   ```

### Manual Setup (Alternative)

If the setup script doesn't work, create the symlink manually:

```bash
# Create symlink
sudo ln -s /opt/jotdown/bin/jd /usr/local/bin/jd

# Test
jd --help
```

### Using Without Global Setup

You can always use the CLI directly without setting up the global command:

```bash
# Direct usage
cd /opt/jotdown
./bin/jd --help

# Or with full path
dart /opt/jotdown/bin/jotdown.dart --help
```

## Troubleshooting

### Command Not Found
- Make sure `/usr/local/bin` is in your PATH
- Check if the symlink exists: `ls -la /usr/local/bin/jd`
- Verify jotDown installation: `ls /opt/jotdown/bin/jd`

### Permission Denied
- Make sure the setup script is executable: `chmod +x /opt/jotdown/bin/setup-jd.sh`
- Run with sudo: `sudo ./bin/setup-jd.sh`

### Can't Find jotDown Installation
The setup script looks for jotDown in these locations:
- `/opt/jotdown/`
- `/usr/local/jotdown/`
- `/usr/share/jotdown/`
- `~/.local/share/jotdown/`
- `~/Applications/jotdown/`

If installed elsewhere, create symlink manually using the correct path.

## Quick Start

Once setup is complete:

```bash
# List notes
jd list

# Add a note
jd add -t "My First Note" -c "Hello from the command line!"

# Search notes
jd search -q "hello"

# View a note (use ID from list command)
jd view --id 1234567890

# Get help
jd --help
```

## More Information

- Full CLI documentation: See `CLI_README.md`
- Desktop application: Launch "jotDown" from applications menu
- Project repository: https://github.com/timappledotcom/jotdown
