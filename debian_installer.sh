#!/bin/bash

echo "========================================="
echo "YouTube Downloader Pro - Debian Installer"
echo "========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Package details
PACKAGE_NAME="youtube-downloader-pro"
VERSION="1.0.0"
PACKAGE_DIR="${PACKAGE_NAME}_${VERSION}"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo -e "${BLUE}[1/8] Checking dependencies...${NC}"

# Check required tools
if ! command_exists dpkg-deb; then
    echo -e "${YELLOW}Installing dpkg-deb...${NC}"
    sudo apt-get install -y dpkg-dev
fi

if ! command_exists python3; then
    echo -e "${RED}Python3 is required but not installed.${NC}"
    echo "Installing Python3..."
    sudo apt-get install -y python3 python3-pip python3-tk ffmpeg
fi

echo -e "${BLUE}[2/8] Creating package structure...${NC}"

# Clean previous build
rm -rf ${PACKAGE_DIR}
rm -f ${PACKAGE_NAME}_${VERSION}_all.deb

# Create directories
mkdir -p ${PACKAGE_DIR}/DEBIAN
mkdir -p ${PACKAGE_DIR}/usr/local/bin
mkdir -p ${PACKAGE_DIR}/usr/local/share/${PACKAGE_NAME}
mkdir -p ${PACKAGE_DIR}/usr/share/applications
mkdir -p ${PACKAGE_DIR}/usr/share/icons/hicolor/256x256/apps
mkdir -p ${PACKAGE_DIR}/usr/share/doc/${PACKAGE_NAME}

echo -e "${BLUE}[3/8] Creating control file...${NC}"

# Create control file
cat > ${PACKAGE_DIR}/DEBIAN/control << 'CONTROL'
Package: youtube-downloader-pro
Version: 1.0.0
Section: utils
Priority: optional
Architecture: all
Depends: python3 (>= 3.8), python3-pip, python3-tk, ffmpeg
Maintainer: User <user@example.com>
Description: YouTube Downloader Pro
 A modern GUI application to download YouTube videos
 in various qualities and formats.
Homepage: https://github.com/youtube-downloader-pro
CONTROL

echo -e "${BLUE}[4/8] Creating installation scripts...${NC}"

# Create post-installation script
cat > ${PACKAGE_DIR}/DEBIAN/postinst << 'POSTINST'
#!/bin/bash
set -e

echo "YouTube Downloader Pro - Post Installation Setup"

# Create virtual environment
cd /usr/local/share/youtube-downloader-pro
python3 -m venv venv
source venv/bin/activate

# Install Python packages
venv/bin/pip install --upgrade pip
venv/bin/pip install yt-dlp customtkinter

# Create downloads directory for the user
if [ -n "$SUDO_USER" ]; then
    DOWNLOAD_DIR="/home/$SUDO_USER/Downloads/YouTube Downloads"
    mkdir -p "$DOWNLOAD_DIR"
    chown -R $SUDO_USER:$SUDO_USER "$DOWNLOAD_DIR"
fi

# Make launcher executable
chmod +x /usr/local/bin/youtube-downloader

# Update icon cache
if command -v update-icon-caches >/dev/null 2>&1; then
    update-icon-caches /usr/share/icons/hicolor/
fi

# Update desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database /usr/share/applications/
fi

echo ""
echo "Installation completed successfully!"
echo "You can run 'youtube-downloader' from terminal or find it in applications menu"
echo ""

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

# Create post-removal script
cat > ${PACKAGE_DIR}/DEBIAN/postrm << 'POSTRM'
#!/bin/bash
# Clean up virtual environment
if [ -d "/usr/local/share/youtube-downloader-pro/venv" ]; then
    rm -rf /usr/local/share/youtube-downloader-pro/venv
fi
# Update icon cache
if command -v update-icon-caches >/dev/null 2>&1; then
    update-icon-caches /usr/share/icons/hicolor/
fi
echo "YouTube Downloader Pro has been removed"
exit 0
POSTRM

chmod +x ${PACKAGE_DIR}/DEBIAN/postrm

echo -e "${BLUE}[5/8] Copying application files...${NC}"

# Copy application files
if [ -d "app" ]; then
    cp -r app ${PACKAGE_DIR}/usr/local/share/${PACKAGE_NAME}/
fi

# Copy individual Python files if they exist
for file in gui.py backend.py main.py; do
    if [ -f "$file" ]; then
        cp "$file" ${PACKAGE_DIR}/usr/local/share/${PACKAGE_NAME}/
    fi
done

# If no app folder, create one
if [ ! -d "app" ] && [ -f "gui.py" ]; then
    mkdir -p ${PACKAGE_DIR}/usr/local/share/${PACKAGE_NAME}/app
    cp *.py ${PACKAGE_DIR}/usr/local/share/${PACKAGE_NAME}/app/ 2>/dev/null
