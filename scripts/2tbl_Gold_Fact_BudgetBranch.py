import pandas as pd
import pyodbc
import numpy as np
from tabulate import tabulate

# Read Excel
df = pd.read_excel(r"C:\ATK_Project\data\Branch Plan 2025.xlsx")

# Strip column names of extra spaces
df.columns = df.columns.str.strip()

# Replace NaN or empty strings with None
df = df.replace({np.nan: None, "": None})

# Print first 20 rows for verification
print(tabulate(df.head(20), headers='keys', tablefmt='psql'))

# Helper function to safely convert values
def safe_val(val):
    return None if val is None else val

# List the exact columns you need to map to SQL table
columns_needed = [
    'BranchID',
    'Month',
    'Product_Segment',
    'BranchRegion',
    'BranchName',
    'Disbursed',
    'Payments',    
    'LP'             
]

# Ensure all required columns exist in Excel
for col in columns_needed:
    if col not in df.columns:
        raise KeyError(f"Column '{col}' not found in Excel sheet. Available columns: {list(df.columns)}")

# Prepare data for bulk insert
data_to_insert = [
    tuple(safe_val(row[col]) for col in columns_needed)
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
cursor.fast_executemany = True

# Bulk insert
cursor.executemany("""
    INSERT INTO mis.2tbl_Gold_Fact_BudgetBranch 
        (BranchID, Month, Product_Segment, BranchRegion, BranchName, Disbursed, Payments, LP)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
""", data_to_insert)

# Commit and close
conn.commit()
conn.close()
