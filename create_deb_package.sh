#!/bin/bash

echo "========================================="
echo "Creating Debian Package for YouTube Downloader"
echo "========================================="

# Package details
PACKAGE_NAME="youtube-downloader-pro"
VERSION="1.0.0"
PACKAGE_DIR="${PACKAGE_NAME}_${VERSION}"

echo "1. Creating directory structure..."

# Create directories
mkdir -p ${PACKAGE_DIR}/DEBIAN
mkdir -p ${PACKAGE_DIR}/usr/local/bin
mkdir -p ${PACKAGE_DIR}/usr/local/share/${PACKAGE_NAME}
mkdir -p ${PACKAGE_DIR}/usr/share/applications
mkdir -p ${PACKAGE_DIR}/usr/share/pixmaps

echo "2. Creating control file..."

# Create control file
cat > ${PACKAGE_DIR}/DEBIAN/control << 'CONTROL'
Package: youtube-downloader-pro
Version: 1.0.0
Section: utils
Priority: optional
Architecture: all
Depends: python3, python3-pip, python3-tk, ffmpeg
Maintainer: User <user@example.com>
Description: YouTube Downloader Pro
 A modern GUI application to download YouTube videos
 in various qualities and formats.
Homepage: https://github.com/youtube-downloader-pro
CONTROL

echo "3. Creating installation scripts..."

# Create post-installation script
cat > ${PACKAGE_DIR}/DEBIAN/postinst << 'POSTINST'
#!/bin/bash
set -e

echo "YouTube Downloader Pro - Post Installation Setup"

# Install Python packages
pip3 install --user yt-dlp customtkinter

echo "Installation completed successfully!"
echo "You can run 'youtube-downloader' from terminal or find it in applications menu"

exit 0
POSTINST

chmod +x ${PACKAGE_DIR}/DEBIAN/postinst

# Create pre-removal script
cat > ${PACKAGE_DIR}/DEBIAN/prerm << 'PRERM'
#!/bin/bash
echo "Removing YouTube Downloader Pro..."
exit 0
PRERM

chmod +x ${PACKAGE_DIR}/DEBIAN/prerm

echo "4. Copying application files..."

# Copy application files
cp -r app ${PACKAGE_DIR}/usr/local/share/${PACKAGE_NAME}/
cp gui.py ${PACKAGE_DIR}/usr/local/share/${PACKAGE_NAME}/ 2>/dev/null || echo "gui.py already in app folder"
cp backend.py ${PACKAGE_DIR}/usr/local/share/${PACKAGE_NAME}/ 2>/dev/null || echo "backend.py already in app folder"

# Verify files were copied
echo "Files copied to ${PACKAGE_DIR}:"
ls -la ${PACKAGE_DIR}/usr/local/share/${PACKAGE_NAME}/

echo "5. Creating launcher script..."

# Create launcher script
cat > ${PACKAGE_DIR}/usr/local/bin/youtube-downloader << 'LAUNCHER'
#!/bin/bash
cd /usr/local/share/youtube-downloader-pro
python3 app/gui.py
LAUNCHER

chmod +x ${PACKAGE_DIR}/usr/local/bin/youtube-downloader

echo "6. Creating desktop entry..."

# Create desktop entry
cat > ${PACKAGE_DIR}/usr/share/applications/youtube-downloader.desktop << 'DESKTOP'
[Desktop Entry]
Name=YouTube Downloader Pro
Comment=Download YouTube videos in high quality
Exec=youtube-downloader
Icon=youtube-downloader
Terminal=false
Type=Application
Categories=AudioVideo;Network;Downloader;
StartupNotify=true
Keywords=youtube;downloader;video;
DESKTOP

echo "7. Creating icon..."

# Create simple icon
cat > ${PACKAGE_DIR}/usr/share/pixmaps/youtube-downloader.xpm << 'XPM'
/* XPM */
static char *youtube_downloader[] = {
"32 32 2 1",
". c #FF0000",
"  c #FFFFFF",
"                                ",
"       .................       ",
"     ...................       ",
"    .....................      ",
"   .......................     ",
"  .........................    ",
"  .........................    ",
"  .........................    ",
"  .........................    ",
"   .......................     ",
"    .....................      ",
"     ...................       ",
"       .................       ",
"                                ",
"          ...........          ",
"        ...............        ",
"      ...................      ",
"    .......................    ",
"  ...........................  ",
"                                "
};
XPM

echo "8. Building Debian package..."

# Build the package
dpkg-deb --build ${PACKAGE_DIR}

# Check if build was successful
if [ -f "${PACKAGE_DIR}.deb" ]; then
    # Rename to standard format
    mv ${PACKAGE_DIR}.deb ${PACKAGE_NAME}_${VERSION}_all.deb
    
    echo ""
    echo "========================================="
    echo "✅ SUCCESS! Package created successfully!"
    echo "========================================="
    echo ""
    echo "Package file: ${PACKAGE_NAME}_${VERSION}_all.deb"
    echo "Size: $(ls -lh ${PACKAGE_NAME}_${VERSION}_all.deb | awk '{print $5}')"
    echo ""
    echo "To install the package, run:"
    echo "  sudo dpkg -i ${PACKAGE_NAME}_${VERSION}_all.deb"
    echo "  sudo apt-get install -f"
    echo ""
    echo "To uninstall:"
    echo "  sudo dpkg -r ${PACKAGE_NAME}"
    echo ""
else
    echo "❌ Error: Package build failed!"
    exit 1
fi

echo "9. Cleaning up..."
# Keep the .deb file, remove build directory
# rm -rf ${PACKAGE_DIR}

echo "Done!"
