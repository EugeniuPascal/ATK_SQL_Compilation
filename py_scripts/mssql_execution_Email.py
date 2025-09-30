import pyodbc
from datetime import datetime

# ----------------- CONFIG -----------------
DB_SERVER = 'MI-DEV-SQL01'
DB_NAME = 'msdb'  # we query MSDB for job history
PROCEDURE_NAME = 'usp_CompileGoldTables'
# ------------------------------------------

def get_last_execution():
    conn_str = (
        r"DRIVER={ODBC Driver 17 for SQL Server};"
        f"SERVER={DB_SERVER};DATABASE={DB_NAME};Trusted_Connection=yes;"
    )
    query = f"""
    SELECT TOP 1
           j.name AS JobName,
           s.step_name AS StepName,
           h.run_status,   -- 0=Fail, 1=Success
           h.run_date,
           h.run_time,
           h.run_duration
    FROM sysjobhistory h
    JOIN sysjobs j
      ON h.job_id = j.job_id
    JOIN sysjobsteps s
      ON h.job_id = s.job_id
     AND h.step_id = s.step_id
    WHERE s.command LIKE '%{PROCEDURE_NAME}%'
    ORDER BY h.run_date DESC, h.run_time DESC;
    """
    with pyodbc.connect(conn_str, timeout=30) as conn:
        cursor = conn.cursor()
        cursor.execute(query)
        row = cursor.fetchone()
        if not row:
            return None
        run_date = datetime.strptime(str(row.run_date), "%Y%m%d").date()
        run_time = f"{row.run_time:06d}"
        run_time = f"{run_time[0:2]}:{run_time[2:4]}:{run_time[4:6]}"
        return {
            "job": row.JobName,
            "step": row.StepName,
            "status": "Success" if row.run_status == 1 else "Fail",
            "date": run_date,
            "time": run_time,
            "duration": row.run_duration
        }

if __name__ == "__main__":
    result = get_last_execution()
    if result:
        print(f"Job: {result['job']} Step: {result['step']}")
        print(f"Last run: {result['date']} {result['time']} (Duration {result['duration']})")
        print(f"Status: {result['status']}")
    else:
        print("No executions found.")
