# compile_silver_tables_job_proc_idempotent.py  (Gold version)
import os
import re
from datetime import datetime

# ---- Settings ----
DB_NAME        = "ATK"
DEFAULT_SCHEMA = "mis"   # you only have access to schema mis

# Folders/files
source_folder = r"C:\ATK_Project\sql_scripts\Gold"
output_file   = r"C:\ATK_Project\compiled\compiled_gold_job_proc.sql"

# --- Regexes (Unicode-friendly) ---
GO_LINE_RE   = re.compile(r"^\s*GO\s*$", re.IGNORECASE | re.MULTILINE)
USE_RE       = re.compile(r"^\s*USE\s+\[?[^\]\r\n]+]?\s*;\s*$", re.IGNORECASE | re.MULTILINE)

# Object name after CREATE <thing> <name>
# \w matches Unicode letters in Python 3; allow dots, brackets, double-quotes, spaces
OBJ_NAME = r'([\w\.\[\]" ]+)'

CREATE_VIEW_RE = re.compile(r"\bCREATE\s+VIEW\s+" + OBJ_NAME, re.IGNORECASE)
CREATE_PROC_RE = re.compile(r"\bCREATE\s+PROCEDURE\s+" + OBJ_NAME, re.IGNORECASE)
CREATE_FUNC_RE = re.compile(r"\bCREATE\s+FUNCTION\s+" + OBJ_NAME, re.IGNORECASE)
CREATE_TABLE_RE= re.compile(r"\bCREATE\s+TABLE\s+" + OBJ_NAME, re.IGNORECASE)

def normalize_object_name(name: str, default_schema: str) -> str:
    """
    Ensure schema-qualified; preserve [] / "" if present; don't double-bracket.
    If schema is missing, use [<default_schema>].<name>
    """
    n = name.strip()
    if '"' in n:
        return n  # already quoted like "schema"."obj"
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
    For CREATE VIEW/PROC/FUNC: rewrite to CREATE OR ALTER and
    schema-qualify the name if it's unqualified (force into DEFAULT_SCHEMA).
    """
    def repl(m):
        raw = m.group(1).strip()
        # If already contains a dot (schema.), keep as-is; else add DEFAULT_SCHEMA
        if '.' in raw or '"' in raw:
            qualified = raw
        else:
            qualified = f'[{DEFAULT_SCHEMA}].' + (raw if (raw.startswith('[') and raw.endswith(']')) else f'[{raw}]')
        prefix = "CREATE OR ALTER " + ("VIEW" if regex is CREATE_VIEW_RE else
                                       "PROCEDURE" if regex is CREATE_PROC_RE else
                                       "FUNCTION")
        return f"{prefix} {qualified}"
    return regex.sub(repl, create_stmt)

def make_idempotent(sql: str) -> str:
    """
    Transform one SQL file into idempotent form suitable for dynamic execution:
    - strip GO/USE
    - CREATE VIEW/PROC/FUNCTION -> CREATE OR ALTER + ensure DEFAULT_SCHEMA when unqualified
    - CREATE TABLE T -> IF OBJECT_ID('T','U') IS NOT NULL DROP TABLE T; CREATE TABLE T ...
      (skips #temp tables; forces DEFAULT_SCHEMA when unqualified)
    """
    # Remove GO and USE
    sql = GO_LINE_RE.sub("", sql)
    sql = USE_RE.sub("", sql)

    # CREATE OR ALTER + schema-qualify programmable objects
    sql = qualify_programmable_object(sql, CREATE_VIEW_RE)
    sql = qualify_programmable_object(sql, CREATE_PROC_RE)
    sql = qualify_programmable_object(sql, CREATE_FUNC_RE)

    # Tables: rewrite to DROP (if exists) + CREATE, skip temp tables
    def table_repl(m):
        raw = m.group(1).strip()
        # skip temp tables (# / ##)
        if raw.lstrip().startswith('#'):
            return f"CREATE TABLE {raw}"
        norm = normalize_object_name(raw, DEFAULT_SCHEMA)
        return (f"IF OBJECT_ID(N'{norm}','U') IS NOT NULL DROP TABLE {norm};\n"
                f"CREATE TABLE {norm}")
    sql = CREATE_TABLE_RE.sub(table_repl, sql)

    return sql.strip()

# Collect all .sql files in source folder
sql_files = sorted([f for f in os.listdir(source_folder) if f.lower().endswith('.sql')])

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

    # Set database (outside procedure)
    f_out.write(f"USE [{DB_NAME}];\nGO\n\n")

    # Drop & create wrapper procedure IN mis schema
    f_out.write(f"IF OBJECT_ID('{DEFAULT_SCHEMA}.usp_CompileGoldTables', 'P') IS NOT NULL\n")
    f_out.write(f"    DROP PROCEDURE {DEFAULT_SCHEMA}.usp_CompileGoldTables;\nGO\n\n")
    f_out.write(f"CREATE PROCEDURE {DEFAULT_SCHEMA}.usp_CompileGoldTables\nAS\nBEGIN\n")
    f_out.write("    SET NOCOUNT ON;\n")
    f_out.write("    DECLARE @sql NVARCHAR(MAX);\n\n")

    # Process each file as a single dynamic-SQL batch
    for sf in sql_files:
        f_out.write("    -- =============================================\n")
        f_out.write(f"    -- Start of: {sf}\n")
        f_out.write("    -- =============================================\n\n")

        with open(os.path.join(source_folder, sf), 'r', encoding='utf-8-sig') as f_in:
            content = f_in.read()
            transformed = make_idempotent(content)

            # Build dynamic SQL safely: only double single-quotes; keep real newlines.
            safe = transformed.replace("'", "''")
            f_out.write("    SET @sql = N'")
            f_out.write(safe)
            f_out.write("';\n")
            f_out.write("    BEGIN TRY\n")
            f_out.write("        EXEC sys.sp_executesql @sql;\n")
            f_out.write("    END TRY\n")
            f_out.write("    BEGIN CATCH\n")
            f_out.write("        THROW; -- bubble up for Agent visibility\n")
            f_out.write("    END CATCH;\n\n")

        f_out.write(f"    -- End of: {sf}\n")
        f_out.write("    -- =============================================\n\n")

    # Close procedure
    f_out.write("END\nGO\n")

print(f"Stored procedure script generated: {output_file}")
