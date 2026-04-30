# 1. Remove Debian package if installed
chmod +x uninstaller.sh
sudo dpkg -r youtube-downloader-pro 2>/dev/null
sudo dpkg -r youtube-downloader 2>/dev/null
sudo dpkg -r youtube-dl 2>/dev/null

# 2. Remove desktop entries
rm -f ~/.local/share/applications/youtube-downloader.desktop
rm -f ~/Desktop/YouTube-Downloader.desktop
rm -f ~/Desktop/YouTube-Downloader-Pro.desktop

# 3. Remove launcher scripts
sudo rm -f /usr/local/bin/youtube-downloader
sudo rm -f /usr/local/bin/youtube-dl
rm -f ~/.local/bin/youtube-downloader


# Remove orphaned packages
sudo apt-get autoremove -y

# Clean apt cache
sudo apt-get clean

# Remove pip cache
rm -rf ~/.cache/pip