import pyodbc
import time
from datetime import datetime, date, timedelta
import win32com.client as win32

# ----------------- CONFIG -----------------
DB_SERVER = 'MI-DEV-SQL01'
DB_NAME = 'ATK'
PROCEDURE_NAME = 'usp_CompileGoldTables'
CHECK_INTERVAL_MINUTES = 10
REMINDER_INTERVAL_HOURS = 3  # Send "still waiting" email every 3 hours
EMAIL_TO = 'eugeniu.pascal@microinvest.md'
# ------------------------------------------

def send_email(subject, body):
    outlook = win32.Dispatch('Outlook.Application')
    mail = outlook.CreateItem(0)  # 0 = olMailItem
    mail.To = EMAIL_TO
    mail.Subject = subject
    mail.Body = body
    mail.Send()

def check_procedure_status():
    conn_str = (
        f"DRIVER={{ODBC Driver 18 for SQL Server}};"
        f"SERVER={DB_SERVER};DATABASE={DB_NAME};"
        f"Trusted_Connection=yes;"
    )
    with pyodbc.connect(conn_str) as conn:
        cursor = conn.cursor()
        cursor.execute(f"""
            SELECT TOP 1 Status, ErrorMessage, EndTime
            FROM mis.ProcedureExecutionLog
            WHERE ProcedureName=? 
              AND CAST(EndTime AS DATE) = ?
            ORDER BY EndTime DESC
        """, PROCEDURE_NAME, date.today())
        return cursor.fetchone()

def wait_for_procedure():
    print(f"Monitoring {PROCEDURE_NAME} every {CHECK_INTERVAL_MINUTES} minutes for today's run...")
    last_reminder_time = datetime.min

    while True:
        row = check_procedure_status()
        now = datetime.now()

        if row:
            status, error, endtime = row
            endtime_str = endtime.strftime("%Y-%m-%d %H:%M:%S") if endtime else "Unknown"

            if status == 'Success':
                send_email(f"Procedure {PROCEDURE_NAME} Finished Successfully",
                           f"Procedure ran successfully at {endtime_str}.")
            else:
                send_email(f"Procedure {PROCEDURE_NAME} Failed",
                           f"Procedure failed at {endtime_str}.\nError: {error}")
            print(f"Notification sent. Exiting.")
            break

        # Send reminder if procedure hasn't run yet
        if now - last_reminder_time >= timedelta(hours=REMINDER_INTERVAL_HOURS):
            send_email(f"Procedure {PROCEDURE_NAME} has not run yet",
                       f"No execution found for today as of {now.strftime('%Y-%m-%d %H:%M:%S')}.")
            last_reminder_time = now
            print(f"Reminder sent at {now.strftime('%Y-%m-%d %H:%M:%S')}")

        print(f"No execution found for today. Waiting {CHECK_INTERVAL_MINUTES} minutes...")
        time.sleep(CHECK_INTERVAL_MINUTES * 60)

if __name__ == "__main__":
    wait_for_procedure()
