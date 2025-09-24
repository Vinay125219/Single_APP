# Device Monitor Kiosk Boot Implementation Guide

## Overview

This comprehensive guide provides complete kiosk boot implementation for both Linux RHEL 7.9 and Windows systems. The implementation ensures your Device Monitor application starts automatically on system boot and creates a locked-down kiosk environment.

## Project Structure

```
Single_APP/
├── main.py                          # Main Device Monitor application
├── kiosk_boot_guide.md             # Original implementation guide
├── scripts/                        # Enhanced kiosk scripts
│   ├── kiosk.bat                   # Windows kiosk wrapper (enhanced)
│   └── kiosk.sh                    # Linux kiosk wrapper (enhanced)
├── linux/                         # Linux RHEL 7.9 implementation
│   ├── systemd/
│   │   └── device-monitor-kiosk.service
│   ├── config/
│   │   ├── gdm-custom.conf
│   │   ├── lightdm.conf
│   │   ├── kiosk-session.desktop
│   │   ├── openbox-rc.xml
│   │   └── kiosk-limits.conf
│   └── scripts/
│       ├── install-kiosk.sh
│       ├── test-kiosk.sh
│       └── kiosk-session.sh
└── windows/                       # Windows implementation
    ├── service/
    │   └── windows_service.py
    └── scripts/
        ├── install-kiosk.ps1
        ├── configure-kiosk.ps1
        ├── configure-registry.bat
        ├── restore-registry.bat
        └── test-kiosk.bat
```

## Linux RHEL 7.9 Implementation

### Prerequisites

- RHEL 7.9 system with root access
- Python 3.6+ installed
- X11 display server
- GDM or LightDM display manager

### Installation Steps

1. **Download and prepare files**:

   ```bash
   # Copy all linux/ directory contents to the target system
   sudo cp -r linux/ /tmp/device-monitor-kiosk/
   sudo cp main.py /tmp/device-monitor-kiosk/
   ```

2. **Run the installation script**:

   ```bash
   cd /tmp/device-monitor-kiosk/linux/scripts
   sudo chmod +x install-kiosk.sh
   sudo ./install-kiosk.sh
   ```

3. **Reboot the system**:
   ```bash
   sudo reboot
   ```

### What the Installation Does

- **Creates kiosk user**: Sets up a dedicated `kioskuser` account
- **Installs systemd service**: Configures auto-start service
- **Configures display manager**: Sets up auto-login for GDM/LightDM
- **Sets up kiosk session**: Creates locked-down X11 session
- **Applies security limits**: Restricts user capabilities
- **Installs application**: Copies and configures the Device Monitor app

### Manual Configuration (Alternative)

If you prefer manual installation:

1. **Create kiosk user**:

   ```bash
   sudo useradd -m -u 1001 -s /bin/bash kioskuser
   sudo usermod -aG users kioskuser
   ```

2. **Install application**:

   ```bash
   sudo mkdir -p /opt/device-monitor
   sudo cp main.py /opt/device-monitor/
   sudo chown -R kioskuser:kioskuser /opt/device-monitor
   ```

3. **Install systemd service**:

   ```bash
   sudo cp linux/systemd/device-monitor-kiosk.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable device-monitor-kiosk.service
   ```

4. **Configure display manager** (GDM):

   ```bash
   sudo cp linux/config/gdm-custom.conf /etc/gdm/custom.conf
   ```

5. **Set up kiosk session**:
   ```bash
   sudo cp linux/config/kiosk-session.desktop /usr/share/xsessions/
   sudo cp linux/scripts/kiosk-session.sh /opt/device-monitor/
   sudo chmod +x /opt/device-monitor/kiosk-session.sh
   ```

### Testing and Troubleshooting

Run the test script to verify installation:

```bash
sudo /opt/device-monitor/test-kiosk.sh
```

Common issues and solutions:

1. **Service fails to start**:

   ```bash
   sudo journalctl -u device-monitor-kiosk.service -f
   ```

2. **X11 display issues**:

   ```bash
   sudo systemctl status display-manager
   export DISPLAY=:0
   xset q
   ```

3. **Python dependencies**:
   ```bash
   python3 -c "import tkinter; print('tkinter OK')"
   ```

### Uninstallation

To remove the kiosk setup:

```bash
sudo /opt/device-monitor/uninstall-kiosk.sh
```

## Windows Implementation

### Prerequisites

- Windows 10/11 (Pro/Enterprise recommended for full features)
- Python 3.7+ installed
- Administrator privileges
- PowerShell execution policy allowing scripts

### Installation Steps

1. **Download and prepare files**:

   - Copy all `windows/` directory contents to target system
   - Copy `main.py` to the same location

2. **Run PowerShell as Administrator**:

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Run the installation script**:

   ```powershell
   cd "path\to\windows\scripts"
   .\install-kiosk.ps1 -Install
   ```

4. **Reboot the system**:
   ```cmd
   shutdown /r /t 0
   ```

### What the Installation Does

- **Creates kiosk user**: Sets up `KioskUser` account with auto-login
- **Installs Python dependencies**: pywin32, tkinter
- **Configures Windows service**: Auto-start service for the application
- **Applies registry settings**: Disables system functions (Task Manager, etc.)
- **Sets up Group Policy**: Advanced kiosk restrictions
- **Configures auto-login**: Automatic user login on boot

### Manual Configuration (Alternative)

1. **Install Python dependencies**:

   ```cmd
   pip install pywin32
   ```

2. **Create kiosk user**:

   ```cmd
   net user KioskUser KioskPass123! /add
   net localgroup Users KioskUser /add
   ```

