@echo off
setlocal EnableDelayedExpansion

set "BASE_DIR=%~dp0"
set "TRACE_REASON=%CLOUDAPP_TRIGGER_REASON%"
if "%TRACE_REASON%"=="" set "TRACE_REASON=update_resume"
set "TRACE_SOURCE=%CLOUDAPP_TRIGGER_SOURCE%"
if "%TRACE_SOURCE%"=="" set "TRACE_SOURCE=cloudapp_update_resume"

set "CLOUDAPP_TRIGGER_SOURCE=%TRACE_SOURCE%"
set "CLOUDAPP_TRIGGER_REASON=%TRACE_REASON%"

call "%BASE_DIR%start_robot.cmd"
exit /b %errorlevel%
