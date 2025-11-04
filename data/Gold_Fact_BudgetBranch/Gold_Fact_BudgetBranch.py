import pandas as pd
import pyodbc
import numpy as np
from decimal import Decimal, InvalidOperation
from tabulate import tabulate

# --- Read Excel ---
df = pd.read_excel(r"C:\ATK_Project\data\Gold_Fact_BudgetBranch\Branch Plan 2025.xlsx")

# Strip extra spaces from column names
df.columns = df.columns.str.strip()

# Replace NaN or empty strings with None
df = df.replace({np.nan: None, "": None})

# --- Robust conversion functions ---
def to_decimal_safe(x):
    """Convert value to Decimal, return None if invalid"""
    if x is None:
        return None
    try:
        if isinstance(x, str):
            x = x.replace(',', '').strip()  # remove commas/spaces
        return Decimal(x)
    except (InvalidOperation, ValueError, TypeError):
        return None

def to_datetime_safe(x):
    """Convert value to datetime, return None if invalid"""
    try:
        return pd.to_datetime(x)
    except (ValueError, TypeError):
        return None

# --- Convert numeric columns ---
for col in ['Disbursed', 'Repayments', 'LP']:
    df[col] = df[col].apply(to_decimal_safe)
    df[col] = df[col].apply(lambda x: round(x, 2) if x is not None else None)  # round to 2 decimals

# Convert Month column
df['Month'] = df['Month'].apply(to_datetime_safe)

# --- Print first 10 rows for verification ---
print(tabulate(df.head(10), headers='keys', tablefmt='psql'))

# --- Columns mapping ---
columns_needed = [
    'BranchID',
    'Month',
    'Product_Segment',
    'Product_Adjusted', 
    'BranchRegion',
    'BranchName',
    'Disbursed',
    'Repayments', 
    'LP'
]

# Check for missing columns
missing_cols = [col for col in columns_needed if col not in df.columns]
if missing_cols:
    raise KeyError(f"Missing columns in Excel sheet: {missing_cols}. Available columns: {list(df.columns)}")

# --- Prepare data for insert ---
def safe_val(val):
    return None if pd.isna(val) else val

data_to_insert = [
    tuple(safe_val(row[col]) for col in columns_needed)
    for _, row in df.iterrows()
]

# --- Connect to SQL Server ---
conn = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=MI-DEV-SQL01;"
    "DATABASE=ATK;"
    "Trusted_Connection=yes;"
)
cursor = conn.cursor()
cursor.fast_executemany = True  # Speeds up bulk insert

# --- Bulk insert ---
cursor.executemany("""
    INSERT INTO [mis].[Gold_Fact_BudgetBranch]
       (BranchID,
        Month,
        Product_Segment,
        Product_Adjusted,
        BranchRegion,
        BranchName,
        Disbursed,
        Repayments, 
        LP)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
""", data_to_insert)

# --- Commit and close ---
conn.commit()
cursor.close()
conn.close()

print("Data inserted successfully!")
