#!/bin/bash

echo "========================================="
echo "YouTube Downloader Pro - Uninstaller"
echo "========================================="

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}This uninstaller will remove the SYSTEM-WIDE installation only.${NC}"
echo -e "${BLUE}Your source code in ~/Desktop/youtube-dl-app-final will NOT be deleted.${NC}"
echo ""

# Confirm uninstallation
read -p "Are you sure you want to uninstall YouTube Downloader Pro? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

# 1. Remove Debian package if installed
echo -e "${YELLOW}[1/6] Removing Debian package...${NC}"
if dpkg -l | grep -q youtube-downloader-pro; then
    sudo dpkg -r youtube-downloader-pro 2>/dev/null && echo "✓ Package removed"
else
    echo "✓ No Debian package found"
fi

# Remove other possible package names
sudo dpkg -r youtube-downloader 2>/dev/null
sudo dpkg -r youtube-dl 2>/dev/null

# 2. Remove desktop entries (system-wide and user)
echo -e "${YELLOW}[2/6] Removing desktop entries...${NC}"
# User desktop entries
rm -f ~/.local/share/applications/youtube-downloader.desktop
rm -f ~/Desktop/YouTube-Downloader.desktop
rm -f ~/Desktop/YouTube-Downloader-Pro.desktop
# System desktop entries
sudo rm -f /usr/share/applications/youtube-downloader.desktop
sudo rm -f /usr/share/pixmaps/youtube-downloader.xpm
echo "✓ Desktop entries removed"

# 3. Remove launcher scripts
echo -e "${YELLOW}[3/6] Removing launcher scripts...${NC}"
sudo rm -f /usr/local/bin/youtube-downloader
sudo rm -f /usr/local/bin/youtube-dl
rm -f ~/.local/bin/youtube-downloader
echo "✓ Launcher scripts removed"

# 4. Remove installed application files (system-wide)
echo -e "${YELLOW}[4/6] Removing installed application files...${NC}"
if [ -d "/usr/local/share/youtube-downloader-pro" ]; then
    sudo rm -rf /usr/local/share/youtube-downloader-pro
    echo "✓ System application files removed"
else
    echo "✓ No system application files found"
fi

# 5. Remove virtual environment (optional - keeps your source)
echo -e "${YELLOW}[5/6] Virtual environment...${NC}"
if [ -d "venv" ]; then
    read -p "Remove the virtual environment (venv) from source folder? This will require re-installing packages. (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf venv
        echo "✓ Virtual environment removed"
    else
        echo "✓ Virtual environment kept"
    fi
else
    echo "✓ No virtual environment found"
fi

# 6. Clean up system
echo -e "${YELLOW}[6/6] Cleaning system...${NC}"
sudo apt-get autoremove -y -q 2>/dev/null
sudo apt-get clean -q 2>/dev/null
echo "✓ System cleaned"

# Update desktop databases
update-desktop-database ~/.local/share/applications/ 2>/dev/null
sudo update-desktop-database /usr/share/applications/ 2>/dev/null

echo ""
echo "========================================="
echo -e "${GREEN}✅ Uninstallation completed!${NC}"
echo "========================================="
echo ""
echo -e "${BLUE}Your source code is still here:${NC}"
echo "  ~/Desktop/youtube-dl-app-final"
echo ""
echo -e "${BLUE}To run the app again from source:${NC}"
echo "  cd ~/Desktop/youtube-dl-app-final"
echo "  ./launch_app.sh"
echo ""
echo -e "${BLUE}To reinstall system-wide:${NC}"
echo "  cd ~/Desktop/youtube-dl-app-final"
echo "  ./debian_installer.sh"
echo ""
