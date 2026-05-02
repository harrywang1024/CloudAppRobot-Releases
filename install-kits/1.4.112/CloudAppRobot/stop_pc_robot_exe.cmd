@echo off
setlocal EnableDelayedExpansion

set "BASE_DIR=%~dp0"
set "INSTANCE_ID=%CLOUDAPP_RUNTIME_INSTANCE_ID%"
if "%INSTANCE_ID%"=="" set "INSTANCE_ID=pc"
set "CONFIG_PATH=%CLOUDAPP_BOT_CONFIG_PATH%"
if "%CONFIG_PATH%"=="" set "CONFIG_PATH=%BASE_DIR%config.pc.json"
set "STOP_AGENT=%CLOUDAPP_STOP_AGENT%"
if /I "%~1"=="all" set "STOP_AGENT=1"
if /I "%~1"=="full" set "STOP_AGENT=1"
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
set "TRIGGER_SOURCE=%CLOUDAPP_TRIGGER_SOURCE%"
if "%TRIGGER_SOURCE%"=="" set "TRIGGER_SOURCE=manual_or_unknown"
set "TRIGGER_REASON=%CLOUDAPP_TRIGGER_REASON%"
if "%TRIGGER_REASON%"=="" set "TRIGGER_REASON=-"
if "%STOP_AGENT%"=="" set "STOP_AGENT=0"

echo Stopping CloudAppRobot processes from:
echo   %RUNTIME_DIR%
>> "%TRACE_LOG%" echo [%date% %time%] stop_pc_robot_exe invoked source=%TRIGGER_SOURCE% reason=%TRIGGER_REASON%
>> "%TRACE_LOG%" echo [%date% %time%] stop_pc_robot_exe stop_agent=%STOP_AGENT%

powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command ^
  "$runtimeDir = '%RUNTIME_DIR%';" ^
  "$configPath = [System.IO.Path]::GetFullPath('%CONFIG_PATH%').ToLowerInvariant();" ^
  "$stopAgent = '%STOP_AGENT%' -eq '1';" ^
  "$exclude = if ($stopAgent) { @() } else { @('cloudapp_agent.pid') };" ^
  "$pidFiles = Get-ChildItem -Path $runtimeDir -Filter '*.pid' -ErrorAction SilentlyContinue | Where-Object { $exclude -notcontains $_.Name } | Select-Object -ExpandProperty Name;" ^
  "foreach ($name in $pidFiles) {" ^
  "  $path = Join-Path $runtimeDir $name;" ^
  "  if (Test-Path $path) {" ^
  "    try {" ^
  "      $procIdValue = [int](Get-Content $path -ErrorAction Stop | Select-Object -First 1);" ^
      "      $proc = Get-Process -Id $procIdValue -ErrorAction SilentlyContinue;" ^
      "      if ($proc) { Stop-Process -Id $procIdValue -Force -ErrorAction SilentlyContinue; Write-Host ('Stopped PID ' + $procIdValue + ' from ' + $name) }" ^
      "      Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue | Out-Null;" ^
  "    } catch { }" ^
  "  }" ^
  "}" ^
  "$names = if ($stopAgent) { @('CloudAppAgent.exe','CloudAppRobot.exe') } else { @('CloudAppRobot.exe') };" ^
  "Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $names -contains $_.Name -and $_.CommandLine -and $_.CommandLine.ToLowerInvariant().Contains($configPath) } | ForEach-Object {" ^
  "  try { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue; Write-Host ('Stopped PID ' + $_.ProcessId + ' via command line match') } catch { }" ^
  "}"

if "%STOP_AGENT%"=="1" (
    >> "%TRACE_LOG%" echo [%date% %time%] full stop mode enabled; clearing local command/update state
    for %%f in (
        "cloudapp_agent.pid"
        "remote_commands.json"
        "remote_commands.fallback.json"
        "remote_command_results.json"
        "pending_remote_update.json"
        "pending_update_handoff.json"
    ) do (
        if exist "%DATA_ROOT%\%%~f" del /f /q "%DATA_ROOT%\%%~f" >nul 2>nul
        if exist "%RUNTIME_DIR%\%%~f" del /f /q "%RUNTIME_DIR%\%%~f" >nul 2>nul
    )
    if exist "%RUNTIME_DIR%\update_in_progress.json" del /f /q "%RUNTIME_DIR%\update_in_progress.json" >nul 2>nul
)

echo CloudAppRobot business stop command finished.
call "%BASE_DIR%stop_robot_status_panel.cmd" "%INSTANCE_ID%"
exit /b 0
