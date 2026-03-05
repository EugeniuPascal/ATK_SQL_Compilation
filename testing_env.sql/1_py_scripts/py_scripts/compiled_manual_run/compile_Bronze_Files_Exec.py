# compile_bronze_tables_folder_with_log_fixed.py
from pathlib import Path
from datetime import datetime
import re

# ---- Settings ----
MAIN_DIR = Path(r"C:\ATK_Project\sql_scripts\Bronze")
OUTPUT   = Path(r"C:\ATK_Project\compiled\manual_run\compiled_Bronze_Tables.sql")
LOG_TABLE = "mis.Bronze_Proc_Exec_Log"

FALLBACK_ENCODINGS = ("utf-8-sig", "utf-8", "cp1250", "cp1252", "latin-1")
DIV = "-" * 100

SQL_ORDER = [
    "mis.Bronze_Документы.ЗаявкаНаКредит.sql",
    "mis.Bronze_Документы.НаправлениеНаВыплату.sql",
    "mis.Bronze_Документы.ОбъединеннаяИнтернетЗаявка.sql",
    "mis.Bronze_Документы.ОбъединеннаяИнтернетЗаявка.РискФакторы.sql",
    "mis.Bronze_Документы.ПротоколКомитета.sql",
    "mis.Bronze_Документы.События.sql",
    "mis.Bronze_Документы.УстановкаДанныхКредита.sql",
    "mis.Bronze_Задачи.ЗадачаАдминистратораКредитов.sql",   
    "mis.Bronze_Задачи.ЗадачаАдминистратораКредитов.ИсторияСтатусов.sql",
    "mis.Bronze_РегистрыСведений.АнулированныеКредитыПартнеров.sql",   
    "mis.Bronze_РегистрыСведений.Валюта.sql",
    "mis.Bronze_РегистрыСведений.ДанныеКредитовВыданных.sql",
    "mis.Bronze_РегистрыСведений.КредитыВТеневыхФилиалах.sql",
    "mis.Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным.sql",
    "mis.Bronze_РегистрыСведений.РеструктурированныеКредиты.sql",
    "mis.Bronze_РегистрыСведений.СведенияОНаправленияхНаВыплату.sql",
    "mis.Bronze_РегистрыСведений.СведенияОПользователяхМобильногоПриложения.sql",
    "mis.Bronze_РегистрыСведений.СведенияОПрочихДоходахКлиента.sql",
    "mis.Bronze_РегистрыСведений.СостоянияРеструктурированныхКредитов.sql",
    "mis.Bronze_РегистрыСведений.СотрудникиДанныеПоЗарплате.sql",
    "mis.Bronze_РегистрыСведений.СтатусыКредитовВыданных.sql",
    "mis.Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки.sql",
    "mis.Bronze_РегистрыСведений.УсловияПослеВыдачиКредита.sql",
    "mis.Bronze_Справочники.Дилеры.sql",
    "mis.Bronze_Справочники.Контрагенты.sql",
    "mis.Bronze_Справочники.Кредиты.sql",
    "mis.Bronze_Справочники.ТипыЗадачАдминистратораКредитов.sql",
    "mis.Bronze_Справочники.ТипыЗадачАдминистратораКредитов_ИсторияПоказателей.sql",
    "mis.Bronze_Справочники.ФилиалыКонтрагентов.sql",
    "mis.Bronze_Справочники.ФинансовыеПродукты.sql"
]

# Remove GO lines from content
GO_RE = re.compile(r"^\s*GO\s*$", re.IGNORECASE | re.MULTILINE)

# --------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------
def read_text_with_fallback(p: Path) -> str | None:
    """Try multiple encodings to safely read SQL text files."""
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
        f"-- Compiled SQL bundle (Bronze) with Logging (Dynamic Execution)\n"
        f"-- Generated: {datetime.now():%Y-%m-%d %H:%M:%S}\n"
        f"-- Source folder: {MAIN_DIR}\n"
        f"-- Files ({len(sql_files)}):\n--   " + "\n--   ".join(f.name for f in sql_files) + "\n"
        f"{DIV}\n\nSET NOCOUNT ON;\n\n"
        f"DECLARE @StartTime DATETIME;\n"
        f"DECLARE @EndTime DATETIME;\n"
        f"DECLARE @Status NVARCHAR(50);\n"
        f"DECLARE @sql NVARCHAR(MAX);\n"
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

            # TRY/CATCH block
            out.write("    BEGIN TRY\n")
            if content and safe_sql.strip():
                out.write("        SET @FailureNote = '';\n")
                out.write(f"        SET @sql = N'{safe_sql}';\n")
                out.write("        EXEC sys.sp_executesql @sql;\n")
                out.write("        SET @Status = 'Success';\n")
            else:
                out.write("        SET @Status = 'Failed';\n")
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

            # Logging
            out.write("    SET @EndTime = GETDATE();\n")
            out.write(f"    INSERT INTO {LOG_TABLE} (TableName, StartTime, EndTime, Status, Failure_Note)\n")
            out.write(f"    VALUES ('{table_name}', @StartTime, @EndTime, @Status, @FailureNote);\n")

            out.write("END\n\n")
            out.write(f"{DIV}\n-- End of: {f.name}\n{DIV}\n\n")

    print(f"✅ Compiled SQL file with dynamic execution and logging created at: {OUTPUT}")

if __name__ == "__main__":
    compile_sql_dynamic()