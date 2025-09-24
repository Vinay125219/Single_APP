@echo off
REM Enhanced Device Monitor Kiosk Script for Windows
REM This script provides robust kiosk functionality with logging and error handling

setlocal enabledelayedexpansion

REM Configuration
set APP_NAME=main.py
set APP_PATH=%~dp0..\%APP_NAME%
set LOG_FILE=%~dp0..\kiosk.log
set MAX_RESTARTS=10
set RESTART_DELAY=5
set RESTART_COUNT=0

REM Ensure we're in the correct directory
cd /d "%~dp0.."

echo Device Monitor Kiosk Started at %DATE% %TIME% >> "%LOG_FILE%"
echo Application Path: %APP_PATH% >> "%LOG_FILE%"

:main_loop
echo Starting Device Monitor Application... >> "%LOG_FILE%"
echo Restart count: !RESTART_COUNT!/!MAX_RESTARTS! >> "%LOG_FILE%"

REM Check if we've exceeded maximum restarts
if !RESTART_COUNT! geq !MAX_RESTARTS! (
    echo ERROR: Maximum restart attempts reached (!MAX_RESTARTS!) >> "%LOG_FILE%"
    echo System may have a persistent issue. Please check logs. >> "%LOG_FILE%"
    echo Press any key to reset counter or close to exit...
    pause
    set RESTART_COUNT=0
    goto main_loop
)

REM Check if application file exists
if not exist "%APP_PATH%" (
    echo ERROR: Application file not found: %APP_PATH% >> "%LOG_FILE%"
    echo Please ensure the application is properly installed.
    echo Press any key to retry...
    pause
    goto main_loop
)

REM Start the application with kiosk mode
set KIOSK=1
python "%APP_PATH%" --kiosk
set EXIT_CODE=!ERRORLEVEL!

echo Application exited with code: !EXIT_CODE! at %DATE% %TIME% >> "%LOG_FILE%"

REM Handle different exit codes
if !EXIT_CODE! equ 0 (
    echo Normal application exit >> "%LOG_FILE%"
    set RESTART_COUNT=0
) else if !EXIT_CODE! equ 1 (
    echo Application error exit >> "%LOG_FILE%"
    set /a RESTART_COUNT+=1
) else (
    echo Unexpected exit code: !EXIT_CODE! >> "%LOG_FILE%"
    set /a RESTART_COUNT+=1
)

echo Restarting in !RESTART_DELAY! seconds... >> "%LOG_FILE%"
echo Application will restart in !RESTART_DELAY! seconds...
timeout /t !RESTART_DELAY! /nobreak >nul

goto main_loop
