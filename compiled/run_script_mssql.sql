USE msdb;
GO

-- Create the job
EXEC sp_add_job
  @job_name = N'Run Silver then Gold',
  @enabled = 1,
  @description = N'Runs all SQL files in Silver, then all SQL files in Gold, daily.';

--------------------------------------------------------------------------------
-- Step 1: Silver (PowerShell step)
--------------------------------------------------------------------------------
EXEC sp_add_jobstep
  @job_name = N'Run Silver then Gold',
  @step_name = N'Run Silver folder',
  @subsystem = N'PowerShell',
  @on_success_action = 3,   -- go to next step
  @on_fail_action    = 2,   -- fail job
  @command = N'
$ErrorActionPreference = "Stop"

# Settings
$server = "YOUR_SERVER\YOUR_INSTANCE"
$db     = "YourDatabase"
$dir    = "C:\ATK_Project\sql_scripts\Silver"

# Optional: create a log file per run (uncomment to use)
# $logDir = "C:\ATK_Project\logs"; New-Item -ItemType Directory -Path $logDir -ErrorAction SilentlyContinue | Out-Null
# $ts = Get-Date -Format "yyyyMMdd_HHmmss"
# $logPath = Join-Path $logDir "silver_$ts.out"

# Run every .sql file, sorted by name
$files = Get-ChildItem -Path $dir -Filter *.sql -File | Sort-Object Name
if (-not $files) { Write-Host "No .sql files found in $dir"; exit 0 }

foreach ($f in $files) {
    Write-Host "Running: $($f.Name)"
    # Windows auth (-E). For SQL auth, replace with: -U user -P password
    & sqlcmd -S $server -d $db -b -E -i $f.FullName
    if ($LASTEXITCODE -ne 0) { throw "sqlcmd failed for $($f.Name) with exit code $LASTEXITCODE" }
    # If using logs: add -o $logPath to the line above
}
';

--------------------------------------------------------------------------------
-- Step 2: Gold (PowerShell step)
--------------------------------------------------------------------------------
EXEC sp_add_jobstep
  @job_name = N'Run Silver then Gold',
  @step_name = N'Run Gold folder',
  @subsystem = N'PowerShell',
  @on_success_action = 1,   -- quit with success
  @on_fail_action    = 2,   -- fail job
  @command = N'
$ErrorActionPreference = "Stop"

# Settings
$server = "YOUR_SERVER\YOUR_INSTANCE"
$db     = "YourDatabase"
$dir    = "C:\ATK_Project\sql_scripts\Gold"

# Optional logging (same idea as in Silver)
# $logDir = "C:\ATK_Project\logs"; New-Item -ItemType Directory -Path $logDir -ErrorAction SilentlyContinue | Out-Null
# $ts = Get-Date -Format "yyyyMMdd_HHmmss"
# $logPath = Join-Path $logDir "gold_$ts.out"

$files = Get-ChildItem -Path $dir -Filter *.sql -File | Sort-Object Name
if (-not $files) { Write-Host "No .sql files found in $dir"; exit 0 }

foreach ($f in $files) {
    Write-Host "Running: $($f.Name)"
    & sqlcmd -S $server -d $db -b -E -i $f.FullName
    if ($LASTEXITCODE -ne 0) { throw "sqlcmd failed for $($f.Name) with exit code $LASTEXITCODE" }
    # If using logs: add -o $logPath to the line above
}
';

--------------------------------------------------------------------------------
-- Schedule daily at 06:00 (server local time)
--------------------------------------------------------------------------------
EXEC sp_add_schedule
  @schedule_name = N'Daily 06:00',
  @freq_type = 4,           -- daily
  @freq_interval = 1,       -- every day
  @active_start_time = 20000; -- 02:00:00

EXEC sp_attach_schedule
  @job_name = N'Run Silver then Gold',
  @schedule_name = N'Daily 06:00';

-- Target server (change if not local)
EXEC sp_add_jobserver
  @job_name = N'Run Silver then Gold',
  @server_name = N'(local)';

GO
