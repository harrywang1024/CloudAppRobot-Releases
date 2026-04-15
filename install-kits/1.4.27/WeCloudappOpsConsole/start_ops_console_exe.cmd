@echo off
setlocal
cd /d "%~dp0"

set "CONFIG_PATH=%~1"
if "%CONFIG_PATH%"=="" set "CONFIG_PATH=config.ops.json"
if not exist "%CONFIG_PATH%" if exist "config.ops.template.json" copy /Y "config.ops.template.json" "%CONFIG_PATH%" >nul

start "" "%~dp0WeCloudappOpsConsole.exe" --config "%CONFIG_PATH%"
endlocal
