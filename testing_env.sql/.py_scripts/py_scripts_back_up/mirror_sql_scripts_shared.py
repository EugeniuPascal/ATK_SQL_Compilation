import shutil
import logging
from pathlib import Path

# -----------------------------
# Configuration
# -----------------------------
SOURCES = [
    Path(r"C:\ATK_Project\sql_scripts"),
    Path(r"C:\ATK_Project\compiled")
]
DST_ROOT = Path(r"G:\CBO\Business Department\Retail Loan Advisor\Private\Sectie Digital\SQL")

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)

# -----------------------------
# Function to fully replace a folder
# -----------------------------
def full_copy(src: Path, dst_root: Path):
    dst_folder = dst_root / src.name
    if dst_folder.exists():
        logging.info(f"Removing old folder: {dst_folder}")
        shutil.rmtree(dst_folder)
    logging.info(f"Copying {src} → {dst_folder}")
    shutil.copytree(src, dst_folder)
    logging.info(f"Copied {src} → {dst_folder} successfully.")

# -----------------------------
# Main
# -----------------------------
if __name__ == "__main__":
    for src in SOURCES:
        full_copy(src, DST_ROOT)

    logging.info("All folders copied successfully.")
