#!/bin/bash

cd ~/Desktop/youtube-dl-app-final

# Check if venv exists
if [ ! -d "venv" ]; then
    echo "First time setup: Creating virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
    pip install customtkinter yt-dlp 2>/dev/null
    pip install --upgrade pip
    pip install yt-dlp
    echo "Setup complete!"
else
    source venv/bin/activate
fi

# Run the application
python app/main.py

# Keep terminal open if there's an error
if [ $? -ne 0 ]; then
    echo ""
    echo "Press Enter to exit..."
    read
fi