fi

echo -e "${BLUE}[6/8] Creating launcher script...${NC}"

# Create launcher script
cat > ${PACKAGE_DIR}/usr/local/bin/youtube-downloader << 'LAUNCHER'
#!/bin/bash
cd /usr/local/share/youtube-downloader-pro

# Activate virtual environment and run
if [ -d "venv" ]; then
    source venv/bin/activate
    if [ -f "app/gui.py" ]; then
        python3 app/gui.py
    elif [ -f "gui.py" ]; then
        python3 gui.py
    else
        echo "Error: GUI file not found"
        exit 1
    fi
    deactivate
else
    echo "Error: Virtual environment not found"
    exit 1
fi
LAUNCHER

chmod +x ${PACKAGE_DIR}/usr/local/bin/youtube-downloader

echo -e "${BLUE}[7/8] Creating desktop entry and icon...${NC}"

# Download and use a proper PNG icon
echo "Downloading icon..."
wget -q -O ${PACKAGE_DIR}/usr/share/icons/hicolor/256x256/apps/youtube-downloader.png https://cdn-icons-png.flaticon.com/256/1384/1384060.png 2>/dev/null || {
    # If wget fails, create a simple PNG using Python
    python3 << 'PYICON'
import base64
png_data = base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAYAAADDPmHLAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAOxAAADsQBlSsOGwAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAATdSURBV4nO3dO6gWVRgG4EdEsDQIgiAoFhRBBVEURBFFEURRRFEUQRRFEAVRRFEUQRRFEEVRBFFEUQRRFEEURRAFUQRdLvoFBV5Lc87smT1n5nzPwvLAMjtnd77nP2dmz8wOIYQQQgghhBBCCCGEsA/cvA9gLd2IAegTDAPQJxgGoE8wDECfYBiAPsEwAH2CYQD6BMMA9AmGAegTDAPQJxgGoE8wDECfYBiAPsEwAH2CYQD6BMMA9AmGAegTDAPQJxgGoE8wDECfYBiAPsEwAH2CYQD6BMMA9AmGAegTDAPQJxgGoE8wDECfYBiAPsEwAH2CYQD6BMMA9AmGAegTDAPQJxgGoE8wDECfYBiAPsEwAH2CYQD6BMMA9AmGAegTDAPQJxgGoE8wDECfYBiAPsEwAH2CYQD6BMMA9AmGAegTDAPQJxgGoE8wDECfYBiAPsEwAH2CYQD6BMMA9AmGAegTDAPQJxgGoE8wDECfYBiAPsEwAH2CYQD6BMMA9AmGAegTDAPQJxgGoE8wDECfYBiAPsEwAH2CYQD6BMMA9AmGAegTDAPQJxgGoE8wDECfYBiAPsEwAH2CYQD6BMMA9AmGAegTDAPQJxgGoE8wDECfYBiAPsEwAH2CYQD6BMMA9Imn8+64mzE4eCbYp+aAkH2CYQD6BMMA9AmGAegTDAPQJxgGoE8wDECfYBiAPsEwAH2CYQD6BMMA9AmGAegTDAPQJxgGoE8wDECfYBiAPsEwAH2CYQD6BMMA9AmGAegTDAPQJxgGoE8wDECfYBiAPsEwAH2CYQD6BMMA9AmGAegTDAPQJxgGoE8wDECfYBiAPsEwAH2CYQD6BMMA9AmGAegTDAPQJxgGoE8wDECfYBiAPsEwAH2CYQD6BMMA9AmGAegTDAPQJxgGoE8wDECfYBiAPsEwAH2CYQD6BMMA9AmGAegTDAPQJxgGoE8wDECfYBiAPsEwAH2CYQD6BMMA9AmGAegTDAPQJxgGoE8wDECfYBiAPsEwAH2CYQD6BMMA9AmGAegTDAPQJxgGoE8wDECfYBiAPsEwAH2CYQD6BMMA9AmGAegTDAPQJxgGoE8wDECfYBiAPsEwAH2CYQD6BMMA9AmGAegTDAPQJxgGoE8wDECfYBiAPsEwAH2CYQD6BMMA9AmGAegTDAPQJxgGoE8wDECfYBiAPsEwAH2CYQD6BMMA9AmGAegTDAPQJxgGoE8wDECfYBiAPsEwAH2CYQD6BMMA9AmGAegTDAPQJxgGoE8wDECfYBiAPsEwAH2CYQD6BMMA9AmGAegTDAPQJxgGoE8wDECfYBiAPsE+8A5wOnAUcDfwIXA98BvwN/BgEwI7AfOAgYDEwP7vhL4FPgfuBh4B96fFtgHnA+sD0bL73gUeBO4AdgPfobO/GWcD2wLQ8phDnA/W/a7eJx/LqAd4B5uRxPA38l33/iU7+HcAxwFrvP5cCzwMnZD/+LgAb57EqcLKKwU5xEnBm9vNFwMlqKocryAJPAJeKeVwO9J5kq8D7wHI9gA+rpQ2TjxM7+aE3b/oF8Mq4RrbgG/XT0PVpM5dNOh+U9dQ/Z01qKp+O+2vW0P+CHgDmT3hM88C/Jv02dAYD0CcYBqBPMAxAn2AYgD7BMAB9gmEA+gTDAIQx/geg0fSyaqzmBwAAAABJRU5ErkJggg==')
with open('/usr/local/share/youtube-downloader-pro/youtube-icon.png', 'wb') as f:
    f.write(png_data)
