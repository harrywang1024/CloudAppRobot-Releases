@echo off
setlocal
set SCRIPT_DIR=%~dp0
for %%I in ("%SCRIPT_DIR%..") do set REPO_DIR=%%~fI
cd /d "%REPO_DIR%"

set CONFIG_PATH=%~1
if "%CONFIG_PATH%"=="" set CONFIG_PATH=robot_client\config.ops.json
if not exist "%CONFIG_PATH%" if exist "robot_client\config.ops.template.json" copy /Y "robot_client\config.ops.template.json" "%CONFIG_PATH%" >nul

set PYTHON_EXE=C:\Python311\pythonw.exe
if not exist "%PYTHON_EXE%" set PYTHON_EXE=C:\Python311\python.exe
if not exist "%PYTHON_EXE%" set PYTHON_EXE=pythonw
if not exist "%PYTHON_EXE%" set PYTHON_EXE=python

start "" "%PYTHON_EXE%" robot_client\ops_console.py --config "%CONFIG_PATH%"
endlocal
