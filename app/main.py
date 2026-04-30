import sys
import os

# Add parent directory to path if needed
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def main():
    """Launch the YouTube Downloader application"""
    try:
        import customtkinter as ctk # type: ignore
        
        # Import the correct GUI class
        from gui import ModernYouTubeDownloaderGUI
        
        # Create and run the application
        root = ctk.CTk()
        app = ModernYouTubeDownloaderGUI(root)
        root.mainloop()
        
    except ImportError as e:
        print(f"Error importing modules: {e}")
        print("\nPlease make sure customtkinter is installed:")
        print("pip install customtkinter")
        input("\nPress Enter to exit...")
        
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        input("\nPress Enter to exit...")

if __name__ == "__main__":
    main()