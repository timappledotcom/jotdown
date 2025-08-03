#!/bin/bash

# jotDown v0.2.1 Release Build Script
# This script builds all package formats for the release

set -e  # Exit on any error

VERSION="0.2.1"
APP_NAME="jotdown"
BUILD_DIR="build_release"
RELEASE_DIR="release_packages"

echo "🚀 Building jotDown v${VERSION} Release Packages"
echo "================================================"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
rm -rf $BUILD_DIR
rm -rf $RELEASE_DIR
mkdir -p $BUILD_DIR
mkdir -p $RELEASE_DIR

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Run code generation
echo "🔨 Running code generation..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Build Linux release
echo "🏗️  Building Linux release..."
flutter build linux --release

# Create build directory structure
echo "📁 Creating package structure..."
cp -r build/linux/x64/release/bundle $BUILD_DIR/${APP_NAME}-v${VERSION}-linux-x64

# Copy additional files
cp README.md $BUILD_DIR/${APP_NAME}-v${VERSION}-linux-x64/
cp CHANGELOG.md $BUILD_DIR/${APP_NAME}-v${VERSION}-linux-x64/
cp LICENSE $BUILD_DIR/${APP_NAME}-v${VERSION}-linux-x64/
cp CLI_README.md $BUILD_DIR/${APP_NAME}-v${VERSION}-linux-x64/
cp FLAT_FILE_STORAGE.md $BUILD_DIR/${APP_NAME}-v${VERSION}-linux-x64/
cp MIGRATION_GUIDE.md $BUILD_DIR/${APP_NAME}-v${VERSION}-linux-x64/
cp RELEASE_v${VERSION}.md $BUILD_DIR/${APP_NAME}-v${VERSION}-linux-x64/

# Copy CLI wrapper and setup scripts
mkdir -p $BUILD_DIR/${APP_NAME}-v${VERSION}-linux-x64/bin
cp bin/jd $BUILD_DIR/${APP_NAME}-v${VERSION}-linux-x64/bin/
cp bin/jotdown.dart $BUILD_DIR/${APP_NAME}-v${VERSION}-linux-x64/bin/

# Create setup script
cat > $BUILD_DIR/${APP_NAME}-v${VERSION}-linux-x64/bin/setup-jd.sh << 'EOF'
#!/bin/bash
# jotDown CLI Setup Script

echo "Setting up jotDown CLI command 'jd'..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
INSTALL_DIR="$(dirname "$SCRIPT_DIR")"

# Create symlink
ln -sf "$SCRIPT_DIR/jd" /usr/local/bin/jd

echo "✅ jotDown CLI setup complete!"
echo "You can now use 'jd --help' to get started."
EOF

chmod +x $BUILD_DIR/${APP_NAME}-v${VERSION}-linux-x64/bin/setup-jd.sh

# Create install script
cat > $BUILD_DIR/${APP_NAME}-v${VERSION}-linux-x64/install.sh << 'EOF'
#!/bin/bash
# jotDown Installation Script

