# compile_silver_tables_job_proc_idempotent.py
import os
import re
import logging
from datetime import datetime

# ---- Settings ----
DB_NAME        = "ATK"
DEFAULT_SCHEMA = "mis"   # only schema you can use
source_folder  = r"C:\ATK_Project\sql_scripts\Silver"
output_file    = r"C:\ATK_Project\compiled\compiled_silver_job_proc.sql"
log_file       = r"C:\ATK_Project\logs\compile_silver.log"

# ---- Logging ----
os.makedirs(os.path.dirname(log_file), exist_ok=True)
logging.basicConfig(
    filename=log_file,
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)
logging.info("=== Starting Silver SQL Compilation Job ===")

# --------------------------------------------------------------------
# Regexes
# --------------------------------------------------------------------
GO_LINE_RE   = re.compile(r"^\s*GO\s*$", re.IGNORECASE | re.MULTILINE)
USE_RE       = re.compile(r"^\s*USE\s+\[?[^\]\r\n]+]?\s*;\s*$", re.IGNORECASE | re.MULTILINE)
LINE_COMMENT_RE  = re.compile(r"--[^\r\n]*")
BLOCK_COMMENT_RE = re.compile(r"/\*.*?\*/", re.DOTALL)
NAME_PART   = r'(?:\[[^\]]+\]|"[^"]+"|[^\s\(\[\]"\.]+)'
NAME_PATTERN = rf"{NAME_PART}(?:\.{NAME_PART})*"
CREATE_VIEW_RE  = re.compile(rf"(?im)\bCREATE\s+VIEW\s+({NAME_PATTERN})")
CREATE_PROC_RE  = re.compile(rf"(?im)\bCREATE\s+PROCEDURE\s+({NAME_PATTERN})")
CREATE_FUNC_RE  = re.compile(rf"(?im)\bCREATE\s+FUNCTION\s+({NAME_PATTERN})")
CREATE_TABLE_RE = re.compile(rf"(?im)\bCREATE\s+TABLE\s+({NAME_PATTERN})[ \t]*(?=\()")

# --------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------
def strip_sql_comments(sql: str) -> str:
    """Remove SQL line and block comments safely."""
    def _block_repl(m):
        return re.sub(r"[^\r\n]", " ", m.group(0))
    sql = BLOCK_COMMENT_RE.sub(_block_repl, sql)
    sql = LINE_COMMENT_RE.sub("", sql)
    return sql

def normalize_object_name(name: str, default_schema: str) -> str:
    n = name.strip()
    if '"' in n:
        return n
    if '.' not in n:
        part = n if (n.startswith('[') and n.endswith(']')) else f'[{n}]'
        return f'[{default_schema}].{part}'
    parts = [p.strip() for p in n.split('.')]
    norm = []
    for p in parts:
        if p.startswith('[') and p.endswith(']'):
            norm.append(p)
        else:
            norm.append(f'[{p}]')
    return '.'.join(norm)

def make_idempotent(sql: str) -> str:
    sql = strip_sql_comments(sql)
    sql = GO_LINE_RE.sub("", sql)
    sql = USE_RE.sub("", sql)
    sql = CREATE_VIEW_RE.sub(lambda m: f"CREATE OR ALTER VIEW {m.group(1)}", sql)
    sql = CREATE_PROC_RE.sub(lambda m: f"CREATE OR ALTER PROCEDURE {m.group(1)}", sql)
    sql = CREATE_FUNC_RE.sub(lambda m: f"CREATE OR ALTER FUNCTION {m.group(1)}", sql)

    def table_repl(m):
        raw = m.group(1).strip()
        if raw.lstrip().startswith('#'):
            return f"CREATE TABLE {raw}"
        norm = normalize_object_name(raw, DEFAULT_SCHEMA)
        return (f"IF OBJECT_ID(N'{norm}','U') IS NOT NULL DROP TABLE {norm};\n"
                f"CREATE TABLE {norm}")
    sql = CREATE_TABLE_RE.sub(table_repl, sql)

    return sql.strip()

