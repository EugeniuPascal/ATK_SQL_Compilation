import pyodbc
import pandas as pd
from datetime import datetime, timedelta
import os

# -------------------------
# 1) Database connection
# -------------------------
conn = pyodbc.connect(
    "Driver={SQL Server};"
    "Server=MI-DEV-SQL01;"  
    "Database=ATK;"                 
    "Trusted_Connection=yes;"
    # "UID=your_user;PWD=your_password;"  # if using SQL authentication
)

# -------------------------
# 2) Define date range for previous month
# -------------------------
today = datetime.today()
first_day_of_current_month = today.replace(day=1)
last_day_of_prev_month = first_day_of_current_month - timedelta(days=1)
first_day_of_prev_month = last_day_of_prev_month.replace(day=1)

# Convert to string for SQL
start_date = first_day_of_prev_month.strftime('%Y-%m-%d')
end_date = first_day_of_current_month.strftime('%Y-%m-%d')

# -------------------------
# 3) SQL query
# -------------------------
query = f"""
SELECT *
FROM [dbo].[РегистрыСведений.ОтправленныеСМС]
WHERE [ОтправленныеСМС Период] >= '{start_date}'
  AND [ОтправленныеСМС Период] < '{end_date}'
  ORDER BY [ОтправленныеСМС Период] ASC
"""

# -------------------------
# 4) Read data into pandas
# -------------------------
df = pd.read_sql(query, conn)

# -------------------------
# 5) Prepare output folder & file
# -------------------------
export_folder = r"\\MI-FSR01\General\CBO\Business Department\Retail Loan Advisor\Private\Sectie Digital\Digital - Cornelia Verdes\Statistica Push notification&SMS\SMS_Reports"
os.makedirs(export_folder, exist_ok=True)

output_file = os.path.join(
    export_folder,
    f"SMS_{first_day_of_prev_month.strftime('%Y_%m')}.xlsx"
)

# -------------------------
# 6) Export to Excel
# -------------------------
df.to_excel(output_file, index=False, engine='openpyxl')

print(f"Export completed: {output_file}")