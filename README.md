# Complete Working Setup
Here's the simplest working approach:
# locaion to download and setup the downloader
desktop

# Step 1: Create virtual environment
cd ~/Desktop/youtube-dl-app-final
python3 -m venv venv

# Step 2: Activate it
source venv/bin/activate

# Step 3: Install yt-dlp
pip install yt-dlp

# Step 4: Run your app
python app/main.py

# Test the Setup
# Test if everything works
cd ~/Desktop/youtube-dl-app-final
source venv/bin/activate
python -c "import yt_dlp; print('✓ yt-dlp installed')"
python -c "import tkinter; print('✓ Tkinter available')"
python app/main.py


# If You Encounter Any Issues
# Recreate virtual environment
cd ~/Desktop/youtube-dl-app-final
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install yt-dlp
python app/main.py


# luanch app from command line
./launch_app.sh

# Create the Debian file
./create_deb_package.sh
