import time
import shutil
from pathlib import Path
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

SRC = Path(r"C:\ATK_Project")
DST = Path(r"H:\mapa lucru\ATK_db\ATK_db_mirror")

class MirrorHandler(FileSystemEventHandler):
    def on_any_event(self, event):
        if event.is_directory:
            return
        src_path = Path(event.src_path)
        if src_path.suffix in {".tmp", ".swp"}:  # optional
            return
        relative_path = src_path.relative_to(SRC)
        dst_path = DST / relative_path
        try:
            dst_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src_path, dst_path)
            print(f"Mirrored: {src_path} → {dst_path}")
        except Exception as e:
            print(f"Error copying {src_path}: {e}")

# Initial full copy
for file_path in SRC.rglob("*"):
    if file_path.is_file():
        dst_path = DST / file_path.relative_to(SRC)
        dst_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(file_path, dst_path)
        print(f"Copied: {file_path} → {dst_path}")

# Set up observer
observer = Observer()
observer.schedule(MirrorHandler(), str(SRC), recursive=True)
observer.start()

print(f"Watching {SRC} → {DST}. Press Ctrl+C to stop.")
try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    observer.stop()
observer.join()
