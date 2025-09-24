# Kiosk Auto-Boot Implementation Guide

## Overview
Auto-boot functionality ensures your kiosk application starts automatically when the system boots, creating a true kiosk experience where users cannot access the underlying OS.

## RHEL 7.9 Implementation

### 1. Systemd Service (Recommended)

Create a systemd service file for your application:

**File:** `/etc/systemd/system/device-monitor-kiosk.service`
```ini
[Unit]
Description=Device Monitor Kiosk Application
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
User=kioskuser
Group=kioskuser
Environment=DISPLAY=:0
Environment=KIOSK=1
Environment=XDG_RUNTIME_DIR=/run/user/1001
ExecStart=/opt/device-monitor/device_monitor_linux_kiosk
Restart=always
RestartSec=3
KillMode=mixed
TimeoutStopSec=10

[Install]
WantedBy=graphical.target
```

**Setup Commands:**
```bash
# Create kiosk user
sudo useradd -m -s /bin/bash kioskuser
sudo passwd kioskuser

# Create application directory
sudo mkdir -p /opt/device-monitor
sudo cp device_monitor_linux_kiosk /opt/device-monitor/
sudo chmod +x /opt/device-monitor/device_monitor_linux_kiosk
sudo chown -R kioskuser:kioskuser /opt/device-monitor

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable device-monitor-kiosk.service
sudo systemctl start device-monitor-kiosk.service
```

### 2. X11 Auto-Login Configuration

**File:** `/etc/gdm/custom.conf` (for GNOME)
```ini
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=kioskuser

[security]

[xdmcp]

[chooser]

[debug]
```

**Alternative for LightDM:**
**File:** `/etc/lightdm/lightdm.conf`
```ini
[Seat:*]
autologin-user=kioskuser
autologin-user-timeout=0
user-session=kiosk-session
```

### 3. Custom X Session for Kiosk

**File:** `/usr/share/xsessions/kiosk-session.desktop`
```ini
[Desktop Entry]
Name=Kiosk Session
Comment=Device Monitor Kiosk Session
Exec=/opt/device-monitor/kiosk-session.sh
Type=Application
DesktopNames=KIOSK
```

**File:** `/opt/device-monitor/kiosk-session.sh`
```bash
#!/bin/bash

# Disable screen saver and power management
xset s off
xset -dpms
xset s noblank

# Hide cursor globally
unclutter -idle 0.1 -root &

# Disable Alt+Tab, Ctrl+Alt+T, etc.
setxkbmap -option terminate:ctrl_alt_bksp

# Start window manager (lightweight)
openbox &

# Wait for window manager
sleep 2

# Start the kiosk application
DISPLAY=:0 KIOSK=1 /opt/device-monitor/device_monitor_linux_kiosk

# If application exits, restart it
while true; do
    sleep 5
    DISPLAY=:0 KIOSK=1 /opt/device-monitor/device_monitor_linux_kiosk
done
```

### 4. System Hardening for Kiosk

**Disable virtual terminals:**
```bash
# Edit /etc/systemd/logind.conf
sudo sed -i 's/#NAutoVTs=6/NAutoVTs=1/' /etc/systemd/logind.conf
sudo sed -i 's/#ReserveVT=6/ReserveVT=1/' /etc/systemd/logind.conf
```

**Create kiosk user restrictions:**
**File:** `/etc/security/limits.d/kiosk.conf`
```
kioskuser soft nproc 50
kioskuser hard nproc 100
kioskuser soft nofile 1024
kioskuser hard nofile 2048
```

## Windows Implementation

### 1. Windows Service (Recommended)

First, modify your Python application to support Windows service mode:

