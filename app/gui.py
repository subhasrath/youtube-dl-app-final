import re
import customtkinter as ctk # type: ignore
from tkinter import filedialog, messagebox
from threading import Thread
import os
import queue
from typing import Dict
from backend import YouTubeDownloader
from datetime import datetime
import subprocess

# Configure CustomTkinter
ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("blue")

class ModernYouTubeDownloaderGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("YouTube Downloader Pro")
        self.root.geometry("900x650")
        self.root.minsize(800, 600)
        
        # Center window
        self.root.update_idletasks()
        x = (self.root.winfo_screenwidth() // 2) - (900 // 2)
        y = (self.root.winfo_screenheight() // 2) - (650 // 2)
        self.root.geometry(f"900x650+{x}+{y}")
        
        self.downloader = YouTubeDownloader()
        self.progress_queue = queue.Queue()
        self.current_download_size = 0
        self.download_speed = 0
        
        self._build_ui()
        self._check_queue()
        
    def _build_ui(self):
        # Main container
        self.main = ctk.CTkFrame(self.root, corner_radius=10)
        self.main.pack(fill="both", expand=True, padx=15, pady=15)
        
        # Header - Compact
        header_frame = ctk.CTkFrame(self.main, fg_color="transparent")
        header_frame.pack(fill="x", pady=(0, 15))
        
        self.title_icon = ctk.CTkLabel(header_frame, text="🎬", font=("Segoe UI", 32))
        self.title_icon.pack(side="left", padx=(0, 10))
        
        title_text = ctk.CTkLabel(header_frame, text="YouTube Downloader Pro",
                                 font=ctk.CTkFont(size=22, weight="bold"))
        title_text.pack(side="left")
        
        # URL Section - Compact
        url_frame = ctk.CTkFrame(self.main, corner_radius=8)
        url_frame.pack(fill="x", pady=(0, 10))
        
        self.url_entry = ctk.CTkEntry(url_frame,
                                     placeholder_text="Paste YouTube URL here...",
                                     height=38,
                                     font=ctk.CTkFont(size=13))
        self.url_entry.pack(fill="x", padx=12, pady=(12, 8))
        
        # URL buttons row
        url_btn_frame = ctk.CTkFrame(url_frame, fg_color="transparent")
        url_btn_frame.pack(fill="x", padx=12, pady=(0, 12))
        
        self.paste_btn = ctk.CTkButton(url_btn_frame, text="📋 Paste",
                                       command=self._paste_url,
                                       height=32,
                                       width=100,
                                       corner_radius=6)
        self.paste_btn.pack(side="left", padx=(0, 8))
        
        self.clear_btn = ctk.CTkButton(url_btn_frame, text="🗑️ Clear",
                                       command=self._clear_url,
                                       height=32,
                                       width=100,
                                       corner_radius=6,
                                       fg_color="gray30",
                                       hover_color="gray40")
        self.clear_btn.pack(side="left")
        
        # Options Section - Two columns side by side
        options_frame = ctk.CTkFrame(self.main, corner_radius=8)
        options_frame.pack(fill="x", pady=(0, 10))
        
        # Left column - Quality
        left_col = ctk.CTkFrame(options_frame, fg_color="transparent")
        left_col.pack(side="left", fill="both", expand=True, padx=12, pady=12)
        
        quality_label = ctk.CTkLabel(left_col, text="Video Quality:",
                                    font=ctk.CTkFont(size=12, weight="bold"))
        quality_label.pack(anchor="w", pady=(0, 5))
        
        self.format_var = ctk.StringVar(value="🎯 Best (Recommended)")
        self.format_combo = ctk.CTkComboBox(left_col,
                                           values=["🎯 Best (Recommended)", 
                                                  "📺 1080p Full HD", 
                                                  "📱 720p HD", 
                                                  "💻 480p SD", 
                                                  "🎵 Audio Only (MP3)"],
                                           variable=self.format_var,
                                           height=35,
                                           corner_radius=6)
        self.format_combo.pack(fill="x")
        
        # Right column - Save location
        right_col = ctk.CTkFrame(options_frame, fg_color="transparent")
        right_col.pack(side="right", fill="both", expand=True, padx=12, pady=12)
        
        path_label = ctk.CTkLabel(right_col, text="Save Location:",
                                 font=ctk.CTkFont(size=12, weight="bold"))
        path_label.pack(anchor="w", pady=(0, 5))
        
        path_input_frame = ctk.CTkFrame(right_col, fg_color="transparent")
        path_input_frame.pack(fill="x")
        
        self.path_var = ctk.StringVar(value=os.path.expanduser("~/Downloads/YouTube Downloads"))
        self.path_entry = ctk.CTkEntry(path_input_frame,
                                      textvariable=self.path_var,
                                      height=35,
                                      corner_radius=6)
        self.path_entry.pack(side="left", fill="x", expand=True, padx=(0, 8))
        
        self.browse_btn = ctk.CTkButton(path_input_frame, text="📁",
                                       command=self._browse,
                                       width=40,
                                       height=35,
                                       corner_radius=6)
        self.browse_btn.pack(side="right")
        
        # Create folder
        os.makedirs(self.path_var.get(), exist_ok=True)
        
        # Progress Section - Compact
        progress_frame = ctk.CTkFrame(self.main, corner_radius=8)
        progress_frame.pack(fill="x", pady=(0, 10))
        
        progress_header = ctk.CTkFrame(progress_frame, fg_color="transparent")
        progress_header.pack(fill="x", padx=12, pady=(10, 5))
        
        progress_label = ctk.CTkLabel(progress_header, text="Download Progress",
                                     font=ctk.CTkFont(size=12, weight="bold"))
        progress_label.pack(side="left")
        
        self.percent_label = ctk.CTkLabel(progress_header, text="0%",
                                         font=ctk.CTkFont(size=12, weight="bold"))
        self.percent_label.pack(side="right")
        
        # Progress bar
        self.progress = ctk.CTkProgressBar(progress_frame, height=10, corner_radius=5)
        self.progress.pack(fill="x", padx=12, pady=(0, 5))
        self.progress.set(0)
        
        # Speed info
        self.speed_label = ctk.CTkLabel(progress_frame, text="", font=ctk.CTkFont(size=11))
        self.speed_label.pack(anchor="w", padx=12, pady=(0, 10))
        
        # Log Textbox - Adjustable height
        log_label = ctk.CTkLabel(progress_frame, text="Activity Log:",
                                font=ctk.CTkFont(size=12, weight="bold"))
        log_label.pack(anchor="w", padx=12, pady=(0, 5))
        
        self.log = ctk.CTkTextbox(progress_frame, height=30, corner_radius=6)
        self.log.pack(fill="both", expand=True, padx=12, pady=(0, 12))
        
        # Control Buttons - Compact row
        btn_frame = ctk.CTkFrame(self.main, corner_radius=8)
        btn_frame.pack(fill="x")
        
        btn_container = ctk.CTkFrame(btn_frame, fg_color="transparent")
        btn_container.pack(pady=10)
        
        # Row 1 - Main controls
        self.download_btn = ctk.CTkButton(btn_container, text="⬇️ Download",
                                          command=self._start_download,
                                          height=38,
                                          width=130,
                                          corner_radius=6,
                                          font=ctk.CTkFont(size=13, weight="bold"))
        self.download_btn.pack(side="left", padx=5)
        
        self.pause_btn = ctk.CTkButton(btn_container, text="⏸️ Pause",
                                       command=self._pause,
                                       state="disabled",
                                       height=38,
                                       width=100,
                                       corner_radius=6,
                                       fg_color="orange",
                                       hover_color="darkorange")
        self.pause_btn.pack(side="left", padx=5)
        
        self.resume_btn = ctk.CTkButton(btn_container, text="▶️ Resume",
                                        command=self._resume,
                                        state="disabled",
                                        height=38,
                                        width=100,
                                        corner_radius=6,
                                        fg_color="green",
                                        hover_color="darkgreen")
        self.resume_btn.pack(side="left", padx=5)
        
        self.cancel_btn = ctk.CTkButton(btn_container, text="❌ Cancel",
                                        command=self._cancel,
                                        state="disabled",
                                        height=38,
                                        width=100,
                                        corner_radius=6,
                                        fg_color="red",
                                        hover_color="darkred")
        self.cancel_btn.pack(side="left", padx=5)
        
        self.open_folder_btn = ctk.CTkButton(btn_container, text="📂 Open",
                                            command=self._open_folder,
                                            height=38,
                                            width=80,
                                            corner_radius=6,
                                            fg_color="gray30",
                                            hover_color="gray40")
        self.open_folder_btn.pack(side="left", padx=5)
        
        # Status Bar - Compact
        status_frame = ctk.CTkFrame(self.main, corner_radius=6, height=32)
        status_frame.pack(fill="x", pady=(5, 0))
        status_frame.pack_propagate(False)
        
        self.status = ctk.StringVar(value="✅ Ready")
        status_label = ctk.CTkLabel(status_frame, textvariable=self.status,
                                   font=ctk.CTkFont(size=11))
        status_label.pack(pady=6)
        
        # Initial log message
        self._log("🎬 YouTube Downloader Pro initialized", "info")
        self._log(f"📁 Download folder: {self.path_var.get()}", "info")
        
        # Bind resize event to adjust log height
        self.root.bind("<Configure>", self._on_resize)
    
    def _on_resize(self, event):
        """Handle window resize - adjust log height"""
        if event.widget == self.root:
            height = self.root.winfo_height()
            # Adjust log height based on window size
            new_log_height = max(30, min(100, height - 200))
            self.log.configure(height=new_log_height)
    
    def _clear_url(self):
        """Clear URL entry"""
        self.url_entry.delete(0, "end")
        self._log("URL cleared", "info")
    
    def _log(self, msg, msg_type="info"):
        """Add colored log message"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        self.log.insert("end", f"[{timestamp}] {msg}\n")
        self.log.see("end")
    
    def _paste_url(self):
        """Paste URL from clipboard"""
        try:
            url = self.root.clipboard_get()
            if 'youtube.com' in url or 'youtu.be' in url:
                self.url_entry.delete(0, "end")
                self.url_entry.insert(0, url)
                self._log("📋 YouTube URL pasted", "info")
            else:
                self._log("⚠️ Invalid YouTube URL in clipboard", "warning")
        except:
            self._log("❌ Failed to access clipboard", "error")
    
    def _browse(self):
        """Browse for directory"""
        path = filedialog.askdirectory(initialdir=self.path_var.get())
        if path:
            self.path_var.set(path)
            os.makedirs(path, exist_ok=True)
            self._log(f"📁 Download folder: {path}", "info")
    
    def _open_folder(self):
        """Open download folder"""
        folder = self.path_var.get()
        if os.path.exists(folder):
            subprocess.run(['xdg-open', folder])
    
    def _start_download(self):
        """Start download process"""
        url = self.url_entry.get().strip()
        if not url:
            messagebox.showerror("Error", "Please enter a YouTube URL")
            return
        
        if not ('youtube.com' in url or 'youtu.be' in url):
            messagebox.showerror("Error", "Please enter a valid YouTube URL")
            return
        
        # Clear previous progress
        self.progress.set(0)
        self.percent_label.configure(text="0%")
        self.speed_label.configure(text="")
        self._log("🚀 Starting download...", "info")
        self._log(f"📎 URL: {url}", "info")
        
        # Disable buttons during download
        self.download_btn.configure(state="disabled")
        self.pause_btn.configure(state="normal")
        self.resume_btn.configure(state="disabled")
        self.cancel_btn.configure(state="normal")
        self.url_entry.configure(state="disabled")
        self.format_combo.configure(state="disabled")
        
        # Start download thread
        thread = Thread(target=self._download_thread, daemon=True)
        thread.start()
    
    def _download_thread(self):
        """Download thread"""
        try:
            self.downloader.download_video(
                url=self.url_entry.get(),
                format=self._convert_format(self.format_var.get()),
                output_path=self.path_var.get(),
                progress_callback=self._progress
            )
            self._queue(("log", "✅ Download completed successfully!", "info"))
            self._queue(("status", "✅ Download complete"))
            self._queue(("progress", 100))
        except Exception as e:
            self._queue(("log", f"❌ Error: {str(e)}", "error"))
            self._queue(("status", "❌ Download failed"))
        finally:
            self._queue(("reset", None))
    
    def _convert_format(self, format_str):
        """Convert display format to backend format"""
        format_map = {
            "🎯 Best (Recommended)": "best",
            "📺 1080p Full HD": "1080p",
            "📱 720p HD": "720p",
            "💻 480p SD": "480p",
            "🎵 Audio Only (MP3)": "audio only",
        }
        return format_map.get(format_str, "best")
    
    def _progress(self, data: Dict):
        """Handle progress updates"""
        status = data.get("status")
        if status == "downloading":
            downloaded = data.get("downloaded_bytes", 0)
            total = data.get("total_bytes") or data.get("total_bytes_estimate")
            if total:
                percent = (downloaded / total) * 100
            else:
                percent = 0.0

            # percent_str = data.get("_percent_str", "0%")
            # clean = re.sub(r'\x1b\[[0-9;]*m', '', percent_str)
            # try:
            #     percent = float(clean.replace("%", ""))
            # except ValueError:
            #     percent = 0.0
            
            speed = data.get("_speed_str", "N/A")
            eta = data.get("_eta_str", "N/A")
            self._queue(("progress", percent))
            self._queue(("status", f"📥 Downloading: {percent:.1f}%"))
            self._queue(("speed", f"⚡ {speed} | ⏱️ ETA: {eta}"))

            if int(percent) % 5 == 0:
                self._queue((
                    "log",
                    f"📥 {percent:.1f}% | {speed} | ETA {eta}",
                    "info"
                ))
        elif status == "playlist_progress":
            msg = data.get("message", "")

            msg = re.sub(r'\x1b\[[0-9;]*m', '', msg)
            match = re.search(r'item (\d+) of (\d+)', msg)

            if match:
                current, total = match.groups()
                display = f"📂 Playlist: {current}/{total}"

                try:
                    percent = (int(current) / int(total)) * 100
                    self._queue(("progress", percent))
                except:
                    pass
            else:
                display = msg
            self._queue(("log", display, "info"))
            self._queue(("status", display))

        elif status == "finished":
            self._queue(("log", "🔄 Processing file...", "info"))
            self._queue(("status", "🔄 Processing..."))
        elif status == "paused":
            self._queue(("status", "⏸️ Paused"))
            


            

    def _pause(self):
        """Pause download"""
        self.downloader.pause()
        self.pause_btn.configure(state="disabled")
        self.resume_btn.configure(state="normal")
        self._log("⏸ Download paused", "warning")
        self.status.set("⏸ Paused")
    
    def _resume(self):
        """Resume download"""
        self.downloader.resume()
        self.pause_btn.configure(state="normal")
        self.resume_btn.configure(state="disabled")
        self._log("▶️ Download resumed", "info")
        self.status.set("▶️ Resuming...")
    
    def _cancel(self):
        """Cancel download"""
        if messagebox.askyesno("Cancel Download", "Are you sure you want to cancel the download?"):
            self.downloader.cancel()
            self._log("❌ Download cancelled", "warning")
            self.status.set("❌ Cancelled")
            self._reset_controls()
    
    def _queue(self, item):
        """Queue GUI updates"""
        self.progress_queue.put(item)
    
    def _check_queue(self):
        """Process queued GUI updates"""
        try:
            while True:
                item = self.progress_queue.get_nowait()
                if len(item) == 3:
                    action, value, msg_type = item
                else:
                    action, value = item
                    msg_type = "info"
                
                if action == "log":
                    self._log(value, msg_type)
                elif action == "status":
                    self.status.set(value)
                elif action == "progress":
                    self.progress.set(value / 100)
                    self.percent_label.configure(text=f"{value:.1f}%")
                elif action == "speed":
                    self.speed_label.configure(text=value)
                elif action == "reset":
                    self._reset_controls()
        except queue.Empty:
            pass
        
        self.root.after(100, self._check_queue)
    
    def _reset_controls(self):
        """Reset UI controls"""
        self.download_btn.configure(state="normal")
        self.pause_btn.configure(state="disabled")
        self.resume_btn.configure(state="disabled")
        self.cancel_btn.configure(state="disabled")
        self.url_entry.configure(state="normal")
        self.format_combo.configure(state="normal")
        
        if self.progress.get() < 1:
            self.progress.set(0)
            self.percent_label.configure(text="0%")
            self.speed_label.configure(text="")

if __name__ == "__main__":
    root = ctk.CTk()
    app = ModernYouTubeDownloaderGUI(root)
    root.mainloop()