echo "🚀 Installing jotDown v0.2.1..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
INSTALL_DIR="/opt/jotdown"

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Copy files
echo "📁 Copying files to $INSTALL_DIR..."
cp -r "$SCRIPT_DIR"/* "$INSTALL_DIR/"

# Create desktop entry
cat > /usr/share/applications/jotdown.desktop << 'DESKTOP_EOF'
[Desktop Entry]
Name=jotDown
Comment=Simple and elegant notes application
Exec=/opt/jotdown/jotdown
Icon=/opt/jotdown/data/flutter_assets/assets/icons/jotdown.png
Terminal=false
Type=Application
Categories=Office;TextEditor;
StartupWMClass=jotdown
DESKTOP_EOF

# Set up CLI command
ln -sf "$INSTALL_DIR/bin/jd" /usr/local/bin/jd

# Set permissions
chmod +x "$INSTALL_DIR/jotdown"
chmod +x "$INSTALL_DIR/bin/jd"
chmod +x "$INSTALL_DIR/bin/setup-jd.sh"

echo "✅ jotDown installation complete!"
echo ""
echo "🖥️  Launch GUI: jotdown (or from application menu)"
echo "⌨️  CLI usage: jd --help"
echo "📖 Documentation: $INSTALL_DIR/README.md"
EOF

chmod +x $BUILD_DIR/${APP_NAME}-v${VERSION}-linux-x64/install.sh

# Create TAR.XZ archive
echo "📦 Creating TAR.XZ archive..."
cd $BUILD_DIR
tar -cJf ../$RELEASE_DIR/${APP_NAME}-v${VERSION}-linux-x64.tar.xz ${APP_NAME}-v${VERSION}-linux-x64/
cd ..

# Create DEB package structure
echo "📦 Creating DEB package..."
DEB_DIR="$BUILD_DIR/${APP_NAME}-deb"
mkdir -p $DEB_DIR/DEBIAN
mkdir -p $DEB_DIR/opt/jotdown
mkdir -p $DEB_DIR/usr/share/applications
mkdir -p $DEB_DIR/usr/local/bin

# Copy files for DEB
cp -r $BUILD_DIR/${APP_NAME}-v${VERSION}-linux-x64/* $DEB_DIR/opt/jotdown/

# Create DEB control file
cat > $DEB_DIR/DEBIAN/control << EOF
Package: jotdown
Version: ${VERSION}
Section: text
Priority: optional
Architecture: amd64
Depends: libgtk-3-0, libglib2.0-0
Maintainer: jotDown Team <contact@jotdown.app>
Description: Simple and elegant notes application for Linux
 jotDown is a beautiful, feature-rich notes application that combines
 the power of Markdown with both desktop GUI and command-line interfaces.
 Features include flat file storage, Ubuntu Yaru theming, encryption,
 and seamless CLI/GUI integration.
Homepage: https://github.com/timappledotcom/jotdown
EOF

# Create DEB postinst script
cat > $DEB_DIR/DEBIAN/postinst << 'EOF'
#!/bin/bash
set -e

# Create symlink for CLI
ln -sf /opt/jotdown/bin/jd /usr/local/bin/jd

# Create desktop entry
cat > /usr/share/applications/jotdown.desktop << 'DESKTOP_EOF'
[Desktop Entry]
Name=jotDown
Comment=Simple and elegant notes application
Exec=/opt/jotdown/jotdown
Icon=/opt/jotdown/data/flutter_assets/assets/icons/jotdown.png
Terminal=false
Type=Application
Categories=Office;TextEditor;
StartupWMClass=jotdown
DESKTOP_EOF

# Update desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database /usr/share/applications
fi

echo "✅ jotDown installation complete!"
echo "🖥️  Launch GUI: jotdown (or from application menu)"
echo "⌨️  CLI usage: jd --help"
EOF

chmod +x $DEB_DIR/DEBIAN/postinst

# Create DEB prerm script
cat > $DEB_DIR/DEBIAN/prerm << 'EOF'
#!/bin/bash
set -e

# Remove symlink
rm -f /usr/local/bin/jd

# Remove desktop entry
rm -f /usr/share/applications/jotdown.desktop

# Update desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database /usr/share/applications
fi
EOF

chmod +x $DEB_DIR/DEBIAN/prerm

# Build DEB package
dpkg-deb --build $DEB_DIR $RELEASE_DIR/${APP_NAME}-v${VERSION}-amd64.deb

# Create RPM spec file and build (if rpmbuild is available)
if command -v rpmbuild >/dev/null 2>&1; then
    echo "📦 Creating RPM package..."
    
    RPM_DIR="$BUILD_DIR/rpm"
    mkdir -p $RPM_DIR/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
    
    # Create source tarball for RPM
    tar -czf $RPM_DIR/SOURCES/${APP_NAME}-${VERSION}.tar.gz -C $BUILD_DIR ${APP_NAME}-v${VERSION}-linux-x64
    
    # Create RPM spec file
    cat > $RPM_DIR/SPECS/${APP_NAME}.spec << EOF
Name:           jotdown
Version:        ${VERSION}
Release:        1%{?dist}
Summary:        Simple and elegant notes application for Linux
License:        MIT
URL:            https://github.com/timappledotcom/jotdown
Source0:        %{name}-%{version}.tar.gz
BuildArch:      x86_64

Requires:       gtk3, glib2

%description
jotDown is a beautiful, feature-rich notes application that combines
the power of Markdown with both desktop GUI and command-line interfaces.
Features include flat file storage, Ubuntu Yaru theming, encryption,
and seamless CLI/GUI integration.

%prep
%setup -q -n ${APP_NAME}-v${VERSION}-linux-x64

%install
mkdir -p %{buildroot}/opt/jotdown
mkdir -p %{buildroot}/usr/local/bin
mkdir -p %{buildroot}/usr/share/applications

cp -r * %{buildroot}/opt/jotdown/
ln -sf /opt/jotdown/bin/jd %{buildroot}/usr/local/bin/jd

cat > %{buildroot}/usr/share/applications/jotdown.desktop << 'DESKTOP_EOF'
[Desktop Entry]
Name=jotDown
Comment=Simple and elegant notes application
Exec=/opt/jotdown/jotdown
Icon=/opt/jotdown/data/flutter_assets/assets/icons/jotdown.png
Terminal=false
Type=Application
Categories=Office;TextEditor;
StartupWMClass=jotdown
DESKTOP_EOF

%files
/opt/jotdown/*
/usr/local/bin/jd
/usr/share/applications/jotdown.desktop

%post
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database /usr/share/applications
fi

%postun
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database /usr/share/applications
fi

%changelog
* $(date +'%a %b %d %Y') jotDown Team <contact@jotdown.app> - ${VERSION}-1
- Updated to Yaru 8.1.0 and Flutter 3.32.8
- Enhanced flat file storage with individual .md files
- Improved Ubuntu integration and performance
- Fixed null safety issues and enhanced stability
EOF

    # Build RPM
    rpmbuild --define "_topdir $PWD/$RPM_DIR" -ba $RPM_DIR/SPECS/${APP_NAME}.spec
    cp $RPM_DIR/RPMS/x86_64/${APP_NAME}-${VERSION}-1.*.rpm $RELEASE_DIR/${APP_NAME}-v${VERSION}-x86_64.rpm
else
    echo "⚠️  rpmbuild not available, skipping RPM package creation"
fi

# Create AppImage (if appimagetool is available)
if command -v appimagetool >/dev/null 2>&1; then
    echo "📦 Creating AppImage..."
    
    APPDIR="$BUILD_DIR/JotDown.AppDir"
    mkdir -p $APPDIR
    
    # Copy application
    cp -r $BUILD_DIR/${APP_NAME}-v${VERSION}-linux-x64/* $APPDIR/
    
    # Create AppRun script
    cat > $APPDIR/AppRun << 'EOF'
#!/bin/bash
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="${HERE}:${PATH}"
exec "${HERE}/jotdown" "$@"
EOF
    chmod +x $APPDIR/AppRun
    
    # Create desktop file
    cat > $APPDIR/jotdown.desktop << 'EOF'
[Desktop Entry]
Name=jotDown
Comment=Simple and elegant notes application
Exec=jotdown
Icon=jotdown
Terminal=false
Type=Application
Categories=Office;TextEditor;
EOF
    
    # Create icon (placeholder - you should add a proper icon)
    mkdir -p $APPDIR/usr/share/icons/hicolor/256x256/apps
    # cp assets/icons/jotdown.png $APPDIR/jotdown.png  # Uncomment when icon is available
    
    # Build AppImage
    appimagetool $APPDIR $RELEASE_DIR/JotDown-v${VERSION}-x86_64.AppImage
else
    echo "⚠️  appimagetool not available, skipping AppImage creation"
fi

# Create checksums
echo "🔐 Creating checksums..."
cd $RELEASE_DIR
sha256sum * > SHA256SUMS
cd ..

# Display results
echo ""
echo "✅ Release packages created successfully!"
echo "📦 Packages available in: $RELEASE_DIR/"
echo ""
ls -lh $RELEASE_DIR/
echo ""
echo "🚀 Ready for upload to GitHub Releases!"

# Create GitHub release script
cat > create_github_release.sh << 'EOF'
#!/bin/bash

# GitHub Release Creation Script for jotDown v0.2.1
# This script creates a GitHub release and uploads the packages

VERSION="0.2.1"
REPO="timappledotcom/jotdown"
RELEASE_DIR="release_packages"

echo "🚀 Creating GitHub Release for jotDown v${VERSION}"
echo "================================================"

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub CLI."
    echo "Please run: gh auth login"
    exit 1
fi

# Create the release
echo "📝 Creating release..."
gh release create "v${VERSION}" \
    --repo "$REPO" \
    --title "jotDown v${VERSION} - Latest Yaru Theme & Enhanced Flat File Storage" \
    --notes-file "RELEASE_v${VERSION}.md" \
    --draft

# Upload packages
echo "📦 Uploading packages..."
if [ -d "$RELEASE_DIR" ]; then
    for file in $RELEASE_DIR/*; do
        if [ -f "$file" ]; then
            echo "⬆️  Uploading $(basename "$file")..."
            gh release upload "v${VERSION}" "$file" --repo "$REPO"
        fi
    done
else
    echo "❌ Release directory not found. Please run build_release.sh first."
    exit 1
fi

echo ""
echo "✅ GitHub release created successfully!"
echo "🌐 View at: https://github.com/$REPO/releases/tag/v${VERSION}"
echo ""
echo "📝 Next steps:"
echo "1. Review the draft release on GitHub"
echo "2. Edit release notes if needed"
echo "3. Publish the release"
EOF

chmod +x create_github_release.sh

echo ""
echo "📝 To create GitHub release:"
echo "   ./create_github_release.sh"
echo ""
echo "🔧 Manual upload instructions:"
echo "1. Go to: https://github.com/timappledotcom/jotdown/releases/new"
echo "2. Tag: v${VERSION}"
echo "3. Title: jotDown v${VERSION} - Latest Yaru Theme & Enhanced Flat File Storage"
echo "4. Upload files from: $RELEASE_DIR/"
echo "5. Copy release notes from: RELEASE_v${VERSION}.md"