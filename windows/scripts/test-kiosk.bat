@echo off
REM Windows Kiosk Testing and Troubleshooting Script

setlocal enabledelayedexpansion

echo Device Monitor Kiosk Testing Script
echo ====================================

REM Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script should be run as Administrator for complete testing
    echo Some tests may fail without administrative privileges
    echo.
)

set INSTALL_PATH=C:\Program Files\DeviceMonitor
set KIOSK_USER=KioskUser
set LOG_PATH=C:\ProgramData\DeviceMonitor

echo Testing Device Monitor Kiosk installation...
echo.

REM Test 1: Installation directory
echo [TEST 1] Installation directory...
if exist "%INSTALL_PATH%" (
    echo PASS: Installation directory exists: %INSTALL_PATH%
    dir "%INSTALL_PATH%" /b
) else (
    echo FAIL: Installation directory not found: %INSTALL_PATH%
)
echo.

REM Test 2: Main application file
echo [TEST 2] Main application file...
if exist "%INSTALL_PATH%\main.py" (
    echo PASS: Main application found: main.py
) else (
    echo FAIL: Main application not found: main.py
)
echo.

REM Test 3: Windows service
echo [TEST 3] Windows service...
sc query DeviceMonitorKiosk >nul 2>&1
if %errorLevel% equ 0 (
    echo PASS: Windows service exists
    sc query DeviceMonitorKiosk | findstr "STATE"
) else (
    echo FAIL: Windows service not found
)
echo.

REM Test 4: Python installation
echo [TEST 4] Python installation...
python --version >nul 2>&1
if %errorLevel% equ 0 (
    echo PASS: Python is installed
    python --version
) else (
    echo FAIL: Python not found or not in PATH
)
echo.

REM Test 5: Python dependencies
echo [TEST 5] Python dependencies...
python -c "import tkinter; print('tkinter: OK')" 2>nul
if %errorLevel% equ 0 (
    echo PASS: tkinter available
) else (
    echo FAIL: tkinter not available
)

python -c "import win32serviceutil; print('pywin32: OK')" 2>nul
if %errorLevel% equ 0 (
    echo PASS: pywin32 available
) else (
    echo FAIL: pywin32 not available
)
echo.

REM Test 6: Kiosk user
echo [TEST 6] Kiosk user...
net user %KIOSK_USER% >nul 2>&1
if %errorLevel% equ 0 (
    echo PASS: Kiosk user exists: %KIOSK_USER%
    net user %KIOSK_USER% | findstr "Local Group"
) else (
    echo FAIL: Kiosk user not found: %KIOSK_USER%
)
echo.

REM Test 7: Auto-login registry settings
echo [TEST 7] Auto-login configuration...
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon 2>nul | findstr "0x1" >nul
if %errorLevel% equ 0 (
    echo PASS: Auto-login is enabled
) else (
    echo FAIL: Auto-login not configured
)

reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName 2>nul | findstr "%KIOSK_USER%" >nul
if %errorLevel% equ 0 (
    echo PASS: Auto-login user is set to %KIOSK_USER%
) else (
    echo FAIL: Auto-login user not set correctly
)
echo.

REM Test 8: Kiosk restrictions
echo [TEST 8] Kiosk restrictions...
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableTaskMgr 2>nul | findstr "0x1" >nul
if %errorLevel% equ 0 (
    echo PASS: Task Manager is disabled
) else (
    echo INFO: Task Manager not disabled
)

reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableCAD 2>nul | findstr "0x1" >nul
if %errorLevel% equ 0 (
    echo PASS: Ctrl+Alt+Del is disabled
) else (
    echo INFO: Ctrl+Alt+Del not disabled
)
echo.

REM Test 9: Log directory and files
echo [TEST 9] Log directory...
if exist "%LOG_PATH%" (
    echo PASS: Log directory exists: %LOG_PATH%
    if exist "%LOG_PATH%\service.log" (
        echo INFO: Service log file exists
        echo Last 5 lines of service log:
        powershell "Get-Content '%LOG_PATH%\service.log' -Tail 5" 2>nul
    ) else (
        echo INFO: Service log file not found (created on first run)
    )
) else (
    echo INFO: Log directory not found (created on first run)
)
echo.

REM Test 10: Application startup test
echo [TEST 10] Application startup test...
echo This will attempt to start the application for 10 seconds...
echo Press Ctrl+C if the application starts successfully
echo.
timeout /t 3 /nobreak >nul
cd /d "%INSTALL_PATH%" 2>nul
if exist "main.py" (
    echo Starting application test...
    timeout /t 10 /nobreak | python main.py --kiosk 2>nul
    if %errorLevel% equ 1 (
        echo INFO: Application test interrupted (normal for kiosk mode)
    ) else (
        echo INFO: Application test completed
    )
) else (
    echo SKIP: Cannot test application - main.py not found
)
echo.

REM Summary
echo ====================================
echo Test Summary:
echo - Check the results above for any FAIL entries
echo - Address any failures before deploying in production
echo - INFO entries are informational and usually okay
echo.

REM Additional troubleshooting options
echo Troubleshooting options:
echo 1. View service logs:     Get-EventLog -LogName Application -Source DeviceMonitorKiosk
echo 2. Service management:    services.msc
echo 3. Registry editor:       regedit (if enabled)
echo 4. Manual app start:      cd "%INSTALL_PATH%" ^&^& python main.py --kiosk
echo 5. Service restart:       net stop DeviceMonitorKiosk ^&^& net start DeviceMonitorKiosk
echo.

pause