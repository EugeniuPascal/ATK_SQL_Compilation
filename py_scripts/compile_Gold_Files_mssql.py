# compile_gold_tables_job_proc_idempotent_clean.py
import os
import re
import logging
from datetime import datetime

# ---- Settings ----
DB_NAME        = "ATK"
DEFAULT_SCHEMA = "mis"   # you only have access to schema mis

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
USE_RE       = re.compile(r"^\s*USE\s+\[?[^\]\r\n]+]?\s*;\s*$", re.IGNORECASE | re.MULTILINE)

# SQL comments
LINE_COMMENT_RE  = re.compile(r"--[^\r\n]*")
BLOCK_COMMENT_RE = re.compile(r"/\*.*?\*/", re.DOTALL)

# Robust name pattern: allows [bracketed], "quoted", or bare parts separated by dots
# - A part is either: [ ... ]  |  " ... "  |  bare-no-whitespace/dot/bracket/quote
NAME_PART   = r'(?:\[[^\]]+\]|"[^"]+"|[^\s\(\[\]"\.]+)'
NAME_PATTERN = rf"{NAME_PART}(?:\.{NAME_PART})*"

# Anchored, multiline patterns for programmable objects and tables
CREATE_VIEW_RE  = re.compile(rf"(?im)^[ \t]*CREATE[ \t]+VIEW[ \t]+({NAME_PATTERN})")
CREATE_PROC_RE  = re.compile(rf"(?im)^[ \t]*CREATE[ \t]+PROCEDURE[ \t]+({NAME_PATTERN})")
CREATE_FUNC_RE  = re.compile(rf"(?im)^[ \t]*CREATE[ \t]+FUNCTION[ \t]+({NAME_PATTERN})")

# Require '(' right after the table name (ignoring spaces) so we only hit real headers
CREATE_TABLE_RE = re.compile(rf"(?im)^[ \t]*CREATE[ \t]+TABLE[ \t]+({NAME_PATTERN})[ \t]*(?=\()")

def strip_sql_comments(sql: str) -> str:
    """
    Remove SQL block and line comments, preserving newlines to avoid
    shifting line numbers too much.
    """
    # Replace block comments with spaces/newlines preserved
    def _block_repl(m):
        text = m.group(0)
        # keep \r and \n, blank other chars to spaces
        return re.sub(r"[^\r\n]", " ", text)
    sql = BLOCK_COMMENT_RE.sub(_block_repl, sql)
    # Remove line comments
    sql = LINE_COMMENT_RE.sub("", sql)
    return sql

def normalize_object_name(name: str, default_schema: str) -> str:
    n = name.strip()
    # If double-quoted, assume caller knows what they're doing
    if '"' in n:
        return n
    # Temp tables or local names without schema
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

def qualify_programmable_object(create_stmt: str, regex: re.Pattern) -> str:
    """
    Turn 'CREATE VIEW/PROCEDURE/FUNCTION <name>' into
    'CREATE OR ALTER <TYPE> <schema-qualified name>'.
    """
    def repl(m):
        raw = m.group(1).strip()
        # Already qualified? keep; else add default schema
        if '.' in raw or '"' in raw or (raw.startswith('[') and '].[' in raw):
            qualified = raw
        else:
            qualified = f'[{DEFAULT_SCHEMA}].' + (raw if (raw.startswith('[') and raw.endswith(']')) else f'[{raw}]')
        # Determine keyword from which regex we’re using
        if regex is CREATE_VIEW_RE:
            kind = "VIEW"
        elif regex is CREATE_PROC_RE:
            kind = "PROCEDURE"
        else:
            kind = "FUNCTION"
        return f"CREATE OR ALTER {kind} {qualified}"
    return regex.sub(repl, create_stmt)

def make_idempotent(sql: str) -> str:
    # 1) Remove comments first (prevents matching prose like "Create the table" in comments)
    sql = strip_sql_comments(sql)

    # 2) Remove GO and USE
    sql = GO_LINE_RE.sub("", sql)
    sql = USE_RE.sub("", sql)

    # 3) Programmable objects -> CREATE OR ALTER + schema-qualify
    sql = qualify_programmable_object(sql, CREATE_VIEW_RE)
    sql = qualify_programmable_object(sql, CREATE_PROC_RE)
    sql = qualify_programmable_object(sql, CREATE_FUNC_RE)

    # 4) Tables -> drop-if-exists + create; ignore temp tables
    def table_repl(m):
        raw = m.group(1).strip()
        if raw.lstrip().startswith('#'):  # temp table
            return f"CREATE TABLE {raw}"
        norm = normalize_object_name(raw, DEFAULT_SCHEMA)
        return f"IF OBJECT_ID(N'{norm}','U') IS NOT NULL DROP TABLE {norm};\nCREATE TABLE {norm}"
    sql = CREATE_TABLE_RE.sub(table_repl, sql)

    return sql.strip()

try:
    sql_files = sorted([f for f in os.listdir(source_folder) if f.lower().endswith('.sql')])
    logging.info(f"Found {len(sql_files)} SQL files in {source_folder}")

    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    with open(output_file, 'w', encoding='utf-8-sig') as f_out:
        # Header
        f_out.write("-- =============================================\n")
        f_out.write("-- Compiled Stored Procedure for MSSQL Agent Job (Gold) - Idempotent\n")
        f_out.write(f"-- Generated: {datetime.now()}\n")
        f_out.write(f"-- Source folder: {source_folder}\n")
        f_out.write(f"-- Files included: {len(sql_files)}\n")
        for sf in sql_files:
            f_out.write(f"--   {sf}\n")
        f_out.write("-- Requires: SQL Server 2016 SP1+ for CREATE OR ALTER\n")
        f_out.write("-- =============================================\n\n")

        # Database
        f_out.write(f"USE [{DB_NAME}];\nGO\n\n")

        # Drop & create procedure
        f_out.write(f"IF OBJECT_ID('{DEFAULT_SCHEMA}.usp_CompileGoldTables', 'P') IS NOT NULL\n")
        f_out.write(f"    DROP PROCEDURE {DEFAULT_SCHEMA}.usp_CompileGoldTables;\nGO\n\n")
        f_out.write(f"CREATE PROCEDURE {DEFAULT_SCHEMA}.usp_CompileGoldTables\nAS\nBEGIN\n")
        f_out.write("    SET NOCOUNT ON;\n\n")

        # Insert each file directly (no dynamic SQL)
        for sf in sql_files:
            try:
                logging.info(f"Processing file: {sf}")
                with open(os.path.join(source_folder, sf), 'r', encoding='utf-8-sig') as f_in:
                    content = f_in.read()
                    transformed = make_idempotent(content)
                    f_out.write(f"    -- Start of: {sf}\n")
                    # indent each line by 4 spaces
                    for line in transformed.splitlines():
                        f_out.write("    " + line + "\n")
                    f_out.write(f"    -- End of: {sf}\n\n")
                logging.info(f"Finished file: {sf}")
            except Exception as e:
                logging.error(f"Error processing {sf}: {e}")
                raise

        # End procedure
        f_out.write("END\nGO\n")

    logging.info(f"✅ Stored procedure script generated successfully: {output_file}")

except Exception as e:
    logging.exception("💥 Fatal error during compilation")
    raise
