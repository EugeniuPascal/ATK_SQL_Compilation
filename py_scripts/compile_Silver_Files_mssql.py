# compile_silver_tables_folder_proc_full_idempotent.py
from pathlib import Path
from datetime import datetime
import re

MAIN_DIR = Path(r"C:\ATK_Project\sql_scripts\Silver")
OUTPUT   = Path(r"C:\ATK_Project\compiled\compiled_Silver_Tables_Proc_mssql.sql")

FALLBACK_ENCODINGS = ("utf-8-sig", "utf-8", "cp1250", "cp1252", "latin-1")
DIV = "-" * 100

def read_text_with_fallback(p: Path) -> str | None:
    for enc in FALLBACK_ENCODINGS:
        try:
            return p.read_text(encoding=enc)
        except Exception:
            pass
    return None

def remove_use_statements(sql: str) -> str:
    """Remove USE <dbname>; statements"""
    return re.sub(r"^\s*USE\s+\[?[^\]\s]+\]?\s*;\s*", "", sql, flags=re.IGNORECASE | re.MULTILINE)

def wrap_sql_objects(sql: str) -> str:
    """
    Wrap CREATE and ALTER statements to avoid errors if object exists
    """
    # CREATE TABLE
    def table_repl(match):
        table_name = match.group(1)
        return f"IF OBJECT_ID(N'{table_name}', N'U') IS NULL\nBEGIN\n{match.group(0)}\nEND"
    sql = re.sub(r"CREATE\s+TABLE\s+([a-zA-Z0-9_\.\[\]]+)", table_repl, sql, flags=re.IGNORECASE)

    # CREATE VIEW
    def view_repl(match):
        view_name = match.group(1)
        return f"IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'{view_name}'))\nBEGIN\n{match.group(0)}\nEND"
    sql = re.sub(r"CREATE\s+VIEW\s+([a-zA-Z0-9_\.\[\]]+)", view_repl, sql, flags=re.IGNORECASE)

    # CREATE PROCEDURE
    def proc_repl(match):
        proc_name = match.group(1)
        return f"IF OBJECT_ID(N'{proc_name}', N'P') IS NULL\nBEGIN\n{match.group(0)}\nEND"
    sql = re.sub(r"CREATE\s+PROCEDURE\s+([a-zA-Z0-9_\.\[\]]+)", proc_repl, sql, flags=re.IGNORECASE)

    # ALTER TABLE ADD COLUMN -> wrap in IF COL_LENGTH
    def alter_add_col_repl(match):
        table_name = match.group(1)
        col_name   = match.group(2)
        col_def    = match.group(3)
        return f"IF COL_LENGTH(N'{table_name}', N'{col_name}') IS NULL\nBEGIN\nALTER TABLE {table_name} ADD {col_name} {col_def}\nEND"
    sql = re.sub(r"ALTER\s+TABLE\s+([a-zA-Z0-9_\.\[\]]+)\s+ADD\s+([a-zA-Z0-9_\[\]]+)\s+([^\n;]+)", alter_add_col_repl, sql, flags=re.IGNORECASE)

    return sql

def compile_sql_to_proc():
    sql_files = sorted(
        [f for f in MAIN_DIR.iterdir() if f.is_file() and f.suffix.lower() == ".sql"],
        key=lambda p: p.name.lower()
    )

    header = (
        f"-- Compiled SQL procedure (Silver) - Full & Idempotent\n"
        f"-- Generated: {datetime.now():%Y-%m-%d %H:%M:%S}\n"
        f"-- Source folder: {MAIN_DIR}\n"
        f"-- Files ({len(sql_files)}):\n--   " + "\n--   ".join(f.name for f in sql_files) + "\n"
        f"{DIV}\n\nSET NOCOUNT ON;\nGO\n\n"
    )

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)

    with OUTPUT.open("w", encoding="utf-8", newline="\n") as out:
        out.write(header)

        # Start procedure
        out.write("CREATE OR ALTER PROCEDURE usp_CompileSilverTables\nAS\nBEGIN\n")
        out.write("SET NOCOUNT ON;\n\n")

        for f in sql_files:
            content = read_text_with_fallback(f)
            if content:
                content = remove_use_statements(content)
                content = wrap_sql_objects(content)
            else:
                content = "-- Could not decode file"

            out.write(f"{DIV}\n-- Start of: {f.name}\n{DIV}\n")
            out.write(content.rstrip() + "\n")
            out.write(f"{DIV}\n-- End of:   {f.name}\n{DIV}\n\n")

        out.write("END\nGO\n")
    print(f"Compiled procedure created at: {OUTPUT}")

if __name__ == "__main__":
    compile_sql_to_proc()
