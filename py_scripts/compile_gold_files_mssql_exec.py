# compile_gold_tables_job_proc_idempotent_with_logging_v3.py
import re
import logging
from datetime import datetime
from pathlib import Path

# ---- Settings ----
DB_NAME        = "ATK"
DEFAULT_SCHEMA = "mis"
SOURCE_FOLDER  = Path(r"C:\ATK_Project\sql_scripts\Gold")
OUTPUT_FILE    = Path(r"C:\ATK_Project\compiled\compiled_gold_job_proc.sql")
LOG_FILE       = Path(r"C:\ATK_Project\logs\compile_gold.log")
LOG_TABLE      = f"{DEFAULT_SCHEMA}.Gold_Proc_Exec_Log"

# ---- Logging ----
LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
logging.basicConfig(
    filename=str(LOG_FILE),
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)
logging.info("=== Starting Gold SQL Compilation Job ===")

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
    def _block_repl(m): return re.sub(r"[^\r\n]", " ", m.group(0))
    sql = BLOCK_COMMENT_RE.sub(_block_repl, sql)
    sql = LINE_COMMENT_RE.sub("", sql)
    return sql

def normalize_object_name(name: str, default_schema: str) -> str:
    n = name.strip().strip('"')
    if n.startswith('#'):
        return n  # temp table
    n = n.strip('[]')
    obj_name = n.split('.', 1)[-1] if '.' in n else n
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
    
    SQL_ORDER = [
        "mis.Gold_Dim_AppUsers.sql",
        "mis.Gold_Dim_Branch.sql",
        "mis.Gold_Dim_Clients.sql",
        "mis.Gold_Dim_Credits.sql",
        "mis.Gold_Dim_EmployeePayrollData.sql",
        "mis.Gold_Dim_Employees.sql",
        "mis.Gold_Dim_EmployeesHistory.sql",
        "mis.Gold_Dim_Events.sql",
        "mis.Gold_Dim_GroupMembershipPeriods.sql",
        "mis.Gold_Dim_PartnersBranch.sql",
        "mis.Gold_Fact_AdminTasks.sql",
        "mis.Gold_Fact_ArchiveDocument.sql",
        "mis.Gold_Fact_BudgetEmployees.sql",
        "mis.Gold_Fact_CerereOnline.sql",
        "mis.Gold_Fact_Comments.sql",
        "mis.Gold_Fact_CPD.sql",
        "mis.Gold_Fact_CreditsInShadowBranches.sql",
        "mis.Gold_Fact_WriteOffCredits.sql",
        "mis.Gold_Fact_Restruct_Daily_Min.sql",
        "mis.Gold_Fact_Disbursement.sql",
        "mis.Gold_Fact_Sold_Par.sql",
        "V2__inc_Gold_Dim_Event_InProgress.sql",
        "V2__inc_Gold_Dim_Event_Responsible.sql",
        "V2__inc_Gold_Dim_Limits.sql",
        "V3__inc_Gold_Fact_Restruct_Daily_Sold_Par.sql"
    ]

    sql_files = [SOURCE_FOLDER / f for f in SQL_ORDER if (SOURCE_FOLDER / f).exists()]
    logging.info(f"Total SQL files to process: {len(sql_files)}")

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT_FILE.open("w", encoding="utf-8-sig") as f_out:
        # Header
        f_out.write("-- =============================================\n")
        f_out.write("-- Compiled Stored Procedure for MSSQL Agent Job (Gold) - Idempotent with Logging\n")
        f_out.write(f"-- Generated: {datetime.now()}\n")
        f_out.write(f"-- Source folder: {SOURCE_FOLDER}\n")
        f_out.write(f"-- Files included: {len(sql_files)}\n")
        for sf in sql_files:
            f_out.write(f"--   {sf.name}\n")
        f_out.write("-- Requires: SQL Server 2016 SP1+ for CREATE OR ALTER\n")
        f_out.write("-- =============================================\n\n")

        # Procedure header
        f_out.write(f"USE [{DB_NAME}];\nGO\n\n")
        f_out.write(f"IF OBJECT_ID('{DEFAULT_SCHEMA}.usp_GoldTables', 'P') IS NOT NULL\n")
        f_out.write(f"    DROP PROCEDURE {DEFAULT_SCHEMA}.usp_GoldTables;\nGO\n\n")
        f_out.write(f"CREATE PROCEDURE {DEFAULT_SCHEMA}.usp_GoldTables\nAS\nBEGIN\n")
        f_out.write("    SET NOCOUNT ON;\n")
        f_out.write("    DECLARE @sql NVARCHAR(MAX);\n")
        f_out.write("    DECLARE @StartTime DATETIME;\n")
        f_out.write("    DECLARE @EndTime DATETIME;\n")
        f_out.write("    DECLARE @Status NVARCHAR(50);\n\n")
        f_out.write("    DECLARE @FailureNote NVARCHAR(MAX);\n\n")

        for sf in sql_files:
            try:
                logging.info(f"Processing file: {sf.name}")
                with sf.open("r", encoding="utf-8-sig") as f_in:
                    content = f_in.read()
                    transformed = make_idempotent(content)
                    safe = transformed.replace("'", "''")
                    if safe.strip():
                        f_out.write(f"    -- Start of: {sf.name}\n")
                        f_out.write("    SET @StartTime = GETDATE();\n")
                        f_out.write("    SET @EndTime = NULL;\n")
                        f_out.write("    SET @Status = 'Running';\n")
                        f_out.write("    SET @sql = N'" + safe + "';\n")

                        # Fail-safe TRY/CATCH with logging
                        f_out.write("    BEGIN TRY\n")
                        f_out.write("        SET @FailureNote = '';\n")
                        f_out.write("        EXEC sys.sp_executesql @sql;\n")
                        f_out.write("        SET @Status = 'Success';\n")
                        f_out.write("    END TRY\n")
                        f_out.write("    BEGIN CATCH\n")
                        f_out.write("        SET @Status = 'Failed';\n")
                        f_out.write("        SET @FailureNote = CONCAT(\n")
                        f_out.write("            'Msg: ', ERROR_MESSAGE(),\n")
                        f_out.write("            ' | Line: ', ERROR_LINE(),\n")
                        f_out.write("            ' | Number: ', ERROR_NUMBER()\n")
                        f_out.write("        );\n")
                        f_out.write("        -- Continue to next file without THROW\n")
                        f_out.write("    END CATCH;\n\n")

                        # Logging always runs
                        f_out.write("    SET @EndTime = GETDATE();\n")
                        f_out.write(f"    INSERT INTO {LOG_TABLE} (TableName, StartTime, EndTime, Status, Failure_Note)\n")
                        f_out.write(f"    VALUES ('{sf.stem}', @StartTime, @EndTime, @Status, @FailureNote);\n\n")

                logging.info(f"Finished file: {sf.name}")
            except Exception as e:
                logging.error(f"Error processing {sf.name}: {e}")
                raise

        # Procedure end
        f_out.write("END\nGO\n")

    logging.info(f"✅ Stored procedure script generated successfully: {OUTPUT_FILE}")
    print(f"✅ Stored procedure script generated successfully: {OUTPUT_FILE}")

except Exception as e:
    logging.exception("💥 Fatal error during compilation")
    raise