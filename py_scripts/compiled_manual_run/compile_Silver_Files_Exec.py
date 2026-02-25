# compile_silver_tables_folder_with_log_dynamic.py
from pathlib import Path
from datetime import datetime
import re

# ---- configure your folder ----
MAIN_DIR  = Path(r"C:\ATK_Project\sql_scripts\Silver")
OUTPUT    = Path(r"C:\ATK_Project\compiled\manual_run\compiled_Silver_Tables.sql")
LOG_TABLE = "mis.Silver_Proc_Exec_Log"

FALLBACK_ENCODINGS = ("utf-8-sig", "utf-8", "cp1250", "cp1252", "latin-1")
DIV = "-" * 100

# ---- strictly ordered files with comments ----
SQL_ORDER = [
    # independent
    "mis.Silver_Employee_User.sql",
    "mis.Silver_CommiteeProtocol.sql",

    # creates Gold_Fact_CerereOnline
    "mis.Silver_EmployeesPosition_SCD.sql",
    "mis.Silver_CerereOnline_base.sql",

    # below table execution order to create mis.Gold_Fact_Restruct_Daily_Min 
    "mis.Silver_Restruct_SCD.sql",    
    "mis.Silver_RestructState_SCD.sql",
    "mis.Silver_Restruct_Merged_SCD.sql",
    "mis.Silver_Client_UnhealedFlag.sql",
    "mis.Silver_Resp_SCD.sql",
    "mis.Silver_Stages_SCD.sql",

    # below table execution order to create mis.Gold_Fact_CPD_Sold 
    "mis.Silver_SCD_GroupMembershipPeriods.sql", 
    "mis.Silver_Sold_Owner.sql",
    "mis.Silver_Limits.sql",
    "mis.Silver_Conditions_After_Disb.sql",
    "mis.Silver_CPD_TaskDays.sql"
]

# ---- remove GO lines ----
GO_RE = re.compile(r"^\s*GO\s*$", re.IGNORECASE | re.MULTILINE)

# ---- helper to read files with fallback encodings ----
def read_text_with_fallback(p: Path) -> str | None:
    for enc in FALLBACK_ENCODINGS:
        try:
            return p.read_text(encoding=enc)
        except Exception:
            continue
    return None

def escape_sql_string(text: str) -> str:
    """Escape single quotes for NVARCHAR literal."""
    return text.replace("'", "''")

# --------------------------------------------------------------------
# Main compilation
# --------------------------------------------------------------------
def compile_sql_dynamic():
    # Build final list strictly from SQL_ORDER
    sql_files = []
    for fname in SQL_ORDER:
        fpath = MAIN_DIR / fname
        if fpath.exists():
            sql_files.append(fpath)
        else:
            print(f"⚠ Warning: file listed in SQL_ORDER not found -> {fpath}")

    header = (
        f"-- Compiled SQL bundle (Silver) with Logging (Dynamic Execution)\n"
        f"-- Generated: {datetime.now():%Y-%m-%d %H:%M:%S}\n"
        f"-- Source folder: {MAIN_DIR}\n"
        f"-- Files ({len(sql_files)}):\n--   " + "\n--   ".join([f.name for f in sql_files]) + "\n"
        f"{DIV}\n\nSET NOCOUNT ON;\n\n"
        f"DECLARE @StartTime DATETIME;\n"
        f"DECLARE @EndTime DATETIME;\n"
        f"DECLARE @Status NVARCHAR(50);\n"
        f"DECLARE @sql NVARCHAR(MAX);\n\n"
    )

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT.open("w", encoding="utf-8", newline="\n") as out:
        out.write(header)

        for f in sql_files:
            content = read_text_with_fallback(f)
            table_name = f.stem

            if content:
                content = GO_RE.sub("", content)
                safe_sql = escape_sql_string(content)

            out.write(f"{DIV}\n-- Start of: {f.name}\n{DIV}\n")

            out.write("BEGIN\n")
            out.write("    SET @StartTime = GETDATE();\n")
            out.write("    SET @Status = 'Running';\n\n")

            # Dynamic SQL execution with TRY/CATCH
            out.write("    BEGIN TRY\n")
            if content and safe_sql.strip():
                out.write(f"        SET @sql = N'{safe_sql}';\n")
                out.write("        EXEC sys.sp_executesql @sql;\n")
                out.write("        SET @Status = 'Success';\n")
            else:
                out.write("        SET @Status = 'Failed'; -- could not read/parse file\n")
            out.write("    END TRY\n")
            out.write("    BEGIN CATCH\n")
            out.write("        SET @Status = 'Failed';\n")
            out.write("        -- Continue to next file without throwing\n")
            out.write("    END CATCH;\n\n")

            # Logging always runs
            out.write("    SET @EndTime = GETDATE();\n")
            out.write(f"    INSERT INTO {LOG_TABLE} (TableName, StartTime, EndTime, Status)\n")
            out.write(f"    VALUES ('{table_name}', @StartTime, @EndTime, @Status);\n")

            out.write("END\n\n")
            out.write(f"{DIV}\n-- End of: {f.name}\n{DIV}\n\n")

    print(f"✅ Compiled SQL file with dynamic execution and logging created at: {OUTPUT}")

if __name__ == "__main__":
    compile_sql_dynamic()