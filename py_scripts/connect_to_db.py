import pyodbc

conn = pyodbc.connect(
    "Driver={ODBC Driver 17 for SQL Server};"
    "Server=MI-DEV-SQL01;"
    "Database=ATK;"
    "Trusted_Connection=yes;"
)

cursor = conn.cursor()
cursor.execute("SELECT TOP 10 * FROM [mis].[Bronze_Документы.ЗаявкаНаКредит]")  # example query
for row in cursor.fetchall():
    print(row)