3. **Install Windows service**:

   ```cmd
   cd "path\to\application"
   python windows_service.py install
   ```

4. **Configure registry**:

   ```cmd
   cd "path\to\windows\scripts"
   configure-registry.bat
   ```

5. **Apply advanced kiosk settings**:
   ```powershell
   .\configure-kiosk.ps1 -Install
   ```

### Testing and Troubleshooting

Run the test script:

```cmd
cd "path\to\windows\scripts"
test-kiosk.bat
```

Common issues and solutions:

1. **Service fails to start**:

   ```cmd
   sc query DeviceMonitorKiosk
   Get-EventLog -LogName Application -Source DeviceMonitorKiosk
   ```

2. **Python not found**:

   - Ensure Python is installed and in PATH
   - Try: `python --version`

3. **Permission issues**:

   - Run as Administrator
   - Check file permissions in installation directory

4. **Auto-login not working**:
   ```cmd
   reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
   ```

### Emergency Exit

If you get locked in kiosk mode:

- **Linux**: Ctrl+Alt+Shift+Q (if configured in Openbox)
- **Windows**: Ctrl+Alt+K (built into application)

### Uninstallation

**Windows**:

```powershell
cd "C:\Program Files\DeviceMonitor"
.\uninstall-kiosk.ps1
```

Or manually:

```cmd
cd "path\to\windows\scripts"
restore-registry.bat
python "C:\Program Files\DeviceMonitor\windows_service.py" remove
```

## Configuration Options

### Environment Variables

Both implementations support these environment variables:

- `KIOSK=1`: Enable kiosk mode
- `DISPLAY=:0`: X11 display (Linux only)

### Application Arguments

- `--kiosk`: Start in kiosk mode
- Standard tkinter arguments are also supported

### Customization

#### Linux Customization

Edit `/opt/device-monitor/kiosk-session.sh` for:

- Screen resolution settings
- Additional applications to start
- Custom keyboard shortcuts

Edit `/home/kioskuser/.config/openbox/rc.xml` for:

- Window management rules
- Keyboard shortcut modifications
- Theme changes

#### Windows Customization

Edit registry settings for:

- Different kiosk user credentials
- Modified restriction levels
- Custom startup applications

Edit `windows_service.py` for:

- Service behavior modifications
- Monitoring intervals
- Restart policies

## Security Considerations

### Linux Security

- **User isolation**: Kiosk user has minimal privileges
- **System restrictions**: Limited process count and file access
- **Network restrictions**: Consider firewall rules
- **Session isolation**: Dedicated X11 session

### Windows Security

- **Registry lockdown**: Disabled system functions
- **User restrictions**: Limited local group membership
- **Service isolation**: Runs as system service
- **Group Policy**: Additional restrictions available

## Production Deployment

### Linux Production Checklist

- [ ] Test on identical hardware
- [ ] Configure network settings
- [ ] Set up remote monitoring
- [ ] Plan update mechanism
- [ ] Configure backup/recovery
- [ ] Document emergency procedures

### Windows Production Checklist

- [ ] Test on target Windows version
- [ ] Configure Windows Update policies
- [ ] Set up remote management
- [ ] Plan application updates
- [ ] Configure system monitoring
- [ ] Document recovery procedures

## Monitoring and Maintenance

### Linux Monitoring

- **Service status**: `systemctl status device-monitor-kiosk.service`
- **Service logs**: `journalctl -u device-monitor-kiosk.service -f`
- **Application logs**: `/opt/device-monitor/device_monitor.log`
- **System resources**: `top`, `htop`, `systemd-cgtop`

### Windows Monitoring

- **Service status**: `Get-Service DeviceMonitorKiosk`
- **Event logs**: `Get-EventLog -LogName Application -Source DeviceMonitorKiosk`
- **Application logs**: `C:\ProgramData\DeviceMonitor\service.log`
- **Performance**: Task Manager, Performance Monitor

### Remote Management

Consider implementing:

- SSH access (Linux) / RDP access (Windows) for maintenance
- Remote logging to central server
- Health check endpoints
- Automated restart mechanisms
- Remote update capabilities

## Troubleshooting Guide

### Common Issues

1. **Application won't start**:

   - Check Python installation
   - Verify file permissions
   - Check display/GUI availability
   - Review application logs

2. **Service fails**:

   - Check service status
   - Review service logs
   - Verify user permissions
   - Check dependencies

3. **Auto-login fails**:

   - Verify display manager configuration
   - Check user account settings
   - Review authentication logs

4. **Kiosk restrictions not working**:
   - Verify registry/policy settings
   - Check user session type
   - Review Group Policy application

### Getting Help

1. Check the test scripts output
2. Review system and application logs
3. Verify all prerequisites are met
4. Test with minimal configuration first
5. Check for system-specific issues

## Updates and Maintenance

### Updating the Application

**Linux**:

```bash
sudo systemctl stop device-monitor-kiosk.service
sudo cp new-main.py /opt/device-monitor/main.py
sudo systemctl start device-monitor-kiosk.service
```

**Windows**:

```cmd
net stop DeviceMonitorKiosk
copy new-main.py "C:\Program Files\DeviceMonitor\main.py"
net start DeviceMonitorKiosk
```

### System Updates

- Plan for maintenance windows
- Test updates in development environment
- Have rollback procedures ready
- Monitor system after updates

This comprehensive implementation provides enterprise-ready kiosk functionality for both Linux RHEL 7.9 and Windows systems, with proper security, monitoring, and maintenance capabilities.
