@echo off
setlocal EnableDelayedExpansion

cd /d "%~dp0"

set "BASE_DIR=%~dp0"
set "DATA_ROOT=%BASE_DIR%.robot_data"
set "RUNTIME_DIR=%DATA_ROOT%\runtime\pc"
set "BOOT_LOG=%RUNTIME_DIR%\startup_bootstrap.log"
set "AGENT_PID_FILE=%RUNTIME_DIR%\cloudapp_agent.pid"

if not exist "%RUNTIME_DIR%" mkdir "%RUNTIME_DIR%"
>> "%BOOT_LOG%" echo [%date% %time%] start_robot entry

if exist "%AGENT_PID_FILE%" (
    for /f "usebackq delims=" %%p in ("%AGENT_PID_FILE%") do (
        tasklist /FI "PID eq %%p" | find "%%p" >nul 2>nul
        if not errorlevel 1 (
            >> "%BOOT_LOG%" echo [%date% %time%] existing agent pid=%%p, ensuring business stack startup
            call "%BASE_DIR%start_pc_robot_exe.cmd"
            exit /b %errorlevel%
        )
    )
    del /f /q "%AGENT_PID_FILE%" >nul 2>nul
)

set "AGENT_EXE="
if exist "%BASE_DIR%CloudAppAgent.exe" (
    set "AGENT_EXE=%BASE_DIR%CloudAppAgent.exe"
)

set "ROBOT_EXE="
if exist "%BASE_DIR%CloudAppRobot.exe" (
    set "ROBOT_EXE=%BASE_DIR%CloudAppRobot.exe"
) else if exist "%BASE_DIR%dist\CloudAppRobot\CloudAppRobot.exe" (
    set "ROBOT_EXE=%BASE_DIR%dist\CloudAppRobot\CloudAppRobot.exe"
)

set "CONFIG_PATH=%BASE_DIR%config.pc.json"
if not exist "%CONFIG_PATH%" (
    echo [ERROR] config.pc.json not found next to this script.
    exit /b 1
)

set "LAUNCHED_PID="
if defined AGENT_EXE (
    >> "%BOOT_LOG%" echo [%date% %time%] launching CloudAppAgent.exe
    for /f %%p in ('powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "$env:CLOUDAPP_ROBOT_DATA_DIR='%DATA_ROOT%'; $proc = Start-Process -FilePath '%AGENT_EXE%' -ArgumentList @('--instance-id','pc','--bot-config','%CONFIG_PATH%') -WindowStyle Hidden -PassThru; $proc.Id"') do (
        set "LAUNCHED_PID=%%p"
    )
) else (
    if not defined ROBOT_EXE (
        echo [ERROR] Neither CloudAppAgent.exe nor CloudAppRobot.exe was found.
        exit /b 1
    )
    >> "%BOOT_LOG%" echo [%date% %time%] launching embedded agent role
    for /f %%p in ('powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "$env:CLOUDAPP_ROBOT_DATA_DIR='%DATA_ROOT%'; $proc = Start-Process -FilePath '%ROBOT_EXE%' -ArgumentList @('--pc-role','agent','--instance-id','pc','--bot-config','%CONFIG_PATH%') -WindowStyle Hidden -PassThru; $proc.Id"') do (
        set "LAUNCHED_PID=%%p"
    )
)

if errorlevel 1 (
    >> "%BOOT_LOG%" echo [%date% %time%] failed to launch agent
    echo [ERROR] Failed to start CloudAppAgent.
    exit /b 1
)

>> "%BOOT_LOG%" echo [%date% %time%] launched agent pid=!LAUNCHED_PID!

set "START_OK="
for /L %%i in (1,1,12) do (
    if not defined START_OK if exist "%AGENT_PID_FILE%" set "START_OK=1"
    if not defined START_OK if defined LAUNCHED_PID (
        tasklist /FI "PID eq !LAUNCHED_PID!" | find "!LAUNCHED_PID!" >nul 2>nul
        if not errorlevel 1 set "START_OK=1"
    )
    if not defined START_OK timeout /t 1 /nobreak >nul
)

if not defined START_OK (
    >> "%BOOT_LOG%" echo [%date% %time%] agent verification failed
    echo [ERROR] Agent did not come up within 12 seconds.
    exit /b 1
)

>> "%BOOT_LOG%" echo [%date% %time%] agent verification ok
>> "%BOOT_LOG%" echo [%date% %time%] agent started; launching business stack once
call "%BASE_DIR%start_pc_robot_exe.cmd"
exit /b %errorlevel%
