@echo off
REM Device Monitor Kiosk Registry Configuration Script
REM This script configures Windows registry for kiosk mode

setlocal enabledelayedexpansion

echo Device Monitor Kiosk Registry Configuration
echo ==========================================

REM Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script must be run as Administrator
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

echo Configuring Windows registry for kiosk mode...

REM Auto-login configuration
echo Setting up auto-login...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "AutoAdminLogon" /t REG_SZ /d "1" /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultUserName" /t REG_SZ /d "KioskUser" /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultPassword" /t REG_SZ /d "KioskPass123!" /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "ForceAutoLogon" /t REG_SZ /d "1" /f

REM Application auto-start (fallback method)
echo Setting up application auto-start...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "DeviceMonitorKiosk" /t REG_SZ /d "C:\Program Files\DeviceMonitor\main.py --kiosk" /f

REM Disable Ctrl+Alt+Del requirement
echo Disabling Ctrl+Alt+Del requirement...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "DisableCAD" /t REG_DWORD /d 1 /f

REM Disable Task Manager
echo Disabling Task Manager...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "DisableTaskMgr" /t REG_DWORD /d 1 /f

REM Disable Registry Editor
echo Disabling Registry Editor...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "DisableRegistryTools" /t REG_DWORD /d 1 /f

REM Disable Alt+Tab
echo Disabling Alt+Tab...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoWindowMinimizingShortcuts" /t REG_DWORD /d 1 /f

REM Disable Windows key
echo Disabling Windows key...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoWinKeys" /t REG_DWORD /d 1 /f

REM Hide desktop icons
echo Hiding desktop icons...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoDesktop" /t REG_DWORD /d 1 /f

REM Disable right-click context menu
echo Disabling right-click context menu...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoViewContextMenu" /t REG_DWORD /d 1 /f

REM Disable system tray
echo Configuring system tray restrictions...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoTrayContextMenu" /t REG_DWORD /d 1 /f

REM Disable Run dialog
echo Disabling Run dialog...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoRun" /t REG_DWORD /d 1 /f

REM Disable Command Prompt
echo Disabling Command Prompt...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System" /v "DisableCMD" /t REG_DWORD /d 2 /f

REM Disable PowerShell
echo Disabling PowerShell...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell" /v "EnableScripts" /t REG_DWORD /d 0 /f

REM Set screen saver timeout to never
echo Disabling screen saver...
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "ScreenSaveActive" /t REG_SZ /d "0" /f
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "ScreenSaveTimeOut" /t REG_SZ /d "0" /f

REM Disable Windows Update restart notifications
echo Disabling Windows Update restart notifications...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoRebootWithLoggedOnUsers" /t REG_DWORD /d 1 /f

REM Create kiosk user if it doesn't exist
echo Creating kiosk user...
net user KioskUser KioskPass123! /add /comment:"Kiosk User Account" /expires:never /passwordchg:no 2>nul
net localgroup Users KioskUser /add 2>nul

echo.
echo Registry configuration completed successfully!
echo.
echo WARNING: Some changes require a system restart to take effect.
echo.
echo Next steps:
echo 1. Install the Windows service: python windows_service.py install
echo 2. Restart the system
echo 3. The system will automatically login as KioskUser
echo 4. The Device Monitor application will start automatically
echo.

pause