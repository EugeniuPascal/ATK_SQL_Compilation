# compile_silver_tables_procedure.py
from pathlib import Path
from datetime import datetime

MAIN_DIR = Path(r"C:\ATK_Project\sql_scripts\Silver")
OUTPUT   = Path(r"C:\ATK_Project\compiled\compiled_Silver_Tables.sql")

FALLBACK_ENCODINGS = ("utf-8-sig", "utf-8", "cp1250", "cp1252", "latin-1")
DIV = "-" * 100
PROC_NAME = "usp_CompileSilverTables"  # name of the stored procedure

def read_text_with_fallback(p: Path) -> str | None:
    for enc in FALLBACK_ENCODINGS:
        try:
            return p.read_text(encoding=enc)
        except Exception:
            pass
    return None

def compile_sql_procedure():
    sql_files = sorted(
        [f for f in MAIN_DIR.iterdir() if f.is_file() and f.suffix.lower() == ".sql"],
        key=lambda p: p.name.lower()
    )

    # Header
    header = (
        f"-- Compiled SQL Procedure (Silver)\n"
        f"-- Generated: {datetime.now():%Y-%m-%d %H:%M:%S}\n"
        f"-- Source folder: {MAIN_DIR}\n"
        f"-- Files ({len(sql_files)}):\n--   " + "\n--   ".join(f.name for f in sql_files) + "\n"
        f"{DIV}\n\nSET NOCOUNT ON;\n\n"
    )

    # Start procedure
    procedure_start = f"IF OBJECT_ID(N'{PROC_NAME}', 'P') IS NOT NULL\n    DROP PROCEDURE {PROC_NAME};\nGO\n\n"
    procedure_start += f"CREATE PROCEDURE {PROC_NAME}\nAS\nBEGIN\n\n"

    procedure_end = "\nEND\nGO\n"

    # Combine SQL contents
    combined_sql = ""
    for f in sql_files:
        content = read_text_with_fallback(f)
        combined_sql += f"{DIV}\n-- Start of: {f.name}\n{DIV}\n"
        combined_sql += (content.rstrip() if content else "-- Could not decode file") + "\n"
        combined_sql += f"{DIV}\n-- End of:   {f.name}\n{DIV}\n\n"

    # Write final output
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT.open("w", encoding="utf-8", newline="\n") as out:
        out.write(header)
        out.write(procedure_start)
        out.write(combined_sql)
        out.write(procedure_end)

    print(f"Compiled procedure created at: {OUTPUT}")

if __name__ == "__main__":
    compile_sql_procedure()
