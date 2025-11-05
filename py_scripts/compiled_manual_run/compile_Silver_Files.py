# compile_silver_tables_folder.py
from pathlib import Path
from datetime import datetime

# ---- configure your folder ----
MAIN_DIR  = Path(r"C:\ATK_Project\sql_scripts\Silver")
OUTPUT    = Path(r"C:\ATK_Project\compiled\manual_run\compiled_Silver_Tables.sql")

FALLBACK_ENCODINGS = ("utf-8-sig", "utf-8", "cp1250", "cp1252", "latin-1")
DIV = "-" * 100

# ---- list your files in the specific order you want first ----
SQL_ORDER = [
    "01_mis.Silver_Restruct_SCD.sql",
    "02_mis.Silver_RestructState_SCD.sql",
    "03_mis.Silver_Restruct_Merged_SCD.sql",
    "04_mis.Silver_Client_UnhealedFlag.sql",
    "05_mis.Silver_Resp_SCD.sql",
    "06_mis.Silver_Stages_SCD.sql",
    # add all your filenames here in the desired order
]

def read_text_with_fallback(p: Path) -> str | None:
    for enc in FALLBACK_ENCODINGS:
        try:
            return p.read_text(encoding=enc)
        except Exception:
            continue
    return None

def compile_sql():
    # 1) build full paths in the desired order
    sql_files = []
    processed_names = set()

    # Add files from SQL_ORDER first
    for f in SQL_ORDER:
        full_path = MAIN_DIR / f
        if full_path.exists():
            sql_files.append(full_path)
            processed_names.add(full_path.name)
        else:
            print(f"⚠ Warning: file listed but not found -> {full_path}")

    # 2) append any extra .sql files not listed in SQL_ORDER
    extra_files = sorted(
        [f for f in MAIN_DIR.iterdir() if f.is_file() and f.suffix.lower() == ".sql" and f.name not in processed_names],
        key=lambda p: p.name.lower()
    )
    if extra_files:
        print(f"ℹ Adding {len(extra_files)} extra files not listed in SQL_ORDER.")
    sql_files.extend(extra_files)

    # 3) build header
    header = (
        f"-- Compiled SQL bundle\n"
        f"-- Generated: {datetime.now():%Y-%m-%d %H:%M:%S}\n"
        f"-- Source folder: {MAIN_DIR}\n"
        f"-- Files ({len(sql_files)}):\n--   " + "\n--   ".join([f.name for f in sql_files]) + "\n"
        f"{DIV}\n\nSET NOCOUNT ON;\n\n"
    )

    processed = set()  # keep absolute paths to avoid duplicates

    with OUTPUT.open("w", encoding="utf-8", newline="\n") as out:
        out.write(header)

        # 4) write all files
        for f in sql_files:
            if f.resolve() in processed:
                continue
            processed.add(f.resolve())

            content = read_text_with_fallback(f)
            out.write(f"{DIV}\n-- Start of: {f.name}\n{DIV}\n")
            out.write((content.rstrip() if content else "-- Could not decode file") + "\n")
            out.write(f"{DIV}\n-- End of:   {f.name}\n{DIV}\n\n")
            out.write("GO\n\n")

    print(f"✅ Compiled SQL file created at: {OUTPUT}")

if __name__ == "__main__":
    compile_sql()
