import time
import shutil
import logging
from pathlib import Path
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# -----------------------------
# Configuration
# -----------------------------
SRC = Path(r"C:\ATK_Project\compiled")
DST = Path(r"G:\CBO\Business Department\Retail Loan Advisor\Private\Sectie Digital\SQL\compiled")

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)

# -----------------------------
# Initial sync function
# -----------------------------
def initial_sync():
    logging.info(f"Starting initial sync from {SRC} → {DST}")
    for file_path in SRC.rglob("*"):
        if file_path.is_file():
            dst_file = DST / file_path.relative_to(SRC)
            dst_file.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(file_path, dst_file)
            logging.info(f"Copied: {file_path} → {dst_file}")
    logging.info("Initial sync completed.")

# -----------------------------
# Watchdog event handler
# -----------------------------
class MirrorHandler(FileSystemEventHandler):
    def on_created(self, event):
        self._mirror(event)

    def on_modified(self, event):
        self._mirror(event)

    def _mirror(self, event):
        if event.is_directory:
            return
        src_path = Path(event.src_path)
        dst_path = DST / src_path.relative_to(SRC)
        try:
            dst_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src_path, dst_path)
            logging.info(f"Mirrored: {src_path} → {dst_path}")
        except Exception as e:
            logging.error(f"Error copying {src_path}: {e}")

# -----------------------------
# Main
# -----------------------------
if __name__ == "__main__":
    initial_sync()

    observer = Observer()
    observer.schedule(MirrorHandler(), str(SRC), recursive=True)
    observer.start()

    logging.info(f"Watching {SRC} → {DST}. Press Ctrl+C to stop.")
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
