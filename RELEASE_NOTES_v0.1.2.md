# jotDown v0.1.2 - Critical Bug Fixes

## 🔧 Critical Fixes

### Password Verification Bug (FIXED)
- **Issue**: Users were getting "Incorrect password" errors even when entering the correct password
- **Root Cause**: Salt mismatch between password setup and verification processes
- **Solution**: Fixed password salt handling to ensure consistent salt usage
- **Impact**: Users can now properly access their encrypted notes

### CLI Setup Issue (FIXED)
- **Issue**: The `jd` command was not available after installation
- **Root Cause**: Missing setup process for global CLI command
- **Solution**: Added automatic CLI setup scripts and installation documentation
- **Impact**: Users can now use the convenient `jd` command from anywhere

## 📦 Installation

### Quick Install
```bash
# Download and extract
wget https://github.com/timappledotcom/jotdown/releases/download/v0.1.2/jotdown-0.1.2-linux-x86_64.tar.gz
tar -xzf jotdown-0.1.2-linux-x86_64.tar.gz
cd jotdown

# Install (requires sudo for system installation)
sudo ./install.sh

# Test CLI
jd --help
jd list
```

### CLI Setup Only
If you already have jotDown installed but need to set up the CLI:
```bash
wget https://github.com/timappledotcom/jotdown/releases/download/v0.1.2/setup-cli.sh
chmod +x setup-cli.sh
sudo ./setup-cli.sh
```

## 🎯 What's New

### For Existing Users
- **Critical Security Fix**: If you were experiencing password issues, this update resolves them
- **Reset Script**: For users affected by the password bug, a reset script was provided to safely restore access

### For New Users
- **Complete Package**: Desktop app + CLI with automatic setup
- **Enhanced Documentation**: Comprehensive installation and usage guides
- **Improved CLI**: All examples now use the convenient `jd` command

## 📋 Technical Details

### Password System Changes
- Separated password verification salt from encryption salt
- Fixed `_enableEncryption()`, `_getSalt()`, and `_changePassword()` methods
- Added migration logic for existing installations

### CLI Improvements
- Added `setup-jd.sh` script for easy CLI configuration
- Updated all documentation to use `jd` command examples
- Created comprehensive installation guide (`INSTALL.md`)

## 📚 Documentation

The release includes comprehensive documentation:
- `README.md` - Main application documentation
- `CLI_README.md` - Complete CLI usage guide
- `INSTALL.md` - Installation troubleshooting
- `CHANGELOG.md` - Detailed version history

## 🐛 If You're Having Issues

### Password Problems (v0.1.1 users)
If you were affected by the password bug in v0.1.1, you may need to reset your encryption. The application will guide you through this process safely.

### CLI Not Working
Run the setup script from your jotDown installation:
```bash
cd /opt/jotdown  # or wherever jotDown is installed
sudo ./bin/setup-jd.sh
```

## 🔄 Upgrade Path

### From v0.1.1
1. Download v0.1.2
2. Install over existing installation
3. Your notes and settings are preserved
4. Password issues are automatically resolved

### From v0.1.0
- Full upgrade recommended
- Export notes before upgrading if desired
- Fresh installation provides all new features

---

This release focuses on stability and usability. The password verification bug was critical and affected user access to encrypted notes. The CLI setup improvements make jotDown much easier to use from the command line.

Thank you for your patience with these issues!
