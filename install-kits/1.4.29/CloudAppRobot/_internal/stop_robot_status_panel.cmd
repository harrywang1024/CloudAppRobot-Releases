@echo off
setlocal
set "BASE_DIR=%~dp0"

set INSTANCE_ID=%~1
if "%INSTANCE_ID%"=="" set INSTANCE_ID=pc
set "TRIGGER_SOURCE=%CLOUDAPP_TRIGGER_SOURCE%"
if "%TRIGGER_SOURCE%"=="" set "TRIGGER_SOURCE=manual_or_unknown"
set "TRIGGER_REASON=%CLOUDAPP_TRIGGER_REASON%"
if "%TRIGGER_REASON%"=="" set "TRIGGER_REASON=-"

if defined CLOUDAPP_ROBOT_DATA_DIR (
  set "DATA_ROOT=%CLOUDAPP_ROBOT_DATA_DIR%"
) else if exist "%BASE_DIR%CloudAppRobot.exe" (
  set "DATA_ROOT=%BASE_DIR%.robot_data"
) else if exist "%BASE_DIR%dist\CloudAppRobot\CloudAppRobot.exe" (
  set "DATA_ROOT=%BASE_DIR%.robot_data"
) else (
  set "DATA_ROOT=%APPDATA%\CloudAppRobot"
)

set "RUNTIME_DIR=%DATA_ROOT%\runtime\%INSTANCE_ID%"
set "TRACE_LOG=%RUNTIME_DIR%\agent_trigger_trace.log"
if not exist "%RUNTIME_DIR%" mkdir "%RUNTIME_DIR%"
>> "%TRACE_LOG%" echo [%date% %time%] stop_robot_status_panel invoked source=%TRIGGER_SOURCE% reason=%TRIGGER_REASON%

if exist "%RUNTIME_DIR%\robot_status_panel.pid" (
  for /f "usebackq delims=" %%p in ("%RUNTIME_DIR%\robot_status_panel.pid") do (
    >> "%TRACE_LOG%" echo [%date% %time%] stop_robot_status_panel killing pid=%%p
    taskkill /PID %%p /T /F >nul 2>nul
  )
  del /f /q "%RUNTIME_DIR%\robot_status_panel.pid" >nul 2>nul
)

endlocal