# --------------------------------------------------------------------
# Main
# --------------------------------------------------------------------
try:
    # ---- Ordered list of Silver files ----
    SQL_ORDER = [
        "mis.Silver_Restruct_SCD.sql",
        "mis.Silver_RestructState_SCD.sql",
        "mis.Silver_Restruct_Merged_SCD.sql",
        "mis.Silver_Client_UnhealedFlag.sql",
        "mis.Silver_Resp_SCD.sql",
        "mis.Silver_Stages_SCD.sql",
        # add more as needed
    ]

    # 1) Build full list in order first
    sql_files = []
    processed_names = set()
    all_files = sorted([f for f in os.listdir(source_folder) if f.lower().endswith('.sql')])

    for f in SQL_ORDER:
        full_path = os.path.join(source_folder, f)
        if os.path.exists(full_path):
            sql_files.append(f)
            processed_names.add(f)
        else:
            logging.warning(f"File listed in SQL_ORDER but not found: {full_path}")

    # 2) Append any remaining .sql files not in SQL_ORDER
    for f in all_files:
        if f not in processed_names:
            sql_files.append(f)

    logging.info(f"Total SQL files to process: {len(sql_files)}")

    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    with open(output_file, 'w', encoding='utf-8-sig') as f_out:
        # header
        f_out.write("-- =============================================\n")
        f_out.write("-- Compiled Stored Procedure for MSSQL Agent Job (Silver) - Idempotent\n")
        f_out.write(f"-- Generated: {datetime.now()}\n")
        f_out.write(f"-- Source folder: {source_folder}\n")
        f_out.write(f"-- Files included: {len(sql_files)}\n")
        for sf in sql_files:
            f_out.write(f"--   {sf}\n")
        f_out.write("-- Requires: SQL Server 2016 SP1+ for CREATE OR ALTER\n")
        f_out.write("-- =============================================\n\n")

        # preamble
        f_out.write(f"USE [{DB_NAME}];\nGO\n\n")
        f_out.write(f"IF OBJECT_ID('{DEFAULT_SCHEMA}.usp_SilverTables', 'P') IS NOT NULL\n")
        f_out.write(f"    DROP PROCEDURE {DEFAULT_SCHEMA}.usp_SilverTables;\nGO\n\n")
        f_out.write(f"CREATE PROCEDURE {DEFAULT_SCHEMA}.usp_SilverTables\nAS\nBEGIN\n")
        f_out.write("    SET NOCOUNT ON;\n")
        f_out.write("    DECLARE @sql NVARCHAR(MAX);\n\n")

        # process each file
        for sf in sql_files:
            try:
                logging.info(f"Processing file: {sf}")
                with open(os.path.join(source_folder, sf), 'r', encoding='utf-8-sig') as f_in:
                    content = f_in.read()
                    transformed = make_idempotent(content)
                    safe = transformed.replace("'", "''")
                    f_out.write(f"    -- Start of: {sf}\n")
                    f_out.write("    SET @sql = N'" + safe + "';\n")
                    f_out.write("    BEGIN TRY\n")
                    f_out.write("        EXEC sys.sp_executesql @sql;\n")
                    f_out.write("    END TRY\n")
                    f_out.write("    BEGIN CATCH\n")
                    f_out.write("        THROW;\n")
                    f_out.write("    END CATCH;\n\n")
                logging.info(f"Finished file: {sf}")
            except Exception as e:
                logging.error(f"Error processing {sf}: {e}")
                raise

        f_out.write("END\nGO\n")

    logging.info(f"✅ Stored procedure script generated successfully: {output_file}")
    print(f"✅ Stored procedure script generated successfully: {output_file}")

except Exception as e:
    logging.exception("💥 Fatal error during compilation")
    raise
