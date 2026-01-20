import shutil
import logging
from pathlib import Path

# -----------------------------
# Configuration
# -----------------------------
SRC = Path(r"C:\ATK_Project")
DST = Path(r"H:\mapa lucru\ATK_db\ATK_db_mirror")

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)

# -----------------------------
# Function to update destination
# -----------------------------
def update_destination(src: Path, dst: Path):
    for src_file in src.rglob("*"):
        if src_file.is_file():
            # Skip .git folder
            if ".git" in src_file.parts:
                continue

            relative_path = src_file.relative_to(src)
            dst_file = dst / relative_path
            dst_file.parent.mkdir(parents=True, exist_ok=True)

            # Copy only if destination doesn't exist or source is newer
            if not dst_file.exists() or src_file.stat().st_mtime > dst_file.stat().st_mtime:
                shutil.copy2(src_file, dst_file)
                logging.info(f"Updated: {src_file} → {dst_file}")

# -----------------------------
# Main
# -----------------------------
if __name__ == "__main__":
    logging.info(f"Updating destination: {SRC} → {DST}")
    update_destination(SRC, DST)
    logging.info("Update completed.")
