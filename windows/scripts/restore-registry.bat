@echo off
REM Device Monitor Kiosk Registry Restoration Script
REM This script removes kiosk mode registry settings

setlocal enabledelayedexpansion

echo Device Monitor Kiosk Registry Restoration
echo ==========================================

REM Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script must be run as Administrator
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

echo Removing kiosk mode registry settings...

REM Remove auto-login configuration
echo Removing auto-login settings...
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "AutoAdminLogon" /f 2>nul
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultUserName" /f 2>nul
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultPassword" /f 2>nul
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "ForceAutoLogon" /f 2>nul

REM Remove application auto-start
echo Removing application auto-start...
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "DeviceMonitorKiosk" /f 2>nul

REM Enable Ctrl+Alt+Del requirement
echo Enabling Ctrl+Alt+Del requirement...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "DisableCAD" /t REG_DWORD /d 0 /f

REM Enable Task Manager
echo Enabling Task Manager...
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "DisableTaskMgr" /f 2>nul

REM Enable Registry Editor
echo Enabling Registry Editor...
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "DisableRegistryTools" /f 2>nul

REM Enable Alt+Tab
echo Enabling Alt+Tab...
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoWindowMinimizingShortcuts" /f 2>nul

REM Enable Windows key
echo Enabling Windows key...
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoWinKeys" /f 2>nul

REM Show desktop icons
echo Showing desktop icons...
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoDesktop" /f 2>nul

REM Enable right-click context menu
echo Enabling right-click context menu...
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoViewContextMenu" /f 2>nul

REM Enable system tray
echo Enabling system tray...
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoTrayContextMenu" /f 2>nul

REM Enable Run dialog
echo Enabling Run dialog...
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoRun" /f 2>nul

REM Enable Command Prompt
echo Enabling Command Prompt...
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System" /v "DisableCMD" /f 2>nul

REM Enable PowerShell
echo Enabling PowerShell...
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell" /v "EnableScripts" /f 2>nul

REM Restore screen saver settings
echo Restoring screen saver settings...
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "ScreenSaveActive" /t REG_SZ /d "1" /f
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "ScreenSaveTimeOut" /t REG_SZ /d "900" /f

REM Enable Windows Update restart notifications
echo Enabling Windows Update restart notifications...
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoRebootWithLoggedOnUsers" /f 2>nul

echo.
echo Registry restoration completed successfully!
echo.
echo The system has been restored to normal Windows configuration.
echo You may want to restart the system for all changes to take effect.
echo.

pause