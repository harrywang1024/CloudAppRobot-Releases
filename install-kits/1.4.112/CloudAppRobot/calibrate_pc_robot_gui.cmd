@echo off
setlocal
cd /d "%~dp0"

if not exist "CloudAppRobot.exe" (
  echo CloudAppRobot.exe not found in %cd%
  pause
  exit /b 1
)

echo Starting GUI calibration...
echo Keep WeChat open and visible, then follow the terminal prompts.
echo.

CloudAppRobot.exe --pc-role calibrate

echo.
echo Calibration finished. Press any key to close.
pause >nul
