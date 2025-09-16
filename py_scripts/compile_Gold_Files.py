# compile_gold_tables_folder.py
from pathlib import Path
from datetime import datetime

# ---- configure your folder ----
MAIN_DIR  = Path(r"C:\ATK_Project\sql_scripts\Gold")
OUTPUT    = Path(r"C:\ATK_Project\compiled\compiled_Gold_Tables.sql")

FALLBACK_ENCODINGS = ("utf-8-sig", "utf-8", "cp1250", "cp1252", "latin-1")
DIV = "-" * 100

def read_text_with_fallback(p: Path) -> str | None:
    for enc in FALLBACK_ENCODINGS:
        try:
            return p.read_text(encoding=enc)
        except Exception:
            continue
    return None

def compile_sql():
    # 1) collect & sort regular .sql files from MAIN_DIR
    sql_files = sorted(
        [f for f in MAIN_DIR.iterdir() if f.is_file() and f.suffix.lower() == ".sql"],
        key=lambda p: p.name.lower()
    )

    # 2) build header
    header = (
        f"-- Compiled SQL bundle\n"
        f"-- Generated: {datetime.now():%Y-%m-%d %H:%M:%S}\n"
        f"-- Source folder: {MAIN_DIR}\n"
        f"-- Files ({len(sql_files)}):\n--   " + "\n--   ".join([f.name for f in sql_files]) + "\n"
        f"{DIV}\n\nSET NOCOUNT ON;\n\n"
    )

    processed = set()  # keep absolute paths to avoid accidental duplicates

    with OUTPUT.open("w", encoding="utf-8", newline="\n") as out:
        out.write(header)

        # 3) write all main files
        for f in sql_files:
            processed.add(f.resolve())
            content = read_text_with_fallback(f)
            out.write(f"{DIV}\n-- Start of: {f.name}\n{DIV}\n")
            out.write((content.rstrip() if content else "-- Could not decode file") + "\n")
            out.write(f"{DIV}\n-- End of:   {f.name}\n{DIV}\n\n")
            out.write("GO\n\n")

    print(f"Compiled SQL file created at: {OUTPUT}")

if __name__ == "__main__":
    compile_sql()