**File:** `windows_service.py`
```python
import win32serviceutil
import win32service
import win32event
import servicemanager
import socket
import sys
import os
import subprocess
import time

class DeviceMonitorService(win32serviceutil.ServiceFramework):
    _svc_name_ = "DeviceMonitorKiosk"
    _svc_display_name_ = "Device Monitor Kiosk Service"
    _svc_description_ = "Runs Device Monitor in Kiosk Mode"

    def __init__(self, args):
        win32serviceutil.ServiceFramework.__init__(self, args)
        self.hWaitStop = win32event.CreateEvent(None, 0, 0, None)
        socket.setdefaulttimeout(60)
        self.is_alive = True

    def SvcStop(self):
        self.ReportServiceStatus(win32service.SERVICE_STOP_PENDING)
        win32event.SetEvent(self.hWaitStop)
        self.is_alive = False

    def SvcDoRun(self):
        servicemanager.LogMsg(servicemanager.EVENTLOG_INFORMATION_TYPE,
                              servicemanager.PYS_SERVICE_STARTED,
                              (self._svc_name_, ''))
        self.main()

    def main(self):
        # Wait for user session to be available
        while self.is_alive:
            try:
                # Check if user session exists
                import win32ts
                sessions = win32ts.WTSEnumerateSessions()
                active_session = None
                for session in sessions:
                    if session['State'] == win32ts.WTSActive:
                        active_session = session['SessionId']
                        break
                
                if active_session is not None:
                    # Launch the kiosk application in user session
                    app_path = os.path.join(os.path.dirname(__file__), 
                                          'device_monitor_windows_kiosk.exe')
                    if os.path.exists(app_path):
                        subprocess.Popen([app_path], 
                                       creationflags=subprocess.CREATE_NEW_PROCESS_GROUP)
                        break
                
                time.sleep(5)
                
            except Exception as e:
                servicemanager.LogErrorMsg(f"Service error: {str(e)}")
                time.sleep(10)

        # Keep service running
        win32event.WaitForSingleObject(self.hWaitStop, win32event.INFINITE)

if __name__ == '__main__':
    if len(sys.argv) == 1:
        servicemanager.Initialize()
        servicemanager.PrepareToHostSingle(DeviceMonitorService)
        servicemanager.StartServiceCtrlDispatcher()
    else:
        win32serviceutil.HandleCommandLine(DeviceMonitorService)
```

**Install as Windows Service:**
```cmd
pip install pywin32
python windows_service.py install
python windows_service.py start
```

### 2. Registry-based Auto-Start (Alternative)

**Registry entry for auto-start:**
```cmd
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "DeviceMonitorKiosk" /t REG_SZ /d "C:\Program Files\DeviceMonitor\device_monitor_windows_kiosk.exe" /f
```

### 3. Windows Kiosk Mode (Windows 10/11)

**PowerShell script to configure Windows Kiosk:**
```powershell
# Create kiosk user
$kioskUser = "KioskUser"
$kioskPassword = ConvertTo-SecureString "KioskPass123!" -AsPlainText -Force
New-LocalUser -Name $kioskUser -Password $kioskPassword -Description "Kiosk User Account"
Add-LocalGroupMember -Group "Users" -Member $kioskUser

# Set up assigned access (requires Windows 10 Pro or Enterprise)
$kioskConfig = @"
<?xml version="1.0" encoding="utf-8"?>
<AssignedAccessConfiguration xmlns="http://schemas.microsoft.com/AssignedAccess/2017/config">
    <Profiles>
        <Profile Id="{12345678-1234-1234-1234-123456789012}">
            <AllAppsList>
                <AllowedApps>
                    <App AppUserModelId="DeviceMonitor_App" />
                </AllowedApps>
            </AllAppsList>
            <StartLayout>
                <![CDATA[<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
                  <DefaultLayoutOverride>
                    <StartLayoutCollection>
                      <defaultlayout:StartLayout GroupCellWidth="6">
                        <start:Group Name="Kiosk">
                          <start:Tile Size="4x4" Column="0" Row="0" AppUserModelId="DeviceMonitor_App" />
                        </start:Group>
                      </defaultlayout:StartLayout>
                    </StartLayoutCollection>
                  </DefaultLayoutOverride>
                </LayoutModificationTemplate>]]>
            </StartLayout>
            <Taskbar ShowTaskbar="false"/>
        </Profile>
    </Profiles>
    <Configs>
        <Config>
            <Account>$kioskUser</Account>
            <DefaultProfile Id="{12345678-1234-1234-1234-123456789012}"/>
        </Config>
    </Configs>
</AssignedAccessConfiguration>
"@

$kioskConfig | Out-File -FilePath "C:\temp\kiosk-config.xml" -Encoding UTF8
Set-AssignedAccess -ConfigurationXml (Get-Content "C:\temp\kiosk-config.xml")
```

