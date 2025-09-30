import pyodbc
import win32com.client as win32
from datetime import datetime
import time

# ----------------- CONFIG -----------------
DB_SERVER = 'MI-DEV-SQL01'
DB_NAME = 'ATK'
PROCEDURE_NAME = 'usp_CompileGoldTables'

CHECK_INTERVAL_MINUTES = 10
EMAIL_TO = 'eugeniu.pascal@microinvest.md'
# ------------------------------------------

def send_email(subject, body):
    outlook = win32.Dispatch('Outlook.Application')
    mail = outlook.CreateItem(0)
    mail.To = EMAIL_TO
    mail.Subject = subject
    mail.Body = body
    mail.Send()
    print(f"Email sent: {subject}")

def run_procedure():
    conn_str = (
        r"DRIVER={ODBC Driver 17 for SQL Server};"
        f"SERVER={DB_SERVER};DATABASE={DB_NAME};Trusted_Connection=yes;"
    )
    try:
        with pyodbc.connect(conn_str, timeout=30) as conn:
            cursor = conn.cursor()
            print(f"Executing procedure {PROCEDURE_NAME}...")
            cursor.execute(f"EXEC {PROCEDURE_NAME}")
            cursor.commit()
        send_email(f"Procedure {PROCEDURE_NAME} Finished Successfully",
                   f"The procedure ran successfully at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}.")
        print("Procedure executed successfully.")
        return True
    except Exception as e:
        send_email(f"Procedure {PROCEDURE_NAME} Failed",
                   f"The procedure failed at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}.\nError: {e}")
        print(f"Procedure failed: {e}")
        return False

def wait_for_procedure():
    while True:
        success = run_procedure()
        if success:
            break
        print(f"Retrying in {CHECK_INTERVAL_MINUTES} minutes...")
        time.sleep(CHECK_INTERVAL_MINUTES * 60)

if __name__ == "__main__":
    wait_for_procedure()
