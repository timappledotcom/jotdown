Name:           jotdown
Version:        0.2.0
Release:        1%{?dist}
Summary:        Simple and elegant notes application for Linux

License:        MIT
URL:            https://github.com/timappledotcom/jotdown
Source0:        %{name}-%{version}.tar.gz

BuildArch:      x86_64
Requires:       glibc, gtk3, glib2

%description
jotDown is a beautiful, feature-rich notes application for Linux that combines
the power of Markdown with the convenience of both a desktop GUI and command-line
interface. Whether you prefer clicking or typing, jotDown adapts to your workflow.

Features:
- Modern Ubuntu-native design with Yaru theming
- Hierarchical tag sidebar for advanced note organization
- Documents folder storage for easy file system access
- Markdown support with live preview
- Command-line interface for automation
- Encryption support for sensitive notes
- Multiple storage locations (Documents, Home, Custom)
- Cross-platform compatibility

%prep
%setup -q

%build
# No build needed, pre-compiled Flutter app

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/opt/jotdown
mkdir -p $RPM_BUILD_ROOT/usr/share/applications
mkdir -p $RPM_BUILD_ROOT/usr/local/bin

cp -r * $RPM_BUILD_ROOT/opt/jotdown/

# Create desktop file
cat > $RPM_BUILD_ROOT/usr/share/applications/jotdown.desktop << EOF
[Desktop Entry]
Name=jotDown
Comment=Simple and elegant notes application
Exec=/opt/jotdown/jotdown
Icon=/opt/jotdown/data/flutter_assets/assets/icons/jotdown.svg
Terminal=false
Type=Application
Categories=Office;TextEditor;Utility;
Keywords=notes;markdown;text;editor;cli;
StartupNotify=true
StartupWMClass=jotdown
EOF

# Create CLI symlink
ln -sf /opt/jotdown/bin/jd $RPM_BUILD_ROOT/usr/local/bin/jd

%files
/opt/jotdown/*
/usr/share/applications/jotdown.desktop
/usr/local/bin/jd

%changelog
* Thu Aug 01 2024 Tim Apple <tim@timapple.com> - 0.2.0-1
- Added hierarchical tag sidebar with advanced filtering
- Added Documents folder storage option
- Added Ubuntu Yaru theming
- Enhanced tag navigation and organization
- Improved user experience and performance