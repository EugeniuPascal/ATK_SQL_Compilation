import pandas as pd
import pyodbc
import numpy as np
from tabulate import tabulate

# Read Excel
df = pd.read_excel(r"H:\mapa lucru\ATK_db\Import_Excel_in_db\mis.2tbl_Gold_Fact_BudgetBranch\Branch Plan 2025.xlsx")

# Replace NaN or empty strings with None
df = df.replace({np.nan: None, "": None})

print(tabulate(df.head(20), headers='keys', tablefmt='psql'))

# Helper function to safely convert values to strings
def safe_str(val):
    if val is None:
        return None
    return str(val)

# Prepare data for bulk insert
data_to_insert = [
    (
        safe_str(row['BranchID']),
        row['Month'],  # Keep as date if Excel stores it as datetime
        safe_str(row['Product_Segment']),
        safe_str(row['BranchRegion']),
        safe_str(row['BranchName']),
        row['Disbursed'],
        row['Payments'],
        row['LP']
    )
    for _, row in df.iterrows()
]
# Connect to SQL Server
conn = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=MI-DEV-SQL01;"
    "DATABASE=ATK;"
    "Trusted_Connection=yes;"
)
cursor = conn.cursor()

# Enable fast_executemany for bulk inserts
cursor.fast_executemany = True

# Bulk insert
cursor.executemany("""
    INSERT INTO mis.2tbl_Gold_Fact_BudgetBranch 
                (BranchID, 
                 Month, 
                 Product_Segment, 
                 BranchRegion, 
                 BranchName,
                 Disbursed,
                 Payments,
                 LP)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
""", data_to_insert)

# Commit and close
conn.commit()
conn.close()
