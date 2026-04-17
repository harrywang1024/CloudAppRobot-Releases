@echo off
setlocal

set "BASE_DIR=%~dp0"
if defined CLOUDAPP_ROBOT_DATA_DIR (
    set "DATA_ROOT=%CLOUDAPP_ROBOT_DATA_DIR%"
) else if exist "%BASE_DIR%CloudAppRobot.exe" (
    set "DATA_ROOT=%BASE_DIR%.robot_data"
) else if exist "%BASE_DIR%dist\CloudAppRobot\CloudAppRobot.exe" (
    set "DATA_ROOT=%BASE_DIR%.robot_data"
) else (
    set "DATA_ROOT=%APPDATA%\CloudAppRobot"
)
set "RUNTIME_DIR=%DATA_ROOT%\runtime\pc"
set "TRACE_LOG=%RUNTIME_DIR%\agent_trigger_trace.log"
set "TRIGGER_SOURCE=%CLOUDAPP_TRIGGER_SOURCE%"
if "%TRIGGER_SOURCE%"=="" set "TRIGGER_SOURCE=manual_or_unknown"
set "TRIGGER_REASON=%CLOUDAPP_TRIGGER_REASON%"
if "%TRIGGER_REASON%"=="" set "TRIGGER_REASON=-"

echo Stopping CloudAppRobot business processes from:
echo   %RUNTIME_DIR%
>> "%TRACE_LOG%" echo [%date% %time%] stop_pc_robot_exe invoked source=%TRIGGER_SOURCE% reason=%TRIGGER_REASON%

powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command ^
  "$runtimeDir = '%RUNTIME_DIR%';" ^
  "$exclude = @('cloudapp_agent.pid');" ^
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
  "}"

echo CloudAppRobot business stop command finished.
call "%BASE_DIR%stop_robot_status_panel.cmd" pc
exit /b 0
