# compile_bronze_tables_folder_strict.py
from pathlib import Path
from datetime import datetime

# ---- configure your folder ----
MAIN_DIR  = Path(r"C:\ATK_Project\sql_scripts\Bronze")
OUTPUT    = Path(r"C:\ATK_Project\compiled\manual_run\compiled_Bronze_Tables.sql")

FALLBACK_ENCODINGS = ("utf-8-sig", "utf-8", "cp1250", "cp1252", "latin-1")
DIV = "-" * 100

# ---- strictly ordered files ----
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

# ---- helper to read files with fallback encodings ----
def read_text_with_fallback(p: Path) -> str | None:
    for enc in FALLBACK_ENCODINGS:
        try:
            return p.read_text(encoding=enc)
        except Exception:
            continue
    return None

def compile_sql_strict():
    # ---- 1) Build final list strictly from SQL_ORDER ----
    sql_files = []
    for fname in SQL_ORDER:
        fpath = MAIN_DIR / fname
        if fpath.exists():
            sql_files.append(fpath)
        else:
            print(f"⚠ Warning: file listed in SQL_ORDER not found -> {fpath}")

    # ---- 2) header for compiled file ----
    header = (
        f"-- Compiled Bronze SQL bundle (strict order)\n"
        f"-- Generated: {datetime.now():%Y-%m-%d %H:%M:%S}\n"
        f"-- Source folder: {MAIN_DIR}\n"
        f"-- Files ({len(sql_files)}):\n--   " + "\n--   ".join([f.name for f in sql_files]) + "\n"
        f"{DIV}\n\nSET NOCOUNT ON;\n\n"
    )

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT.open("w", encoding="utf-8", newline="\n") as out:
        out.write(header)

        for f in sql_files:
            content = read_text_with_fallback(f)
            out.write(f"{DIV}\n-- Start of: {f.name}\n{DIV}\n")
            out.write((content.rstrip() if content else "-- Could not decode file") + "\n")
            out.write(f"{DIV}\n-- End of:   {f.name}\n{DIV}\n\n")
            out.write("GO\n\n")

    print(f"✅ Compiled Bronze SQL file created at: {OUTPUT}")

if __name__ == "__main__":
    compile_sql_strict()