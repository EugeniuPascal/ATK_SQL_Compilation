import os
import re
import logging
from datetime import datetime
import smtplib
from email.message import EmailMessage

# ---- Settings ----
DB_NAME        = "ATK"
DEFAULT_SCHEMA = "mis"
source_folder  = r"C:\ATK_Project\sql_scripts\Silver"
output_file    = r"C:\ATK_Project\compiled\compiled_silver_job_proc.sql"
log_file       = r"C:\ATK_Project\logs\compile_silver.log"

EMAIL_TO       = "eugeniu.pascal@microinvest.md"
EMAIL_FROM     = "your.email@domain.com"  # change to a valid sender
SMTP_SERVER    = "smtp.domain.com"        # change to your SMTP server
SMTP_PORT      = 587                       # change if needed
SMTP_USER      = "your.email@domain.com"
SMTP_PASS      = "your_password"

# ---- Logging ----
os.makedirs(os.path.dirname(log_file), exist_ok=True)
logging.basicConfig(
    filename=log_file,
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)
logging.info("=== Starting Silver SQL Compilation Job ===")

# --- Regexes (Unicode-friendly) ---
GO_LINE_RE   = re.compile(r"^\s*GO\s*$", re.IGNORECASE | re.MULTILINE)
USE_RE       = re.compile(r"^\s*USE\s+\[?[^\]\r\n]+]?\s*;\s*$", re.IGNORECASE | re.MULTILINE)
OBJ_NAME     = r'([\w\.\[\]" ]+)'
CREATE_VIEW_RE  = re.compile(r"\bCREATE\s+VIEW\s+" + OBJ_NAME, re.IGNORECASE)
CREATE_PROC_RE  = re.compile(r"\bCREATE\s+PROCEDURE\s+" + OBJ_NAME, re.IGNORECASE)
CREATE_FUNC_RE  = re.compile(r"\bCREATE\s+FUNCTION\s+" + OBJ_NAME, re.IGNORECASE)
CREATE_TABLE_RE = re.compile(r"\bCREATE\s+TABLE\s+" + OBJ_NAME, re.IGNORECASE)

def normalize_object_name(name: str, default_schema: str) -> str:
    n = name.strip()
    if '"' in n:
        return n
    if '.' not in n:
        part = n if (n.startswith('[') and n.endswith(']')) else f'[{n}]'
        return f'[{default_schema}].{part}'
    parts = [p.strip() for p in n.split('.')]
    norm = []
    for p in parts:
        if p.startswith('[') and p.endswith(']'):
            norm.append(p)
        else:
            norm.append(f'[{p}]')
    return '.'.join(norm)

def make_idempotent(sql: str) -> str:
    sql = GO_LINE_RE.sub("", sql)
    sql = USE_RE.sub("", sql)
    sql = CREATE_VIEW_RE.sub(lambda m: f"CREATE OR ALTER VIEW {m.group(1)}", sql)
    sql = CREATE_PROC_RE.sub(lambda m: f"CREATE OR ALTER PROCEDURE {m.group(1)}", sql)
    sql = CREATE_FUNC_RE.sub(lambda m: f"CREATE OR ALTER FUNCTION {m.group(1)}", sql)

    def table_repl(m):
        raw = m.group(1).strip()
        if raw.lstrip().startswith('#'):
            return f"CREATE TABLE {raw}"
        norm = normalize_object_name(raw, DEFAULT_SCHEMA)
        return (f"IF OBJECT_ID(N'{norm}','U') IS NOT NULL DROP TABLE {raw};\n"
                f"CREATE TABLE {raw}")
    sql = CREATE_TABLE_RE.sub(table_repl, sql)
    return sql.strip()

def send_email(subject: str, body: str):
    msg = EmailMessage()
    msg['Subject'] = subject
    msg['From'] = EMAIL_FROM
    msg['To'] = EMAIL_TO
    msg.set_content(body)

    with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
        server.starttls()
        server.login(SMTP_USER, SMTP_PASS)
        server.send_message(msg)
        logging.info(f"Email sent: {subject}")

# ---- Main compilation ----
try:
    sql_files = sorted([f for f in os.listdir(source_folder) if f.lower().endswith('.sql')])
    logging.info(f"Found {len(sql_files)} SQL files in {source_folder}")

    with open(output_file, 'w', encoding='utf-8-sig') as f_out:
        f_out.write("-- =============================================\n")
        f_out.write("-- Compiled Stored Procedure for MSSQL Agent Job (Silver) - Idempotent\n")
        f_out.write(f"-- Generated: {datetime.now()}\n")
        f_out.write(f"-- Source folder: {source_folder}\n")
        f_out.write(f"-- Files included: {len(sql_files)}\n")
        for sf in sql_files:
            f_out.write(f"--   {sf}\n")
        f_out.write("-- Requires: SQL Server 2016 SP1+ for CREATE OR ALTER\n")
        f_out.write("-- =============================================\n\n")

        f_out.write(f"USE [{DB_NAME}];\nGO\n\n")
        f_out.write(f"IF OBJECT_ID('{DEFAULT_SCHEMA}.usp_CompileSilverTables', 'P') IS NOT NULL\n")
        f_out.write(f"    DROP PROCEDURE {DEFAULT_SCHEMA}.usp_CompileSilverTables;\nGO\n\n")
        f_out.write(f"CREATE PROCEDURE {DEFAULT_SCHEMA}.usp_CompileSilverTables\nAS\nBEGIN\n")
        f_out.write("    SET NOCOUNT ON;\n")
        f_out.write("    DECLARE @sql NVARCHAR(MAX);\n\n")

        for sf in sql_files:
            try:
                logging.info(f"Processing file: {sf}")
                with open(os.path.join(source_folder, sf), 'r', encoding='utf-8-sig') as f_in:
                    content = f_in.read()
                    transformed = make_idempotent(content)
                    safe = transformed.replace("'", "''")
                    f_out.write(f"    -- Start of: {sf}\n")
                    f_out.write("    SET @sql = N'" + safe + "';\n")
                    f_out.write("    BEGIN TRY\n")
                    f_out.write("        EXEC sys.sp_executesql @sql;\n")
                    f_out.write("    END TRY\n")
                    f_out.write("    BEGIN CATCH\n")
                    f_out.write("        THROW;\n")
                    f_out.write("    END CATCH;\n\n")
                logging.info(f"Finished file: {sf}")
            except Exception as e:
                logging.error(f"Error processing {sf}: {e}")
                raise

        f_out.write("END\nGO\n")

    logging.info(f"✅ Stored procedure script generated successfully: {output_file}")
    send_email("✅ Silver Compilation Success", f"The Silver compilation job completed successfully.\nOutput file: {output_file}")

except Exception as e:
    logging.exception("💥 Fatal error during compilation")
    try:
        send_email("💥 Silver Compilation Failed", f"The Silver compilation job failed.\nError: {e}")
    except Exception as email_err:
        logging.exception(f"Failed to send failure email: {email_err}")
    raise
