@echo off
setlocal EnableDelayedExpansion

cd /d "%~dp0"

set "BASE_DIR=%~dp0"
set "DATA_ROOT=%BASE_DIR%.robot_data"
set "INSTANCE_ID=%CLOUDAPP_RUNTIME_INSTANCE_ID%"
if "%INSTANCE_ID%"=="" set "INSTANCE_ID=pc"
set "RUNTIME_DIR=%DATA_ROOT%\runtime\%INSTANCE_ID%"
set "BOOT_LOG=%RUNTIME_DIR%\startup_bootstrap.log"
set "AGENT_PID_FILE=%RUNTIME_DIR%\cloudapp_agent.pid"

if not exist "%RUNTIME_DIR%" mkdir "%RUNTIME_DIR%"
>> "%BOOT_LOG%" echo [%date% %time%] start_robot entry

set "CONFIG_PATH=%CLOUDAPP_BOT_CONFIG_PATH%"
if "%CONFIG_PATH%"=="" set "CONFIG_PATH=%BASE_DIR%config.pc.json"
if not exist "%CONFIG_PATH%" (
    echo [ERROR] Bot config file not found: %CONFIG_PATH%
    exit /b 1
)

if exist "%AGENT_PID_FILE%" (
    for /f "usebackq delims=" %%p in ("%AGENT_PID_FILE%") do (
        call :is_numeric_pid "%%p"
        if not errorlevel 1 (
            for /f "usebackq delims=" %%q in (`powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "$pid = [int]'%%p'; $cfg = [System.IO.Path]::GetFullPath('%CONFIG_PATH%').ToLowerInvariant(); $instance = ('--instance-id %INSTANCE_ID%').ToLowerInvariant(); $match = Get-CimInstance Win32_Process -Filter \"ProcessId = $pid\" -ErrorAction SilentlyContinue | Where-Object { ($_.Name -eq 'CloudAppAgent.exe' -or ($_.Name -eq 'CloudAppRobot.exe' -and $_.CommandLine -and ($_.CommandLine.ToLowerInvariant().Contains('--pc-role agent') -or $_.CommandLine.ToLowerInvariant().Contains('--pc-role=agent')))) -and $_.CommandLine -and $_.CommandLine.ToLowerInvariant().Contains($instance) -and $_.CommandLine.ToLowerInvariant().Contains($cfg) } | Select-Object -First 1 -ExpandProperty ProcessId; if ($match) { [string]$match }"` ) do set "MATCHED_AGENT_PID=%%q"
            if defined MATCHED_AGENT_PID (
                >> "%BOOT_LOG%" echo [%date% %time%] existing agent pid=!MATCHED_AGENT_PID!, ensuring business stack startup
                call "%BASE_DIR%start_pc_robot_exe.cmd"
                exit /b %errorlevel%
            )
        )
    )
    set "MATCHED_AGENT_PID="
    del /f /q "%AGENT_PID_FILE%" >nul 2>nul
)

set "EXISTING_AGENT_PID="
for /f "usebackq delims=" %%p in (`powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "$cfg = [System.IO.Path]::GetFullPath('%CONFIG_PATH%').ToLowerInvariant(); $instance = ('--instance-id %INSTANCE_ID%').ToLowerInvariant(); $match = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { ($_.Name -eq 'CloudAppAgent.exe' -or ($_.Name -eq 'CloudAppRobot.exe' -and $_.CommandLine -and ($_.CommandLine.ToLowerInvariant().Contains('--pc-role agent') -or $_.CommandLine.ToLowerInvariant().Contains('--pc-role=agent')))) -and $_.CommandLine -and $_.CommandLine.ToLowerInvariant().Contains($instance) -and $_.CommandLine.ToLowerInvariant().Contains($cfg) } | Select-Object -First 1 -ExpandProperty ProcessId; if ($match) { [string]$match }"` ) do set "EXISTING_AGENT_PID=%%p"
if defined EXISTING_AGENT_PID (
    >> "%BOOT_LOG%" echo [%date% %time%] discovered existing agent pid=%EXISTING_AGENT_PID% via command line probe
    > "%AGENT_PID_FILE%" echo %EXISTING_AGENT_PID%
    call "%BASE_DIR%start_pc_robot_exe.cmd"
    exit /b %errorlevel%
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

if defined AGENT_EXE (
    >> "%BOOT_LOG%" echo [%date% %time%] launching standalone CloudAppAgent.exe
    set "CLOUDAPP_ROBOT_DATA_DIR=%DATA_ROOT%"
    start "" "%AGENT_EXE%" --instance-id "%INSTANCE_ID%" --bot-config "%CONFIG_PATH%"
    set "LAUNCH_RC=%ERRORLEVEL%"
 ) else (
    if not defined ROBOT_EXE (
        echo [ERROR] Neither CloudAppAgent.exe nor CloudAppRobot.exe was found.
        exit /b 1
    )
    >> "%BOOT_LOG%" echo [%date% %time%] launching embedded agent role fallback
    set "CLOUDAPP_ROBOT_DATA_DIR=%DATA_ROOT%"
    start "" "%ROBOT_EXE%" --pc-role agent --instance-id "%INSTANCE_ID%" --bot-config "%CONFIG_PATH%"
    set "LAUNCH_RC=%ERRORLEVEL%"
)

if not "%LAUNCH_RC%"=="0" (
    >> "%BOOT_LOG%" echo [%date% %time%] failed to launch agent
    echo [ERROR] Failed to start CloudAppAgent.
    exit /b 1
)

>> "%BOOT_LOG%" echo [%date% %time%] launch command accepted

set "START_OK="
for /L %%i in (1,1,12) do (
    if not defined START_OK if exist "%AGENT_PID_FILE%" (
        for /f "usebackq delims=" %%p in ("%AGENT_PID_FILE%") do (
            call :is_numeric_pid "%%p"
            if not errorlevel 1 (
                tasklist /FI "PID eq %%p" | find "%%p" >nul 2>nul
                if not errorlevel 1 set "START_OK=1"
            )
        )
    )
    if not defined START_OK if defined AGENT_EXE (
        tasklist /FI "IMAGENAME eq CloudAppAgent.exe" | find /I "CloudAppAgent.exe" >nul 2>nul
        if not errorlevel 1 set "START_OK=1"
    ) else (
        tasklist /FI "IMAGENAME eq CloudAppRobot.exe" | find /I "CloudAppRobot.exe" >nul 2>nul
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

:is_numeric_pid
setlocal
set "VALUE=%~1"
echo(%VALUE%| findstr /R "^[0-9][0-9]*$" >nul
endlocal & exit /b %errorlevel%
