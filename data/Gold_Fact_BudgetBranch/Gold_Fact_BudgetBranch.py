import pandas as pd
import pyodbc
import numpy as np
from decimal import Decimal, InvalidOperation
from tabulate import tabulate

# ============================================================
# CONFIG
# ============================================================
EXCEL_PATH = r"C:\ATK_Project\data\Gold_Fact_BudgetBranch\Branch Plan 2025.xlsx"
SQL_TABLE = "[mis].[Gold_Fact_BudgetBranch]"

COLUMNS = [
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

SQL_CONN_STR = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=MI-DEV-SQL01;"
    "DATABASE=ATK;"
    "Trusted_Connection=yes;"
)

# ============================================================
# HELPERS
# ============================================================
def to_decimal_safe(x):
    if x is None:
        return None
    try:
        if isinstance(x, str):
            x = x.replace(',', '').strip()
        return Decimal(x).quantize(Decimal("0.00"))
    except (InvalidOperation, ValueError, TypeError):
        return None


def to_datetime_safe(x):
    try:
        return pd.to_datetime(x)
    except (ValueError, TypeError):
        return None


def safe_val(val):
    return None if pd.isna(val) else val


# ============================================================
# EXTRACT
# ============================================================
def read_excel(path: str) -> pd.DataFrame:
    df = pd.read_excel(path)
    df.columns = df.columns.str.strip()
    df = df.replace({np.nan: None, "": None})
    return df


# ============================================================
# TRANSFORM
# ============================================================
def transform(df: pd.DataFrame) -> pd.DataFrame:
    missing = [c for c in COLUMNS if c not in df.columns]
    if missing:
        raise KeyError(f"Missing columns: {missing}")

    for col in ['Disbursed', 'Repayments', 'LP']:
        df[col] = df[col].apply(to_decimal_safe)
        df[col] = df[col].astype(object)  # keep Decimal for SQL insert

    df['Month'] = df['Month'].apply(to_datetime_safe)

    return df[COLUMNS]


# ============================================================
# LOAD
# ============================================================
def load_to_sql(df: pd.DataFrame):
    data = [
        tuple(safe_val(row[col]) for col in COLUMNS)
        for _, row in df.iterrows()
    ]

    conn = pyodbc.connect(SQL_CONN_STR)
    cursor = conn.cursor()
    cursor.fast_executemany = True

    try:
        cursor.execute("BEGIN TRAN")

        # Empty the table first
        cursor.execute(f"TRUNCATE TABLE {SQL_TABLE}")

        cursor.executemany(f"""
            INSERT INTO {SQL_TABLE}
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
        """, data)

        cursor.execute("COMMIT TRAN")

        print(f"Inserted {len(data):,} rows into {SQL_TABLE}")

    except Exception:
        cursor.execute("ROLLBACK TRAN")
        raise

    finally:
        cursor.close()
        conn.close()


# ============================================================
# MAIN
# ============================================================
def main():
    df = read_excel(EXCEL_PATH)
    df = transform(df)

    # ----------------------------
    # DISPLAY FIX: show Decimals exactly like SQL
    # ----------------------------
    df_display = df.copy()
    for col in ['Disbursed', 'Repayments', 'LP']:
        df_display[col] = df_display[col].apply(lambda x: float(x) if x is not None else None)

    print(tabulate(df_display.head(21), headers='keys', tablefmt='psql', floatfmt=".2f"))

    # ----------------------------
    # LOAD TO SQL
    # ----------------------------
    load_to_sql(df)
    print("✅ ETL completed successfully")


if __name__ == "__main__":
    main()