### 4. Group Policy Configuration

**Disable common Windows features for kiosk:**
```cmd
# Disable Ctrl+Alt+Del
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "DisableCAD" /t REG_DWORD /d 1 /f

# Disable Task Manager
reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "DisableTaskMgr" /t REG_DWORD /d 1 /f

# Disable Alt+Tab
reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoWindowMinimizingShortcuts" /t REG_DWORD /d 1 /f

# Auto-login configuration
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "AutoAdminLogon" /t REG_SZ /d "1" /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultUserName" /t REG_SZ /d "KioskUser" /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultPassword" /t REG_SZ /d "KioskPass123!" /f
```

## Updated CI/CD Pipeline

### Enhanced Build Script for Auto-Boot

**Windows PowerShell Script:** `build-kiosk-installer.ps1`
```powershell
# Build the kiosk executable with auto-boot capability
param(
    [string]$Version = "1.0.0"
)

# Create installer directory structure
New-Item -ItemType Directory -Force -Path "installer/windows"
New-Item -ItemType Directory -Force -Path "installer/linux"

# Copy executables
Copy-Item "dist/device_monitor_windows_kiosk.exe" "installer/windows/"
Copy-Item "dist/device_monitor_linux_kiosk" "installer/linux/"

# Create Windows installer script
@"
@echo off
echo Installing Device Monitor Kiosk...
xcopy /Y device_monitor_windows_kiosk.exe "C:\Program Files\DeviceMonitor\"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "DeviceMonitorKiosk" /t REG_SZ /d "C:\Program Files\DeviceMonitor\device_monitor_windows_kiosk.exe" /f
echo Installation complete. System will start kiosk on next boot.
pause
"@ | Out-File -FilePath "installer/windows/install-kiosk.bat" -Encoding ASCII

# Create Linux installer script
@"
#!/bin/bash
echo "Installing Device Monitor Kiosk..."
sudo mkdir -p /opt/device-monitor
sudo cp device_monitor_linux_kiosk /opt/device-monitor/
sudo chmod +x /opt/device-monitor/device_monitor_linux_kiosk

# Create systemd service
sudo tee /etc/systemd/system/device-monitor-kiosk.service > /dev/null <<EOF
[Unit]
Description=Device Monitor Kiosk Application
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
User=kioskuser
Group=kioskuser
Environment=DISPLAY=:0
Environment=KIOSK=1
ExecStart=/opt/device-monitor/device_monitor_linux_kiosk
Restart=always
RestartSec=3

[Install]
WantedBy=graphical.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable device-monitor-kiosk.service
echo "Installation complete. Please create kioskuser and reboot."
"@ | Out-File -FilePath "installer/linux/install-kiosk.sh" -Encoding UTF8
```

## Testing Auto-Boot

### RHEL 7.9 Testing
```bash
# Test service status
sudo systemctl status device-monitor-kiosk.service

# Test manual start
sudo systemctl start device-monitor-kiosk.service

# Check logs
journalctl -u device-monitor-kiosk.service -f

# Test reboot
sudo reboot
```

### Windows Testing
```cmd
# Check if service is running
sc query DeviceMonitorKiosk

# Test registry entry
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "DeviceMonitorKiosk"

# Test reboot behavior
shutdown /r /t 0
```

## Security Considerations

1. **User Account Isolation**: Kiosk user should have minimal privileges
2. **Network Restrictions**: Consider firewall rules for kiosk applications
3. **Update Mechanism**: Plan for secure remote updates
4. **Monitoring**: Implement remote monitoring for kiosk health
5. **Recovery**: Plan for system recovery if kiosk application fails

## Important Notes

- **RHEL 7.9 Limitation**: Older systemd version may require different service configuration
- **Windows Versions**: Assigned Access requires Windows 10 Pro/Enterprise
- **Hardware Dependencies**: USB device access may require specific permissions
- **Remote Management**: Consider implementing remote management capabilities for production deployments
