# compile_gold_tables_job_proc_idempotent.py
import os
import re
import logging
from datetime import datetime

# ---- Settings ----
DB_NAME        = "ATK"
DEFAULT_SCHEMA = "mis"   # only schema you can use
source_folder  = r"C:\ATK_Project\sql_scripts\Gold"
output_file    = r"C:\ATK_Project\compiled\compiled_gold_job_proc.sql"
log_file       = r"C:\ATK_Project\logs\compile_gold.log"

# ---- Logging ----
os.makedirs(os.path.dirname(log_file), exist_ok=True)
logging.basicConfig(
    filename=log_file,
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)
logging.info("=== Starting Gold SQL Compilation Job ===")

# --------------------------------------------------------------------
# Regexes
# --------------------------------------------------------------------
GO_LINE_RE   = re.compile(r"^\s*GO\s*$", re.IGNORECASE | re.MULTILINE)
USE_RE       = re.compile(r"^\s*USE\s+\[?[^\]\r\n]+]?\s*;\s*$",
                          re.IGNORECASE | re.MULTILINE)

# SQL comments
LINE_COMMENT_RE  = re.compile(r"--[^\r\n]*")
BLOCK_COMMENT_RE = re.compile(r"/\*.*?\*/", re.DOTALL)

# Object name pattern (schema.object, [quoted], "double-quoted")
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
    # 0) strip comments
    sql = strip_sql_comments(sql)
    # 1) remove GO/USE
    sql = GO_LINE_RE.sub("", sql)
    sql = USE_RE.sub("", sql)
    # 2) programmable objects → CREATE OR ALTER
    sql = CREATE_VIEW_RE.sub(lambda m: f"CREATE OR ALTER VIEW {m.group(1)}", sql)
    sql = CREATE_PROC_RE.sub(lambda m: f"CREATE OR ALTER PROCEDURE {m.group(1)}", sql)
    sql = CREATE_FUNC_RE.sub(lambda m: f"CREATE OR ALTER FUNCTION {m.group(1)}", sql)

    # 3) tables → drop-if-exists + create
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
    sql_files = sorted([f for f in os.listdir(source_folder)
                        if f.lower().endswith('.sql')])
    logging.info(f"Found {len(sql_files)} SQL files in {source_folder}")

    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    with open(output_file, 'w', encoding='utf-8-sig') as f_out:
        # header
        f_out.write("-- =============================================\n")
        f_out.write("-- Compiled Stored Procedure for MSSQL Agent Job (Gold) - Idempotent\n")
        f_out.write(f"-- Generated: {datetime.now()}\n")
        f_out.write(f"-- Source folder: {source_folder}\n")
        f_out.write(f"-- Files included: {len(sql_files)}\n")
        for sf in sql_files:
            f_out.write(f"--   {sf}\n")
        f_out.write("-- Requires: SQL Server 2016 SP1+ for CREATE OR ALTER\n")
        f_out.write("-- =============================================\n\n")

        # preamble
        f_out.write(f"USE [{DB_NAME}];\nGO\n\n")
        f_out.write(f"IF OBJECT_ID('{DEFAULT_SCHEMA}.usp_GoldTables', 'P') IS NOT NULL\n")
        f_out.write(f"    DROP PROCEDURE {DEFAULT_SCHEMA}.usp_GoldTables;\nGO\n\n")
        f_out.write(f"CREATE PROCEDURE {DEFAULT_SCHEMA}.usp_GoldTables\nAS\nBEGIN\n")
        f_out.write("    SET NOCOUNT ON;\n")
        f_out.write("    DECLARE @sql NVARCHAR(MAX);\n\n")

        # process each file
        for sf in sql_files:
            try:
                logging.info(f"Processing file: {sf}")
                with open(os.path.join(source_folder, sf), 'r',
                          encoding='utf-8-sig') as f_in:
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
