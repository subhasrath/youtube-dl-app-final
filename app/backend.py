import yt_dlp # type: ignore
import os
from threading import Event
from typing import Optional, Dict, Callable
import time

class YTDLPLogger:
    def __init__(self, callback):
        self.callback = callback

    def debug(self, msg):
        self._handle(msg)

    def warning(self, msg):
        self._handle(msg)

    def error(self, msg):
        self._handle(msg)

    def _handle(self, msg):
        # Detect playlist progress
        if "Downloading item" in msg:
            self.callback({
                "status": "playlist_progress",
                "message": msg
            })

class YouTubeDownloader:
    def __init__(self):
        """
        Initialize the downloader with default options.
        Uses threading.Event for pause/resume functionality.
        """
        self.pause_event = Event()
        self.pause_event.set()  # Start in unpaused state
        self.current_download = None
        self.download_active = False
        
    def _progress_hook(self, d: Dict, callback: Callable) -> None:
        """
        Progress callback for yt-dlp.
        Handles pause/resume and updates progress.
        """
        if not callback:
            return
        status = d.get('status')

        if status == 'downloading':
            while not self.pause_event.is_set() and self.download_active:
                callback({"status": "paused"})
                self.pause_event.wait(0.1)
            
            if not self.download_active:
                raise Exception("CANCELLED_BY_USER")
                
            callback(d)

        elif status == 'finished':
            callback({"status": "finished", "filename": d.get('filename')})
    
    def download_video(
        self,
        url: str,
        format: str = "best",
        output_path: str = "./downloads",
        progress_callback: Optional[Callable] = None
    ) -> None:
        """
        Download a YouTube video with pause/resume support.
        
        Args:
            url: YouTube video URL
            format: Quality format (best, 1080p, 720p, etc.)
            output_path: Directory to save the video
            progress_callback: Function to receive progress updates
        """
        self.download_active = True
        try:
            ydl_opts = {
                'format': self._get_format_string(format),
                'outtmpl': os.path.join(output_path, '%(title)s.%(ext)s'),
                'progress_hooks': [lambda d: self._progress_hook(d, progress_callback)], # type: ignore
                'logger': YTDLPLogger(progress_callback),
                'noprogress': False,
                'quiet': False,
                'no_warnings': False,
            }
            
            with yt_dlp.YoutubeDL(ydl_opts) as ydl: # type: ignore
                self.current_download = ydl
                ydl.download([url])
                
        except Exception as e:
            if self.download_active:  # Only propagate error if not cancelled
                raise e
        finally:
            self.download_active = False
            self.current_download = None
    
    def pause(self) -> None:
        """Pause the current download"""
        self.pause_event.clear()
    
    def resume(self) -> None:
        """Resume the paused download"""
        self.pause_event.set()
    
    def cancel(self) -> None:
        """Cancel the current download"""
        self.download_active = False
        self.resume()  # Release any waiting threads
        if self.current_download:
            self.current_download.cancel_download() # type: ignore
    
    def _get_format_string(self, format: str) -> str:
        """Convert user-friendly format to yt-dlp format string"""
        format_map = {
            "best": "bestvideo+bestaudio/best",
            "audio only": "bestaudio/best",
            "1080p": "bestvideo[height<=1080]+bestaudio/best",
            "720p": "bestvideo[height<=720]+bestaudio/best",
            "480p": "bestvideo[height<=480]+bestaudio/best",
        }
        return format_map.get(format, format)