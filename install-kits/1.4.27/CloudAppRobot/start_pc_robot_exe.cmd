@echo off
setlocal EnableDelayedExpansion

set "BASE_DIR=%~dp0"
set "EXE_PATH="
set "DATA_ROOT=%BASE_DIR%.robot_data"
set "RUNTIME_DIR=%DATA_ROOT%\runtime\pc"
set "BOOT_LOG=%RUNTIME_DIR%\startup_bootstrap.log"
set "TRACE_LOG=%RUNTIME_DIR%\agent_trigger_trace.log"
set "TRIGGER_SOURCE=%CLOUDAPP_TRIGGER_SOURCE%"
if "%TRIGGER_SOURCE%"=="" set "TRIGGER_SOURCE=manual_or_unknown"
set "TRIGGER_REASON=%CLOUDAPP_TRIGGER_REASON%"
if "%TRIGGER_REASON%"=="" set "TRIGGER_REASON=-"

if exist "%BASE_DIR%CloudAppRobot.exe" (
    set "EXE_PATH=%BASE_DIR%CloudAppRobot.exe"
) else if exist "%BASE_DIR%dist\CloudAppRobot\CloudAppRobot.exe" (
    set "EXE_PATH=%BASE_DIR%dist\CloudAppRobot\CloudAppRobot.exe"
)

if not defined EXE_PATH (
    echo [ERROR] CloudAppRobot.exe not found.
    exit /b 1
)

set "CONFIG_PATH=%BASE_DIR%config.pc.json"
if not exist "%CONFIG_PATH%" (
    echo [ERROR] config.pc.json not found next to this script.
    exit /b 1
)

if not exist "%RUNTIME_DIR%" mkdir "%RUNTIME_DIR%"

> "%BOOT_LOG%" echo [%date% %time%] bootstrap start
>> "%TRACE_LOG%" echo [%date% %time%] start_pc_robot_exe invoked source=%TRIGGER_SOURCE% reason=%TRIGGER_REASON%
>> "%BOOT_LOG%" echo BASE_DIR=%BASE_DIR%
>> "%BOOT_LOG%" echo EXE_PATH=%EXE_PATH%
>> "%BOOT_LOG%" echo CONFIG_PATH=%CONFIG_PATH%
>> "%BOOT_LOG%" echo DATA_ROOT=%DATA_ROOT%
>> "%BOOT_LOG%" echo RUNTIME_DIR=%RUNTIME_DIR%

if exist "%RUNTIME_DIR%\group_bot_supervisor.pid" (
    for /f "usebackq delims=" %%p in ("%RUNTIME_DIR%\group_bot_supervisor.pid") do (
        call :is_numeric_pid "%%p"
        if not errorlevel 1 (
            tasklist /FI "PID eq %%p" | find "%%p" >nul 2>nul
            if not errorlevel 1 (
                echo [INFO] CloudAppRobot supervisor is already running with PID %%p
                >> "%BOOT_LOG%" echo [%date% %time%] existing supervisor pid=%%p
                call "%BASE_DIR%start_robot_status_panel.cmd" pc
                exit /b 0
            )
        )
    )
    del /f /q "%RUNTIME_DIR%\group_bot_supervisor.pid" >nul 2>nul
)

echo Starting CloudAppRobot in background...
echo [NOTE] For first launch on a new PC, run this script as Administrator once so WeCloudapp can finish local session setup.
for /f %%p in ('powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command ^
  "$env:CLOUDAPP_ROBOT_DATA_DIR='%DATA_ROOT%'; $proc = Start-Process -FilePath '%EXE_PATH%' -ArgumentList @('--pc-role','supervisor','--instance-id','pc','--bot-config','%CONFIG_PATH%') -WindowStyle Hidden -PassThru; $proc.Id"') do (
    set "LAUNCHED_PID=%%p"
)

if errorlevel 1 (
    echo [ERROR] Failed to start CloudAppRobot.exe
    >> "%BOOT_LOG%" echo [%date% %time%] failed to launch exe
    exit /b 1
)

>> "%BOOT_LOG%" echo [%date% %time%] launched pid=%LAUNCHED_PID%

set "START_OK="
for /L %%i in (1,1,10) do (
    if not defined START_OK if defined LAUNCHED_PID (
        call :is_numeric_pid "!LAUNCHED_PID!"
        if not errorlevel 1 (
            tasklist /FI "PID eq !LAUNCHED_PID!" | find "!LAUNCHED_PID!" >nul 2>nul
            if not errorlevel 1 set "START_OK=1"
        )
    )
    if not defined START_OK if exist "%RUNTIME_DIR%\status_supervisor.json" set "START_OK=1"
    if not defined START_OK if exist "%RUNTIME_DIR%\group_bot_supervisor.pid" (
        for /f "usebackq delims=" %%p in ("%RUNTIME_DIR%\group_bot_supervisor.pid") do (
            call :is_numeric_pid "%%p"
            if not errorlevel 1 (
                tasklist /FI "PID eq %%p" | find "%%p" >nul 2>nul
                if not errorlevel 1 (
                    set "START_OK=1"
                )
            )
        )
    )
    if not defined START_OK timeout /t 1 /nobreak >nul
)
if not defined START_OK (
    echo [ERROR] CloudAppRobot did not create a live supervisor within 10 seconds.
    echo [ERROR] Check: %BOOT_LOG%
    >> "%BOOT_LOG%" echo [%date% %time%] supervisor verification failed
    if exist "%RUNTIME_DIR%\status_supervisor.json" >> "%BOOT_LOG%" echo [%date% %time%] status_supervisor.json exists
    if exist "%RUNTIME_DIR%\group_bot_supervisor.pid" >> "%BOOT_LOG%" echo [%date% %time%] group_bot_supervisor.pid exists
    exit /b 1
)

>> "%BOOT_LOG%" echo [%date% %time%] supervisor verification ok
call "%BASE_DIR%start_robot_status_panel.cmd" pc

echo CloudAppRobot started.
exit /b 0

:is_numeric_pid
setlocal
set "VALUE=%~1"
echo(%VALUE%| findstr /R "^[0-9][0-9]*$" >nul
endlocal & exit /b %errorlevel%
