# compile_gold_tables_folder.py
from pathlib import Path
from datetime import datetime

# ---- configure your folder ----
MAIN_DIR  = Path(r"C:\ATK_Project\sql_scripts\Gold")
OUTPUT    = Path(r"C:\ATK_Project\compiled\manual_run\compiled_Gold_Tables.sql")

FALLBACK_ENCODINGS = ("utf-8-sig", "utf-8", "cp1250", "cp1252", "latin-1")
DIV = "-" * 100

# ---- list your files in the specific order you want first ----
SQL_ORDER = [
    "mis.Gold_Dim_AppUsers.sql",
    "mis.Gold_Dim_Branch.sql",
    "mis.Gold_Dim_Clients.sql",
    "mis.Gold_Dim_Credits.sql",
    "mis.Gold_Dim_EmployeePayrollData.sql",
    "mis.Gold_Dim_Employees.sql",
    "mis.Gold_Dim_EmployeesHistory.sql",
    "mis.Gold_Dim_Event_InProgress.sql",
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
    "V3__incremental_gold_fact_Restruct_Daily_Sold_Par.sql"
]

# ---- helper to read files with fallback encodings ----
def read_text_with_fallback(p: Path) -> str | None:
    for enc in FALLBACK_ENCODINGS:
        try:
            return p.read_text(encoding=enc)
        except Exception:
            continue
    return None

def compile_sql():
    # ---- 1) all .sql files in the folder
    all_files = sorted([f for f in MAIN_DIR.iterdir() if f.is_file() and f.suffix.lower() == ".sql"])

    # ---- 2) compute extra files not in SQL_ORDER
    extra_files = [f for f in all_files if f.name not in SQL_ORDER]
    if extra_files:
        print(f"ℹ Adding {len(extra_files)} extra files not listed in SQL_ORDER:")
        for f in extra_files:
            print(f"   {f.name}")

    # ---- 3) build final processing list: SQL_ORDER first, then extras
    sql_files = []
    processed_names = set()
    for fname in SQL_ORDER:
        fpath = MAIN_DIR / fname
        if fpath.exists():
            sql_files.append(fpath)
            processed_names.add(fname)
        else:
            print(f"⚠ Warning: file listed but not found -> {fpath}")

    sql_files.extend(extra_files)

    # ---- 4) header for compiled file
    header = (
        f"-- Compiled SQL bundle\n"
        f"-- Generated: {datetime.now():%Y-%m-%d %H:%M:%S}\n"
        f"-- Source folder: {MAIN_DIR}\n"
        f"-- Files ({len(sql_files)}):\n--   " + "\n--   ".join([f.name for f in sql_files]) + "\n"
        f"{DIV}\n\nSET NOCOUNT ON;\n\n"
    )

    processed = set()  # track absolute paths to avoid duplicates

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT.open("w", encoding="utf-8", newline="\n") as out:
        out.write(header)

        for f in sql_files:
            if f.resolve() in processed:
                continue
            processed.add(f.resolve())

            content = read_text_with_fallback(f)
            out.write(f"{DIV}\n-- Start of: {f.name}\n{DIV}\n")
            out.write((content.rstrip() if content else "-- Could not decode file") + "\n")
            out.write(f"{DIV}\n-- End of:   {f.name}\n{DIV}\n\n")
            out.write("GO\n\n")

    print(f"✅ Compiled SQL file created at: {OUTPUT}")

if __name__ == "__main__":
    compile_sql()
