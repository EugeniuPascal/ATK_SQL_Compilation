# compile_bronze_tables_folder_with_log_fixed.py
from pathlib import Path
from datetime import datetime
import re

# ---- Settings ----
MAIN_DIR = Path(r"C:\ATK_Project\sql_scripts\Bronze")
OUTPUT   = Path(r"C:\ATK_Project\compiled\manual_run\compiled_Bronze_Tables.sql")
LOG_TABLE = "mis.Bronze_Proc_Exec_Log"

FALLBACK_ENCODINGS = ("utf-8-sig", "utf-8", "cp1250", "cp1252", "latin-1")
DIV = "-" * 100

# Remove GO lines from content
GO_RE = re.compile(r"^\s*GO\s*$", re.IGNORECASE | re.MULTILINE)

# --------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------
def read_text_with_fallback(p: Path) -> str | None:
    """Try multiple encodings to safely read SQL text files."""
    for enc in FALLBACK_ENCODINGS:
        try:
            return p.read_text(encoding=enc)
        except Exception:
            continue
    return None

# --------------------------------------------------------------------
# Main compilation
# --------------------------------------------------------------------
def compile_sql():
    sql_files = sorted(
        [f for f in MAIN_DIR.iterdir() if f.is_file() and f.suffix.lower() == ".sql"],
        key=lambda p: p.name.lower()
    )

    header = (
        f"-- Compiled SQL bundle (Bronze) with Logging\n"
        f"-- Generated: {datetime.now():%Y-%m-%d %H:%M:%S}\n"
        f"-- Source folder: {MAIN_DIR}\n"
        f"-- Files ({len(sql_files)}):\n--   " + "\n--   ".join(f.name for f in sql_files) + "\n"
        f"{DIV}\n\nSET NOCOUNT ON;\n\n"
        f"DECLARE @StartTime DATETIME;\n"
        f"DECLARE @EndTime DATETIME;\n"
        f"DECLARE @Status NVARCHAR(50);\n\n"
    )

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT.open("w", encoding="utf-8", newline="\n") as out:
        out.write(header)

        for f in sql_files:
            content = read_text_with_fallback(f)
            table_name = f.stem

            # Remove GO from content
            if content:
                content = GO_RE.sub("", content)

            out.write(f"{DIV}\n-- Start of: {f.name}\n{DIV}\n")

            # Set start time and status
            out.write(f"SET @StartTime = GETDATE();\n")
            out.write(f"SET @Status = 'Running';\n\n")

            # Wrap file SQL in TRY/CATCH
            out.write("BEGIN TRY\n")
            if content:
                indented_content = "\n    ".join(content.rstrip().splitlines())
                out.write(f"    {indented_content}\n")
            else:
                out.write("    -- Could not decode file\n")
            out.write("    SET @Status = 'Success';\n")
            out.write("END TRY\n")
            out.write("BEGIN CATCH\n")
            out.write("    SET @Status = 'Failed';\n")
            out.write("END CATCH;\n\n")

            # Capture end time and insert log
            out.write("SET @EndTime = GETDATE();\n")
            out.write(f"INSERT INTO {LOG_TABLE} (TableName, StartTime, EndTime, Status)\n")
            out.write(f"VALUES ('{table_name}', @StartTime, @EndTime, @Status);\n\n")

            out.write(f"{DIV}\n-- End of: {f.name}\n{DIV}\n\n")

    print(f"✅ Compiled SQL file with logging created at: {OUTPUT}")

if __name__ == "__main__":
    compile_sql()