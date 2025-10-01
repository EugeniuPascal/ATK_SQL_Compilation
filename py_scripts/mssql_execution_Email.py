# send_procedure_status_email.py
import pyodbc
import smtplib
from email.mime.text import MIMEText

# ---- Settings ----
DB_CONN = "Driver={SQL Server};Server=YOUR_SERVER;Database=ATK;Trusted_Connection=yes;"
SMTP_SERVER = "smtp.yourcompany.com"
SMTP_FROM = "sqlserver@yourcompany.com"
SMTP_TO = "your.email@example.com"

# Connect to SQL Server
conn = pyodbc.connect(DB_CONN)
cursor = conn.cursor()

# Get the latest run of the compiled procedure
cursor.execute("""
    SELECT TOP 1 ProcedureName, RunTime, Status, ErrorMessage
    FROM mis.ProcedureStatusLog
    ORDER BY RunTime DESC
""")
row = cursor.fetchone()
cursor.close()
conn.close()

# Build email
subject = f"Procedure {row.ProcedureName} finished: {row.Status}"
body = f"Procedure: {row.ProcedureName}\nTime: {row.RunTime}\nStatus: {row.Status}"
if row.ErrorMessage:
    body += f"\nError: {row.ErrorMessage}"

msg = MIMEText(body)
msg['Subject'] = subject
msg['From'] = SMTP_FROM
msg['To'] = SMTP_TO

# Send email
with smtplib.SMTP(SMTP_SERVER) as server:
    server.sendmail(SMTP_FROM, [SMTP_TO], msg.as_string())

print(f"Email sent for procedure {row.ProcedureName}: {row.Status}")
