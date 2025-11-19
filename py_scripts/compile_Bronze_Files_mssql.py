# compile_bronze_tables_job_proc_idempotent.py
import re
import logging
from datetime import datetime
from pathlib import Path

# ---- Settings ----
DB_NAME        = "ATK"
DEFAULT_SCHEMA = "mis"
SOURCE_FOLDER  = Path(r"C:\ATK_Project\sql_scripts\Bronze")
OUTPUT_FILE    = Path(r"C:\ATK_Project\compiled\compiled_bronze_job_proc.sql")
LOG_FILE       = Path(r"C:\ATK_Project\logs\compile_bronze.log")

# ---- Logging ----
LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
logging.basicConfig(
    filename=str(LOG_FILE),
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)
logging.info("=== Starting Bronze SQL Compilation Job ===")

# --------------------------------------------------------------------
# Regexes
# --------------------------------------------------------------------
GO_LINE_RE       = re.compile(r"^\s*GO\s*$", re.IGNORECASE | re.MULTILINE)
USE_RE           = re.compile(r"^\s*USE\s+\[?[^\]\r\n]+]?\s*;\s*$", re.IGNORECASE | re.MULTILINE)
LINE_COMMENT_RE  = re.compile(r"--[^\r\n]*")
BLOCK_COMMENT_RE = re.compile(r"/\*.*?\*/", re.DOTALL)
NAME_PART        = r'(?:\[[^\]]+\]|"[^"]+"|[^\s\(\[\]"\.]+)'
NAME_PATTERN     = rf"{NAME_PART}(?:\.{NAME_PART})*"
CREATE_VIEW_RE   = re.compile(rf"(?im)\bCREATE\s+VIEW\s+({NAME_PATTERN})")
CREATE_FUNC_RE   = re.compile(rf"(?im)\bCREATE\s+FUNCTION\s+({NAME_PATTERN})")
CREATE_TABLE_RE  = re.compile(rf"(?im)\bCREATE\s+TABLE\s+({NAME_PATTERN})[ \t]*(?=\()")

# --------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------
def strip_sql_comments(sql: str) -> str:
    """Remove block and line comments safely (preserving newlines)."""
    def _block_repl(m): 
        return re.sub(r"[^\r\n]", " ", m.group(0))
    sql = BLOCK_COMMENT_RE.sub(_block_repl, sql)
    sql = LINE_COMMENT_RE.sub("", sql)
    return sql

def normalize_object_name(name: str, default_schema: str) -> str:
    """
    Normalize to [schema].[object] format without adding extra brackets.
    Multi-part names like Bronze_РегистрыСведений.КредитыВТеневыхФилиалах
    become: [mis].[Bronze_РегистрыСведений.КредитыВТеневыхФилиалах]
    Temp tables (#temp) are returned untouched.
    """
    n = name.strip().strip('"')

    if n.startswith('#'):
        return n  # temp table

    # Remove any outer brackets from input
    n = n.strip('[]')

    # Only last part is treated as object, everything else stays in object name
    obj_name = n.split('.', 1)[-1] if '.' in n else n

    # Wrap schema and object in single brackets
    return f'[{default_schema}].[{obj_name}]'


def make_idempotent(sql: str) -> str:
    """Clean SQL and make CREATE statements idempotent for tables/views/functions."""
    sql = strip_sql_comments(sql)
    sql = GO_LINE_RE.sub("", sql)
    sql = USE_RE.sub("", sql)
    sql = CREATE_VIEW_RE.sub(lambda m: f"CREATE OR ALTER VIEW {m.group(1)}", sql)
    sql = CREATE_FUNC_RE.sub(lambda m: f"CREATE OR ALTER FUNCTION {m.group(1)}", sql)

    def table_repl(m):
        raw = m.group(1).strip()
        if raw.startswith('#'):
            return f"CREATE TABLE {raw}"
        norm = normalize_object_name(raw, DEFAULT_SCHEMA)
        return f"IF OBJECT_ID(N'{norm}','U') IS NOT NULL DROP TABLE {norm};\nCREATE TABLE {norm}"

    return CREATE_TABLE_RE.sub(table_repl, sql).strip()

# --------------------------------------------------------------------
# Main
# --------------------------------------------------------------------
try:
    sql_files = sorted([f for f in SOURCE_FOLDER.iterdir() if f.is_file() and f.suffix.lower() == ".sql"])
    logging.info(f"Found {len(sql_files)} SQL files to compile.")
    if not sql_files:
        raise FileNotFoundError(f"No .sql files found in {SOURCE_FOLDER}")

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT_FILE.open("w", encoding="utf-8-sig") as f_out:
        # Header
        f_out.write("-- =============================================\n")
        f_out.write("-- Compiled Stored Procedure for MSSQL Agent Job (Bronze) - Idempotent\n")
        f_out.write(f"-- Generated: {datetime.now()}\n")
        f_out.write(f"-- Source folder: {SOURCE_FOLDER}\n")
        f_out.write(f"-- Files included: {len(sql_files)}\n")
        for sf in sql_files:
            f_out.write(f"--   {sf.name}\n")
        f_out.write("-- Requires: SQL Server 2016 SP1+ for CREATE OR ALTER\n")
        f_out.write("-- =============================================\n\n")

        # Procedure header
        f_out.write(f"USE [{DB_NAME}];\nGO\n\n")
        f_out.write(f"IF OBJECT_ID('{DEFAULT_SCHEMA}.usp_BronzeTables', 'P') IS NOT NULL\n")
        f_out.write(f"    DROP PROCEDURE {DEFAULT_SCHEMA}.usp_BronzeTables;\nGO\n\n")
        f_out.write(f"CREATE PROCEDURE {DEFAULT_SCHEMA}.usp_BronzeTables\nAS\nBEGIN\n")
        f_out.write("    SET NOCOUNT ON;\n")
        f_out.write("    DECLARE @sql NVARCHAR(MAX);\n\n")

        # Process each file
        for sf in sql_files:
            try:
                logging.info(f"Processing file: {sf.name}")
                with sf.open("r", encoding="utf-8-sig") as f_in:
                    content = f_in.read()
                    transformed = make_idempotent(content)
                    safe = transformed.replace("'", "''")
                    if safe.strip():  # skip empty
                        f_out.write(f"    -- Start of: {sf.name}\n")
                        f_out.write(f"    SET @sql = N'{safe}';\n")
                        f_out.write("    BEGIN TRY\n")
                        f_out.write("        EXEC sys.sp_executesql @sql;\n")
                        f_out.write("    END TRY\n")
                        f_out.write("    BEGIN CATCH\n")
                        f_out.write("        THROW;\n")
                        f_out.write("    END CATCH;\n\n")
                logging.info(f"Finished file: {sf.name}")
            except Exception as e:
                logging.error(f"Error processing {sf.name}: {e}")
                raise

        f_out.write("END\nGO\n")

    logging.info(f"✅ Stored procedure script generated successfully: {OUTPUT_FILE}")
    print(f"✅ Stored procedure script generated successfully: {OUTPUT_FILE}")

except Exception as e:
    logging.exception("💥 Fatal error during compilation")
    raise
