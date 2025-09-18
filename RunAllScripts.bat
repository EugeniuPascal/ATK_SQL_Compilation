@echo off
setlocal enabledelayedexpansion

REM ----------------------------
REM --- Base folder ---
REM ----------------------------
set "BASE_DIR=C:\ATK_Project\"
set "COMPILED_DIR=%BASE_DIR%compiled\"
set "PY_SCRIPTS_DIR=%BASE_DIR%py_scripts\"

REM ----------------------------
REM --- Folders for logs ------
REM ----------------------------
set "LOGS_SILVER=%COMPILED_DIR%Logs\Silver"
set "LOGS_GOLD=%COMPILED_DIR%Logs\Gold"

if not exist "%LOGS_SILVER%" mkdir "%LOGS_SILVER%" 2>nul
if not exist "%LOGS_GOLD%" mkdir "%LOGS_GOLD%" 2>nul

REM ----------------------------
REM --- Timestamp helper ---
REM ----------------------------
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set TIMESTAMP=%%i

REM ----------------------------
REM --- Executables & DB ---
REM ----------------------------
set "PYTHON=C:\Users\eugeniu.pascal\AppData\Local\Programs\Python\Python313\python.exe"
set "SQLCMD=C:\Program Files\SqlCmd\sqlcmd.exe"
set "SERVER=MI-DEV-SQL01"
set "DB=ATK"

REM ----------------------------
REM --- SILVER Python ---
REM ----------------------------
echo [%time%] Starting SILVER Python compilation...
"%PYTHON%" "%PY_SCRIPTS_DIR%compile_Silver_Files.py"
if %errorlevel% neq 0 (
    echo [%time%] SILVER Python FAILED with code %errorlevel%.
    pause
    exit /b %errorlevel%
)
echo [%time%] SILVER Python SUCCESS.

REM ----------------------------
REM --- SILVER SQL -----
REM ----------------------------
set "SCRIPT=%COMPILED_DIR%compiled_Silver_Tables.sql"
set "LOG=%LOGS_SILVER%\compiled_Silver_Tables_%TIMESTAMP%.log"

echo [%time%] Running SILVER SQL...
"%SQLCMD%" -S "%SERVER%" -d "%DB%" -E -i "%SCRIPT%" -b -r 1 -I -e -o "%LOG%"
if %errorlevel% neq 0 (
    echo [%time%] SILVER SQL FAILED. See log: "%LOG%"
    pause
    exit /b %errorlevel%
)
echo [%time%] SILVER SQL SUCCESS. Log: "%LOG%"

REM ----------------------------
REM --- GOLD Python ----
REM ----------------------------
echo [%time%] Starting GOLD Python compilation...
"%PYTHON%" "%PY_SCRIPTS_DIR%compile_Gold_Files.py"
if %errorlevel% neq 0 (
    echo [%time%] GOLD Python FAILED with code %errorlevel%.
    pause
    exit /b %errorlevel%
)
echo [%time%] GOLD Python SUCCESS.

REM ----------------------------
REM --- GOLD SQL -------
REM ----------------------------
set "SCRIPT=%COMPILED_DIR%compiled_Gold_Tables.sql"
set "LOG=%LOGS_GOLD%\compiled_Gold_Tables_%TIMESTAMP%.log"

echo [%time%] Running GOLD SQL...
"%SQLCMD%" -S "%SERVER%" -d "%DB%" -E -i "%SCRIPT%" -b -r 1 -I -e -o "%LOG%"
if %errorlevel% neq 0 (
    echo [%time%] GOLD SQL FAILED. See log: "%LOG%"
    pause
    exit /b %errorlevel%
)
echo [%time%] GOLD SQL SUCCESS. Log: "%LOG%"

REM ----------------------------
REM --- Finished ---
REM ----------------------------
echo [%time%] ALL STEPS COMPLETED SUCCESSFULLY.
pause
exit /b 0
