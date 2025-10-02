# send_procedure_status_summary_email.py
import pyodbc
import smtplib
from email.mime.text import MIMEText
from datetime import datetime

# ---- Settings ----
DB_CONN = "Driver={SQL Server};Server=MI-DEV-SQL01;Database=ATK;Trusted_Connection=yes;"
SMTP_SERVER = "smtp.microinvest.md"
SMTP_FROM = "sqlserver@microinvest.md"
SMTP_TO = "eugeniu.pascal@microinvest.md"

# ---- Connect to SQL Server ----
conn = pyodbc.connect(DB_CONN)
cursor = conn.cursor()

# Get all procedure runs from today
cursor.execute("""
    SELECT ProcedureName, RunTime, Status, ErrorMessage
    FROM mis.ProcedureStatusLog
    WHERE CAST(RunTime AS DATE) = CAST(GETDATE() AS DATE)
    ORDER BY RunTime
""")
rows = cursor.fetchall()
cursor.close()
conn.close()

# Build email
if not rows:
    subject = "Procedure Status: No runs today"
    body = "No procedure runs have been logged today."
else:
    subject = f"Procedure Status Summary - {datetime.now().strftime('%Y-%m-%d')}"
    body_lines = []
    for row in rows:
        line = f"{row.RunTime}: {row.ProcedureName} → {row.Status}"
        if row.ErrorMessage:
            line += f" | Error: {row.ErrorMessage}"
        body_lines.append(line)
    body = "\n".join(body_lines)

msg = MIMEText(body)
msg['Subject'] = subject
msg['From'] = SMTP_FROM
msg['To'] = SMTP_TO

# ---- Send email ----
with smtplib.SMTP(SMTP_SERVER) as server:
    server.sendmail(SMTP_FROM, [SMTP_TO], msg.as_string())

print(f"Email sent: {subject}")