PYICON
}

# Create desktop entry with correct icon path
cat > ${PACKAGE_DIR}/usr/share/applications/youtube-downloader.desktop << 'DESKTOP'
[Desktop Entry]
Version=1.0
Name=YouTube Downloader Pro
Comment=Download YouTube videos in high quality
Exec=youtube-downloader
Icon=youtube-downloader
Terminal=false
Type=Application
Categories=AudioVideo;Network;Downloader;
StartupNotify=true
Keywords=youtube;downloader;video;mp4;mp3;
MimeType=x-scheme-handler/https;
DESKTOP

# Create icon symlink for the icon
cat > ${PACKAGE_DIR}/usr/share/icons/hicolor/256x256/apps/youtube-downloader.png << 'PNGICON'
[This will be replaced by the downloaded icon]
PNGICON

# Actually download the icon properly
wget -O ${PACKAGE_DIR}/usr/share/icons/hicolor/256x256/apps/youtube-downloader.png https://cdn-icons-png.flaticon.com/256/1384/1384060.png 2>/dev/null || echo "Icon download skipped"

# Create documentation
cat > ${PACKAGE_DIR}/usr/share/doc/${PACKAGE_NAME}/README << 'README'
YouTube Downloader Pro

A modern GUI application to download YouTube videos in various qualities.

Features:
- Download videos in multiple qualities (1080p, 720p, 480p)
- Extract audio only (MP3)
- Pause and resume downloads
- Modern dark theme interface
- Real-time progress tracking

Usage:
- Run 'youtube-downloader' from terminal
- Or find in applications menu

Uninstall:
- sudo dpkg -r youtube-downloader-pro
README

echo -e "${BLUE}[8/8] Building and installing Debian package...${NC}"

# Build the package
dpkg-deb --build ${PACKAGE_DIR}

if [ -f "${PACKAGE_DIR}.deb" ]; then
    # Rename to standard format
    mv ${PACKAGE_DIR}.deb ${PACKAGE_NAME}_${VERSION}_all.deb
    
    echo -e "${GREEN}✓ Package created: ${PACKAGE_NAME}_${VERSION}_all.deb${NC}"
    echo -e "${GREEN}✓ Size: $(ls -lh ${PACKAGE_NAME}_${VERSION}_all.deb | awk '{print $5}')${NC}"
    
    # Install the package
    echo ""
    echo -e "${BLUE}Installing the package...${NC}"
    sudo dpkg -i ${PACKAGE_NAME}_${VERSION}_all.deb
    
    # Fix dependencies if needed
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}Fixing missing dependencies...${NC}"
        sudo apt-get install -f -y
    fi
    
    # Update icon cache
    sudo update-icon-caches /usr/share/icons/hicolor/ 2>/dev/null || true
    
    echo ""
    echo "========================================="
    echo -e "${GREEN}✅ Installation Complete!${NC}"
    echo "========================================="
    echo ""
    echo -e "${GREEN}YouTube Downloader Pro has been installed successfully!${NC}"
    echo ""
    echo "You can now:"
    echo "  1. Run from terminal: ${GREEN}youtube-downloader${NC}"
    echo "  2. Find in applications menu: ${GREEN}YouTube Downloader Pro${NC}"
    echo "  3. Pin to dock for easy access"
    echo ""
    echo "Download location: ~/Downloads/YouTube Downloads"
    echo ""
    echo "To uninstall: sudo dpkg -r ${PACKAGE_NAME}"
    echo ""
    
    # Ask if user wants to launch the app
    read -p "Launch YouTube Downloader Pro now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        youtube-downloader
    fi
else
    echo -e "${RED}❌ Error: Package build failed!${NC}"
    exit 1
fi

# Clean up build directory (optional)
read -p "Clean up build files? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf ${PACKAGE_DIR}
    echo "Cleanup complete."
fi
