#!/bin/bash

# Build complete jotDown v0.1.7 with desktop integration fixes
echo "Building jotDown v0.1.7 - Desktop Integration Fixes"

VERSION="0.1.7"

# Clean up old packages
rm -rf packages/jotdown-v${VERSION}*
mkdir -p packages

echo "🏗️  Building DEB package..."

# Create DEB package structure
DEB_DIR="jotdown-v${VERSION}"
mkdir -p ${DEB_DIR}/{opt/jotdown,usr/share/applications,usr/share/icons/hicolor/{16x16,32x32,48x48,64x64,128x128,256x256}/apps,DEBIAN}

# Copy Flutter application
cp -r build/linux/x64/release/bundle/* ${DEB_DIR}/opt/jotdown/

# Copy additional assets  
cp -r assets ${DEB_DIR}/opt/jotdown/
cp -r bin ${DEB_DIR}/opt/jotdown/

# Install desktop file with correct StartupWMClass
cp assets/jotdown.desktop ${DEB_DIR}/usr/share/applications/

# Install all icon sizes for proper desktop integration
cp assets/icons/jotdown-16.png ${DEB_DIR}/usr/share/icons/hicolor/16x16/apps/jotdown.png
cp assets/icons/jotdown-32.png ${DEB_DIR}/usr/share/icons/hicolor/32x32/apps/jotdown.png
cp assets/icons/jotdown-48.png ${DEB_DIR}/usr/share/icons/hicolor/48x48/apps/jotdown.png
cp assets/icons/jotdown-64.png ${DEB_DIR}/usr/share/icons/hicolor/64x64/apps/jotdown.png
cp assets/icons/jotdown-128.png ${DEB_DIR}/usr/share/icons/hicolor/128x128/apps/jotdown.png
cp assets/icons/jotdown-256.png ${DEB_DIR}/usr/share/icons/hicolor/256x256/apps/jotdown.png

# Create control file
cat > ${DEB_DIR}/DEBIAN/control << EOF
Package: jotdown
Version: ${VERSION}
Section: text
Priority: optional
Architecture: amd64
Maintainer: Tim Apple <tim@timapple.com>
Description: A markdown-based note taking application
 jotDown is a simple, elegant note-taking application that supports
 markdown formatting. It includes both desktop and CLI interfaces
 for maximum productivity with proper desktop integration.
EOF

# Create enhanced post-install script
cat > ${DEB_DIR}/DEBIAN/postinst << 'EOF'
#!/bin/bash

echo "Setting up jotDown CLI..."
if [ -f /opt/jotdown/bin/setup-jd.sh ]; then
    chmod +x /opt/jotdown/bin/setup-jd.sh
    /opt/jotdown/bin/setup-jd.sh
fi

echo "Setting up jotDown GUI..."
ln -sf /opt/jotdown/jotdown /usr/local/bin/jotdown

echo "Setting up desktop integration..."

# Update desktop database
if [ -x /usr/bin/update-desktop-database ]; then
    /usr/bin/update-desktop-database -q /usr/share/applications
fi

# Update icon cache for proper icon display in dock/taskbar
if [ -x /usr/bin/gtk-update-icon-cache ]; then
    /usr/bin/gtk-update-icon-cache -f -q /usr/share/icons/hicolor
fi

# Update mime database
if [ -x /usr/bin/update-mime-database ]; then
    /usr/bin/update-mime-database /usr/share/mime
fi

echo "jotDown v0.1.7 installed successfully!"
echo ""
echo "🎉 Desktop Integration Fixes:"
echo "  ✅ Proper icon display in dock/taskbar"
echo "  ✅ Can be pinned to dock/taskbar"
echo "  ✅ Correct application identification"
echo ""
echo "Usage:"
echo "  Desktop app: Search for 'jotDown' in applications or run 'jotdown'"
echo "  CLI: Use 'jd' command in terminal"
EOF

chmod +x ${DEB_DIR}/DEBIAN/postinst

# Create post-removal script
cat > ${DEB_DIR}/DEBIAN/postrm << 'EOF'
#!/bin/bash

# Remove symlinks
rm -f /usr/local/bin/jotdown
rm -f /usr/local/bin/jd

# Update desktop database
if [ -x /usr/bin/update-desktop-database ]; then
    /usr/bin/update-desktop-database -q /usr/share/applications
fi

# Update icon cache
if [ -x /usr/bin/gtk-update-icon-cache ]; then
    /usr/bin/gtk-update-icon-cache -f -q /usr/share/icons/hicolor
fi

echo "jotDown removed."
EOF

chmod +x ${DEB_DIR}/DEBIAN/postrm

# Create pre-removal script
cat > ${DEB_DIR}/DEBIAN/prerm << 'EOF'
#!/bin/bash

# Stop any running instances
pkill -f jotdown || true
sleep 1

echo "Preparing to remove jotDown..."
EOF

chmod +x ${DEB_DIR}/DEBIAN/prerm

# Build DEB package
dpkg-deb --build ${DEB_DIR} packages/jotdown-v${VERSION}-amd64.deb

echo "📦 DEB package: $(ls -lh packages/jotdown-v${VERSION}-amd64.deb | awk '{print $5}')"

echo "🏗️  Building TAR.XZ archive..."

# Create portable archive
ARCHIVE_DIR="jotdown-v${VERSION}-linux-x64"
mkdir -p ${ARCHIVE_DIR}

# Copy application files
cp -r build/linux/x64/release/bundle/* ${ARCHIVE_DIR}/
cp -r assets ${ARCHIVE_DIR}/
cp -r bin ${ARCHIVE_DIR}/
cp scripts/install.sh ${ARCHIVE_DIR}/

# Create archive
tar -cJf packages/jotdown-v${VERSION}-linux-x64.tar.xz ${ARCHIVE_DIR}/

echo "📦 TAR.XZ archive: $(ls -lh packages/jotdown-v${VERSION}-linux-x64.tar.xz | awk '{print $5}')"

echo "🏗️  Building RPM package..."

# Convert DEB to RPM
if command -v alien >/dev/null 2>&1; then
    cd packages
    sudo alien --to-rpm jotdown-v${VERSION}-amd64.deb
    if [ -f jotdown-${VERSION}-2.x86_64.rpm ]; then
        mv jotdown-${VERSION}-2.x86_64.rpm jotdown-v${VERSION}-x86_64.rpm
        echo "📦 RPM package: $(ls -lh jotdown-v${VERSION}-x86_64.rpm | awk '{print $5}')"
    fi
    cd ..
else
    echo "⚠️  alien not found, skipping RPM package"
fi

echo "🏗️  Building AppImage..."

# Create AppImage if tool is available
if [ -f "./appimagetool.AppImage" ]; then
    APPDIR="JotDown.AppDir"
    mkdir -p ${APPDIR}/usr/{bin,lib,share/applications,share/icons/hicolor/256x256/apps}
    
    # Copy application
    cp -r build/linux/x64/release/bundle/* ${APPDIR}/usr/bin/
    mv ${APPDIR}/usr/bin/jotdown ${APPDIR}/usr/bin/jotdown-bin
    
    # Create wrapper script
    cat > ${APPDIR}/usr/bin/jotdown << 'EOF'
#!/bin/bash
APPDIR="$(dirname "$(readlink -f "${0}")")/../.."
export LD_LIBRARY_PATH="${APPDIR}/usr/lib:${LD_LIBRARY_PATH}"
exec "${APPDIR}/usr/bin/jotdown-bin" "$@"
EOF
    chmod +x ${APPDIR}/usr/bin/jotdown
    
    # Copy desktop file and icon
    cp assets/jotdown.desktop ${APPDIR}/jotdown.desktop
    cp assets/jotdown.desktop ${APPDIR}/usr/share/applications/
    cp assets/icons/jotdown-256.png ${APPDIR}/usr/share/icons/hicolor/256x256/apps/jotdown.png
    cp assets/icons/jotdown-256.png ${APPDIR}/jotdown.png
    
    # Create AppRun
    cat > ${APPDIR}/AppRun << 'EOF'
#!/bin/bash
APPDIR="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="${APPDIR}/usr/lib:${LD_LIBRARY_PATH}"
exec "${APPDIR}/usr/bin/jotdown" "$@"
EOF
    chmod +x ${APPDIR}/AppRun
    
    # Build AppImage
    ./appimagetool.AppImage ${APPDIR} packages/JotDown-v${VERSION}-x86_64.AppImage
    
    if [ -f packages/JotDown-v${VERSION}-x86_64.AppImage ]; then
        chmod +x packages/JotDown-v${VERSION}-x86_64.AppImage
        echo "📦 AppImage: $(ls -lh packages/JotDown-v${VERSION}-x86_64.AppImage | awk '{print $5}')"
    fi
    
    rm -rf ${APPDIR}
else
    echo "⚠️  appimagetool not found, skipping AppImage"
fi

# Clean up build directories
rm -rf ${DEB_DIR} ${ARCHIVE_DIR}

echo ""
echo "🎉 jotDown v${VERSION} packages built successfully!"
echo ""
echo "📋 Package Summary:"
ls -lh packages/jotdown-v${VERSION}* packages/JotDown-v${VERSION}* 2>/dev/null || true
echo ""
echo "Key improvements in v${VERSION}:"
echo "  🔧 Fixed StartupWMClass for proper dock integration"
echo "  🎨 Complete icon set (16x16 to 256x256)"
echo "  📱 Proper desktop environment recognition"
echo "  🔗 Enhanced installation scripts"
