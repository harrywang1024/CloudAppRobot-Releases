@echo off
setlocal
set "BASE_DIR=%~dp0"
set "TARGET_EXE="
set "DIST_EXE=%BASE_DIR%dist\CloudAppRobot\CloudAppRobot.exe"
set "FORCE_SOURCE_PANEL=%CLOUDAPP_FORCE_SOURCE_PANEL%"
set "TRIGGER_SOURCE=%CLOUDAPP_TRIGGER_SOURCE%"
if "%TRIGGER_SOURCE%"=="" set "TRIGGER_SOURCE=manual_or_unknown"
set "TRIGGER_REASON=%CLOUDAPP_TRIGGER_REASON%"
if "%TRIGGER_REASON%"=="" set "TRIGGER_REASON=-"

set INSTANCE_ID=%~1
if "%INSTANCE_ID%"=="" set INSTANCE_ID=pc

if /I not "%FORCE_SOURCE_PANEL%"=="1" if exist "%BASE_DIR%CloudAppRobot.exe" (
  set "TARGET_EXE=%BASE_DIR%CloudAppRobot.exe"
)
if /I not "%FORCE_SOURCE_PANEL%"=="1" if not defined TARGET_EXE if exist "%DIST_EXE%" (
  set "TARGET_EXE=%DIST_EXE%"
)

if defined CLOUDAPP_ROBOT_DATA_DIR (
  set "DATA_ROOT=%CLOUDAPP_ROBOT_DATA_DIR%"
) else if defined TARGET_EXE (
  set "DATA_ROOT=%BASE_DIR%.robot_data"
) else (
  for %%I in ("%BASE_DIR%..") do set "REPO_DIR=%%~fI"
  cd /d "%REPO_DIR%"
  set "DATA_ROOT=%BASE_DIR%"
)

set "RUNTIME_DIR=%DATA_ROOT%\runtime\%INSTANCE_ID%"
set "TRACE_LOG=%RUNTIME_DIR%\agent_trigger_trace.log"
if not exist "%RUNTIME_DIR%" mkdir "%RUNTIME_DIR%"
>> "%TRACE_LOG%" echo [%date% %time%] start_robot_status_panel invoked source=%TRIGGER_SOURCE% reason=%TRIGGER_REASON%

set PYTHON_EXE=C:\Python311\pythonw.exe
if not exist "%PYTHON_EXE%" set PYTHON_EXE=C:\Python311\python.exe
if not exist "%PYTHON_EXE%" set PYTHON_EXE=pythonw
if not exist "%PYTHON_EXE%" set PYTHON_EXE=python

if exist "%RUNTIME_DIR%\robot_status_panel.pid" (
  for /f "usebackq delims=" %%p in ("%RUNTIME_DIR%\robot_status_panel.pid") do (
    tasklist /FI "PID eq %%p" | find "%%p" >nul 2>nul
    if not errorlevel 1 (
      >> "%TRACE_LOG%" echo [%date% %time%] start_robot_status_panel skipped existing pid=%%p
      endlocal & exit /b 0
    )
  )
  del /f /q "%RUNTIME_DIR%\robot_status_panel.pid" >nul 2>nul
)

if defined TARGET_EXE (
  for /f %%p in ('powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "$env:CLOUDAPP_ROBOT_DATA_DIR='%DATA_ROOT%'; $proc = Start-Process -FilePath '%TARGET_EXE%' -ArgumentList '--pc-role','status_panel','--instance-id','%INSTANCE_ID%' -WindowStyle Normal -PassThru; $proc.Id"') do (
    > "%RUNTIME_DIR%\robot_status_panel.pid" echo %%p
  )
) else (
  for /f %%p in ('powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "$env:CLOUDAPP_ROBOT_DATA_DIR='%DATA_ROOT%'; $proc = Start-Process -FilePath '%PYTHON_EXE%' -ArgumentList 'robot_client\\robot_status_panel.py','--instance-id','%INSTANCE_ID%' -PassThru; $proc.Id"') do (
    > "%RUNTIME_DIR%\robot_status_panel.pid" echo %%p
  )
)

endlocal
