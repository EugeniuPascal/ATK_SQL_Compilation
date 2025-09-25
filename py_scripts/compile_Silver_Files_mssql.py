import os, sys
from datetime import datetime

source_folder = r"C:\ATK_Project\sql_scripts\Silver"
output_dir    = r"C:\ATK_Project\compiled"
output_file   = os.path.join(output_dir, "compiled_silver_mssql.sql")

try:
    os.makedirs(output_dir, exist_ok=True)

    sql_files = sorted([f for f in os.listdir(source_folder)
                        if f.lower().endswith('.sql') and not f.lower().endswith('_data.sql')])

    with open(output_file, 'w', encoding='utf-8') as f_out:
        f_out.write("-- =============================================\n")
        f_out.write("-- Compiled SQL Script for MSSQL Agent Job (Silver)\n")
        f_out.write(f"-- Generated: {datetime.now()}\n")
        f_out.write(f"-- Source folder: {source_folder}\n")
        f_out.write(f"-- Tables included: {len(sql_files)}\n")
        for sf in sql_files:
            f_out.write(f"--   {sf}\n")
        f_out.write("-- =============================================\n\n")
        f_out.write("SET NOCOUNT ON;\nGO\n\n")

        for sf in sql_files:
            table_name = sf.replace('.sql', '')
            f_out.write(f"-- =============================================\n")
            f_out.write(f"-- Start of: {sf}\n")
            f_out.write(f"-- =============================================\n\n")
            f_out.write(f"IF OBJECT_ID(N'mis.[{table_name}]', 'U') IS NOT NULL\n")
            f_out.write(f"    DROP TABLE mis.[{table_name}];\nGO\n\n")

            with open(os.path.join(source_folder, sf), 'r', encoding='utf-8') as f_in:
                content = f_in.read()
                content = content.replace("\nGO\n", "\n").replace("GO\n", "\n").replace("\nGO", "\n")
                f_out.write(content.strip() + "\n\n")

            data_file = os.path.join(source_folder, f"{table_name}_data.sql")
            if os.path.exists(data_file):
                f_out.write(f"-- Inserting data for {table_name}\n")
                with open(data_file, 'r', encoding='utf-8') as f_data:
                    data_content = f_data.read()
                    data_content = data_content.replace("\nGO\n", "\n").replace("GO\n", "\n").replace("\nGO", "\n")
                    f_out.write(data_content.strip() + "\n\n")

            f_out.write(f"-- End of: {sf}\n-- =============================================\n\n")

        f_out.write("-- End of compiled script\nGO\n")

    print(f"MSSQL Agent-ready script with data generated: {output_file}")
    sys.exit(0)
except Exception as e:
    print(f"[ERROR] {e}")
    sys.exit(1)
