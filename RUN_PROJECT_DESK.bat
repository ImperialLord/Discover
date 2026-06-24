@echo off
setlocal EnableExtensions
set "ROOT=D:\Henceforth DOS"
set "SCRIPTS=%ROOT%\23_CODE_REPOS\Scripts"
set "PY=python"
where python >nul 2>&1 || set "PY=C:\Users\bobby\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"

for /f "tokens=5" %%P in ('netstat -ano ^| findstr :8765 ^| findstr LISTENING') do (
  for /f "delims=" %%C in ('powershell -NoProfile -Command "(Get-CimInstance Win32_Process -Filter 'ProcessId=%%P').CommandLine"') do echo %%C | findstr /I /C:"evolve_server.py" >nul && taskkill /PID %%P /F >nul
)

cd /d "%SCRIPTS%"
echo Running Discover Doctor preflight...
"%PY%" discover_doctor.py --mode=Preflight
if errorlevel 1 echo Doctor found actionable issues. Review http://127.0.0.1:8765/doctor.html

echo Starting Discover API on port 8765...
start "Discover Server" /D "%SCRIPTS%" "%PY%" evolve_server.py

set /a _tries=0
:wait_api
timeout /t 1 /nobreak >nul
set /a _tries+=1
powershell -NoProfile -Command "try{(Invoke-WebRequest -Uri 'http://127.0.0.1:8765/api/health' -UseBasicParsing -TimeoutSec 2).StatusCode -eq 200}catch{$false}" | findstr /I "True" >nul && goto api_up
if %_tries% LSS 15 goto wait_api
echo WARNING: API did not respond on port 8765. Check the Discover Server window.
goto open_ui

:api_up
echo Discover API is online.

:open_ui
start "" "http://127.0.0.1:8765/"
start "" "http://127.0.0.1:8765/workspace.html"
echo.
echo Discover Project Desk: http://127.0.0.1:8765/
echo Discover Workspace (Lens + Doctor): http://127.0.0.1:8765/workspace.html
echo Discover Doctor: http://127.0.0.1:8765/doctor.html
echo.
echo Keep the "Discover Server" window open while using Discover.
pause
endlocal
