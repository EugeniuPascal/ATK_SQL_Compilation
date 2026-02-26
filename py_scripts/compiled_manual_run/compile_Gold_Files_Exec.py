# compile_gold_tables_folder_with_log_safe.py
from pathlib import Path
from datetime import datetime
import re

# ---- configure your folder ----
MAIN_DIR  = Path(r"C:\ATK_Project\sql_scripts\Gold")
OUTPUT    = Path(r"C:\ATK_Project\compiled\manual_run\compiled_Gold_Tables.sql")
LOG_TABLE = "mis.Gold_Proc_Exec_Log"

FALLBACK_ENCODINGS = ("utf-8-sig", "utf-8", "cp1250", "cp1252", "latin-1")
DIV = "-" * 100


SQL_ORDER = [
    "mis.Gold_Dim_AppUsers.sql",
    #broken
    "mis.Gold_Dim_Branch.sql",
    #"mis.Gold_Dim_Clients.sql",
    #"mis.Gold_Dim_Credits.sql",
    "mis.Gold_Dim_EmployeePayrollData.sql",
    #broken
    "mis.Gold_Dim_Employees.sql",
    #"mis.Gold_Dim_EmployeesHistory.sql",
    #"mis.Gold_Dim_Events.sql",
    "mis.Gold_Dim_GroupMembershipPeriods.sql",
    #"mis.Gold_Dim_PartnersBranch.sql",
    #"mis.Gold_Fact_AdminTasks.sql",
    #"mis.Gold_Fact_ArchiveDocument.sql",
    #broken
    "mis.Gold_Fact_BudgetEmployees.sql",
    #"mis.Gold_Fact_CerereOnline.sql",
    "mis.Gold_Fact_Comments.sql",
    "mis.Gold_Fact_CPD.sql",
    "mis.Gold_Fact_CreditsInShadowBranches.sql",
    "mis.Gold_Fact_WriteOffCredits.sql"
    #"mis.Gold_Fact_Restruct_Daily_Min.sql",
    #"mis.Gold_Fact_Disbursement.sql",
    #"mis.Gold_Fact_Sold_Par.sql",
    #"V2__inc_Gold_Dim_Event_InProgress.sql",
    #"V2__inc_Gold_Dim_Event_Responsible.sql",
    #"V2__inc_Gold_Dim_Limits.sql",
    #"V3__inc_Gold_Fact_Restruct_Daily_Sold_Par.sql"
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
    sql_files = []
    for fname in SQL_ORDER:
        fpath = MAIN_DIR / fname
        if fpath.exists():
            sql_files.append(fpath)
        else:
            print(f"⚠ Warning: file listed in SQL_ORDER not found -> {fpath}")

    header = (
        f"-- Compiled SQL bundle (Gold) with Logging (Dynamic Execution)\n"
        f"-- Generated: {datetime.now():%Y-%m-%d %H:%M:%S}\n"
        f"-- Source folder: {MAIN_DIR}\n"
        f"-- Files ({len(sql_files)}):\n--   " + "\n--   ".join([f.name for f in sql_files]) + "\n"
        f"{DIV}\n\nSET NOCOUNT ON;\n\n"
        f"DECLARE @StartTime DATETIME;\n"
        f"DECLARE @EndTime DATETIME;\n"
        f"DECLARE @Status NVARCHAR(50);\n"
        f"DECLARE @sql NVARCHAR(MAX);\n\n"
        f"DECLARE @FailureNote NVARCHAR(MAX);\n\n"
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
                out.write("        SET @FailureNote = '';\n")
                out.write(f"        SET @sql = N'{safe_sql}';\n")
                out.write("        EXEC sys.sp_executesql @sql;\n")
                out.write("        SET @Status = 'Success';\n")
            else:
                out.write("        SET @Status = 'Failed'; -- could not read/parse file\n")
                out.write("        SET @FailureNote = N'File could not be read or parsed';\n")
            out.write("    END TRY\n")
            out.write("    BEGIN CATCH\n")
            out.write("        SET @Status = 'Failed';\n")
            out.write("        SET @FailureNote = CONCAT(\n")
            out.write("            'Msg: ', ERROR_MESSAGE(),\n")
            out.write("            ' | Line: ', ERROR_LINE(),\n")
            out.write("            ' | Number: ', ERROR_NUMBER()\n")
            out.write("        );\n")
            out.write("    END CATCH;\n\n")

            # Logging always runs
            out.write("    SET @EndTime = GETDATE();\n")
            out.write(f"    INSERT INTO {LOG_TABLE} (TableName, StartTime, EndTime, Status, Failure_Note)\n")
            out.write(f"    VALUES ('{table_name}', @StartTime, @EndTime, @Status, @FailureNote);\n")

            out.write("END\n\n")
            out.write(f"{DIV}\n-- End of: {f.name}\n{DIV}\n\n")

    print(f"✅ Compiled Gold SQL file with dynamic execution and logging created at: {OUTPUT}")


if __name__ == "__main__":
    compile_sql_dynamic()