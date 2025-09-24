# Device Monitor Kiosk - Quick Start Guide

## Choose Your Platform

### Linux RHEL 7.9 Quick Start

1. **Copy files to your RHEL system**:

   ```bash
   # Copy the entire linux/ directory and main.py to your target system
   scp -r linux/ main.py user@rhel-system:/tmp/kiosk-install/
   ```

2. **Run installation**:

   ```bash
   ssh user@rhel-system
   cd /tmp/kiosk-install/linux/scripts
   sudo chmod +x install-kiosk.sh
   sudo ./install-kiosk.sh
   ```

3. **Reboot and test**:
   ```bash
   sudo reboot
   # System will auto-login as 'kioskuser' and start the application
   ```

### Windows Quick Start

1. **Copy files to your Windows system**:

   - Copy the entire `windows/` directory to `C:\temp\kiosk-install\`
   - Copy `main.py` to the same location

2. **Run PowerShell as Administrator**:

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   cd "C:\temp\kiosk-install\windows\scripts"
   .\install-kiosk.ps1 -Install
   ```

3. **Reboot and test**:
   ```cmd
   shutdown /r /t 0
   # System will auto-login as 'KioskUser' and start the application
   ```

## Emergency Exit Methods

- **Linux**: Ctrl+Alt+Shift+Q (configured in Openbox)
- **Windows**: Ctrl+Alt+K (built into the application)

## Testing Your Installation

### Linux Testing

```bash
sudo /opt/device-monitor/test-kiosk.sh all
```

### Windows Testing

```cmd
cd "C:\Program Files\DeviceMonitor\scripts"
test-kiosk.bat
```

## Need Help?

1. Check the comprehensive [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
2. Review the original [kiosk_boot_guide.md](kiosk_boot_guide.md)
3. Run the test scripts to identify issues
4. Check system logs for error messages

## Uninstallation

### Linux

```bash
sudo /opt/device-monitor/uninstall-kiosk.sh
```

### Windows

```powershell
& "C:\Program Files\DeviceMonitor\uninstall-kiosk.ps1"
```

Or use the registry restoration:

```cmd
cd "C:\Program Files\DeviceMonitor\scripts"
restore-registry.bat
```
