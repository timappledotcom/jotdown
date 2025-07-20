#!/bin/bash

# Build fixed jotDown v0.1.6 package with proper desktop integration
echo "Building jotDown v0.1.6 with desktop integration fixes..."

VERSION="0.1.6"

# Clean up
rm -rf packages/jotdown-v${VERSION}-fixed-*

# Create DEB package structure
DEB_DIR="jotdown-v${VERSION}-fixed"
mkdir -p ${DEB_DIR}/{opt/jotdown,usr/share/applications,usr/share/icons/hicolor/{16x16,32x32,48x48,64x64,128x128,256x256}/apps,DEBIAN}

# Copy Flutter application
cp -r build/linux/x64/release/bundle/* ${DEB_DIR}/opt/jotdown/

# Copy additional assets  
cp -r assets ${DEB_DIR}/opt/jotdown/
cp -r bin ${DEB_DIR}/opt/jotdown/

# Install desktop file with fixed StartupWMClass
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
Version: ${VERSION}-fixed
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

echo "jotDown installed successfully!"
echo ""
echo "The application should now appear with proper icon in:"
echo "  - Application menu/launcher"
echo "  - Dock/taskbar when running"
echo "  - Can be pinned to dock/taskbar"
echo ""
echo "Usage:"
echo "  Desktop app: Search for 'jotDown' in applications or run 'jotdown'"
echo "  CLI: Use 'jd' command in terminal"
echo ""
echo "Note: If icon issues persist, try logging out and back in."
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
dpkg-deb --build ${DEB_DIR} packages/jotdown-v${VERSION}-fixed-amd64.deb

# Clean up build directory
rm -rf ${DEB_DIR}

echo ""
echo "Fixed package created: packages/jotdown-v${VERSION}-fixed-amd64.deb"
echo ""
echo "Key fixes in this package:"
echo "  ✅ Correct StartupWMClass (com.example.jotdown)"
echo "  ✅ All icon sizes installed (16x16 to 256x256)"
echo "  ✅ Proper desktop database updates"
echo "  ✅ Enhanced post-install messaging"
echo ""
echo "Install with: sudo dpkg -i packages/jotdown-v${VERSION}-fixed-amd64.deb"
