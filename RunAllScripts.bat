@echo off
setlocal enabledelayedexpansion

REM ----------------------------
REM --- Base folder (where .bat lives) ---
REM ----------------------------
set "BASE_DIR=C:\ATK_Project\"
set "COMPILED_DIR=%BASE_DIR%compiled\"
set "PY_SCRIPTS_DIR=%BASE_DIR%py_scripts\"

REM ----------------------------
REM --- Folders for logs ------
REM ----------------------------
set "LOGS_SILVER=%COMPILED_DIR%Logs\Silver"
set "LOGS_GOLD=%COMPILED_DIR%Logs\Gold"

REM Create Logs folders if they don't exist
if not exist "%LOGS_SILVER%" mkdir "%LOGS_SILVER%" 2>nul
if not exist "%LOGS_GOLD%" mkdir "%LOGS_GOLD%" 2>nul

REM ----------------------------
REM --- Helper for timestamp (locale-independent) ---
REM ----------------------------
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set TIMESTAMP=%%i

REM ----------------------------
REM --- Paths for executables ---
REM ----------------------------
set "PYTHON=C:\Users\eugeniu.pascal\AppData\Local\Programs\Python\Python313\python.exe"
set "SQLCMD=C:\Program Files\SqlCmd\sqlcmd.exe"
set "SERVER=MI-DEV-SQL01"
set "DB=ATK"

REM ----------------------------
REM --- Step 1: SILVER Python ---
REM ----------------------------
echo [%time%] Starting SILVER Python compilation...
"%PYTHON%" "%PY_SCRIPTS_DIR%compile_Silver_Files.py"
if %errorlevel% neq 0 (
    echo [%time%] SILVER Python FAILED with code %errorlevel%.
    exit /b %errorlevel%
) else (
    echo [%time%] SILVER Python SUCCESS.
)

REM ----------------------------
REM --- Step 2: SILVER SQL -----
REM ----------------------------
set "SCRIPT=%COMPILED_DIR%compiled_Silver_Tables.sql"
set "LOG=%LOGS_SILVER%\compiled_Silver_Tables_%TIMESTAMP%.log"

echo [%time%] Starting SILVER SQL execution...
"%SQLCMD%" -S "%SERVER%" -d "%DB%" -E -i "%SCRIPT%" -b -r 1 -I -e -o "%LOG%"
if %errorlevel% neq 0 (
    echo [%time%] SILVER SQL FAILED. See log: "%LOG%"
    exit /b %errorlevel%
) else (
    echo [%time%] SILVER SQL SUCCESS. Log: "%LOG%"
)

REM ----------------------------
REM --- Step 3: GOLD Python ----
REM ----------------------------
echo [%time%] Starting GOLD Python compilation...
"%PYTHON%" "%PY_SCRIPTS_DIR%compile_Gold_Files.py"
if %errorlevel% neq 0 (
    echo [%time%] GOLD Python FAILED with code %errorlevel%.
    exit /b %errorlevel%
) else (
    echo [%time%] GOLD Python SUCCESS.
)

REM ----------------------------
REM --- Step 4: GOLD SQL -------
REM ----------------------------
set "SCRIPT=%COMPILED_DIR%compiled_Gold_Tables.sql"
set "LOG=%LOGS_GOLD%\compiled_Gold_Tables_%TIMESTAMP%.log"

echo [%time%] Starting GOLD SQL execution...
"%SQLCMD%" -S "%SERVER%" -d "%DB%" -E -i "%SCRIPT%" -b -r 1 -I -e -o "%LOG%"
if %errorlevel% neq 0 (
    echo [%time%] GOLD SQL FAILED. See log: "%LOG%"
    exit /b %errorlevel%
) else (
    echo [%time%] GOLD SQL SUCCESS. Log: "%LOG%"
)

echo [%time%] ALL STEPS COMPLETED SUCCESSFULLY.
pause
exit /b 0
