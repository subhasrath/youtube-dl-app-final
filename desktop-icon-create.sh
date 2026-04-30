cd ~/Desktop/youtube-dl-app-final

# Download a proper YouTube icon
wget -O youtube-icon.png https://cdn-icons-png.flaticon.com/256/1384/1384060.png 2>/dev/null || echo "Using default icon"

# Create desktop entry with the icon
cat > ~/.local/share/applications/youtube-downloader.desktop << EOF
[Desktop Entry]
Version=1.0
Name=YouTube Downloader Pro
Comment=Download YouTube videos in various qualities
Exec=$HOME/Desktop/youtube-dl-app-final/launch_app.sh
Icon=$HOME/Desktop/youtube-dl-app-final/youtube-icon.png
Terminal=false
Type=Application
Categories=AudioVideo;Network;Downloader;
StartupNotify=true
Keywords=youtube;downloader;video;mp4;mp3;
Actions=Download;Settings;

[Desktop Action Download]
Name=Start Download
Exec=$HOME/Desktop/youtube-dl-app-final/launch_app.sh

[Desktop Action Settings]
Name=Open Downloads Folder
Exec=xdg-open $HOME/Downloads
EOF

update-desktop-database ~/.local/share/applications/